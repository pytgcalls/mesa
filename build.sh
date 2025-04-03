# shellcheck disable=SC1090
source <(curl -s https://raw.githubusercontent.com/pytgcalls/build-toolkit/refs/heads/master/build-toolkit.sh)

require_rust
require_venv

UTIL_MACROS_VERSION=$(get_version "util-macros")
XSHMFENCE_VERSION=$(get_version "xshmfence")
XRANDR_VERSION=$(get_version "xrandr")
FFI_VERSION=$(get_version "ffi")
XML2_VERSION=$(get_version "xml2")
WAYLAND_VERSION=$(get_version "wayland")
SPIRV_TOOLS_VERSION=$(get_version "spirv-tools")
SPIRV_LLVM_VERSION=$(get_version "spirv-llvm")
GLSLANG_VERSION=$(get_version "glslang")
GLVND_VERSION=$(get_version "glvnd")
VDPAU_VERSION=$(get_version "vdpau")
LIBVA_VERSION=$(get_version "libva")
PCI_ACCESS=$(get_version "pciaccess")
DRM_VERSION=$(get_version "drm")
MESA_VERSION=$(get_version "mesa")

run cargo install bindgen-cli cbindgen
python -m pip install packaging pyyaml pycparser mako --root-user-action=ignore
build_and_install "${FREEDESKTOP_GIT}xorg/util/macros.git" "util-macros-$UTIL_MACROS_VERSION" autogen
build_and_install "${FREEDESKTOP_GIT}xorg/lib/libxshmfence.git" "libxshmfence-$XSHMFENCE_VERSION" autogen
build_and_install "${FREEDESKTOP_GIT}xorg/lib/libxrandr.git" "libXrandr-$XRANDR_VERSION" autogen
build_and_install https://github.com/libffi/libffi.git "v$FFI_VERSION" configure
build_and_install https://gitlab.gnome.org/GNOME/libxml2.git "v$XML2_VERSION" autogen PYTHON_CFLAGS="$(/opt/python/cp312-cp312/bin/python3-config --cflags)" PYTHON_LIBS="$(/opt/python/cp312-cp312/bin/python3-config --libs)"
build_and_install "${FREEDESKTOP_GIT}wayland/wayland.git" "$WAYLAND_VERSION" meson -Ddocumentation=false
build_and_install "https://github.com/KhronosGroup/SPIRV-Headers.git" "vulkan-sdk-$SPIRV_TOOLS_VERSION" cmake --skip-build
build_and_install "https://github.com/KhronosGroup/SPIRV-Tools.git" "vulkan-sdk-$SPIRV_TOOLS_VERSION" cmake --update-submodules -DSPIRV-Headers_SOURCE_DIR="$(pwd)/SPIRV-Headers"
build_and_install "https://github.com/KhronosGroup/SPIRV-LLVM-Translator.git" "v$SPIRV_LLVM_VERSION" cmake
build_and_install "https://github.com/KhronosGroup/glslang.git" "$GLSLANG_VERSION" cmake -DALLOW_EXTERNAL_SPIRV_TOOLS=ON
build_and_install "${FREEDESKTOP_GIT}glvnd/libglvnd.git" "v$GLVND_VERSION" meson
build_and_install "${FREEDESKTOP_GIT}vdpau/libvdpau.git" "$VDPAU_VERSION" meson
build_and_install "https://github.com/intel/libva.git" "$LIBVA_VERSION" meson
build_and_install "${FREEDESKTOP_GIT}xorg/lib/libpciaccess.git" "libpciaccess-$PCI_ACCESS" meson
build_and_install "${FREEDESKTOP_GIT}mesa/drm.git" "libdrm-$DRM_VERSION" meson -Dintel=enabled
build_and_install "${FREEDESKTOP_GIT}mesa/mesa.git" "mesa-$MESA_VERSION" meson-static --prefix="$(pwd)/mesa/build/" --pre-autogen-command="find src -type f -name 'meson.build' ! -path 'src/nouveau/*' -exec sed -i 's/shared_library/library/g' {} +"
build_and_install "${FREEDESKTOP_GIT}mesa/drm.git" "libdrm-$DRM_VERSION" meson-static -Dintel=enabled --prefix="$(pwd)/drm/build/"

mkdir -p artifacts/lib
mkdir -p artifacts/include

cp mesa/build/lib/libgbm.a artifacts/lib/
cp mesa/build/include/gbm.h artifacts/include/
cp drm/build/lib/libdrm.a artifacts/lib/
cp -r drm/build/include/libdrm artifacts/include/