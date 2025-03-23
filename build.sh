export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:/usr/lib/pkgconfig:$PKG_CONFIG_PATH
export ACLOCAL_PATH=/usr/share/aclocal

FREEDESKTOP_GIT="https://gitlab.com/freedesktop-sdk/mirrors/freedesktop/"
LIBRARIES_FILE="libraries.properties"
yum install -y flex elfutils-libelf-devel libffi-devel libxml2-devel

get_version() {
    grep "^$1=" "$LIBRARIES_FILE" | cut -d '=' -f2
}

MESA_VERSION=$(get_version "mesa")
GLVND_VERSION=$(get_version "glvnd")
VDPAU_VERSION=$(get_version "vdpau")
GLSLANG_VERSION=$(get_version "glslang")
SPIRV_TOOLS_VERSION=$(get_version "spirv-tools")
LIBVA_VERSION=$(get_version "libva")
DRM_VERSION=$(get_version "drm")
PCI_ACCESS=$(get_version "pciaccess")
SPIRV_LLVM_VERSION=$(get_version "spirv-llvm")
WAYLAND_VERSION=$(get_version "wayland")
XSHMFENCE_VERSION=$(get_version "xshmfence")
XRANDR_VERSION=$(get_version "xrandr")
UTIL_MACROS_VERSION=$(get_version "util-macros")

curl https://sh.rustup.rs -sSf | sh -s -- -y
source $HOME/.cargo/env
cargo install bindgen-cli cbindgen

python3.12 -m venv venv
source venv/bin/activate
python -m pip install meson ninja packaging pyyaml pycparser mako --root-user-action=ignore

# Install util-macros
git clone $FREEDESKTOP_GIT'xorg/util/macros.git' --branch util-macros-$UTIL_MACROS_VERSION --depth 1
cd macros
echo 'Running autogen.sh for macros...'
./autogen.sh --prefix=/usr;
if [ $? -ne 0 ]; then
  echo 'Error while executing autogen.sh for macros' >&2
  exit 1
fi
make -j$(nproc)
if [ $? -ne 0 ]; then
  echo 'Error while executing make for macros' >&2
  exit 1
fi
make install
if [ $? -ne 0 ]; then
  echo 'Error while executing make install for macros' >&2
  exit 1
fi
cd ..

# Install xshmfence
git clone $FREEDESKTOP_GIT'xorg/lib/libxshmfence.git' --branch libxshmfence-$XSHMFENCE_VERSION --depth 1
cd libxshmfence
echo 'Running autogen.sh for xshmfence...'
./autogen.sh --prefix=/usr;
if [ $? -ne 0 ]; then
  echo 'Error while executing autogen.sh for xshmfence' >&2
  exit 1
fi
make -j$(nproc)
if [ $? -ne 0 ]; then
  echo 'Error while executing make for xshmfence' >&2
  exit 1
fi
make install
if [ $? -ne 0 ]; then
  echo 'Error while executing make install for xshmfence' >&2
  exit 1
fi
cd ..

# Install xrandr
git clone $FREEDESKTOP_GIT'xorg/lib/libxrandr.git' --branch libXrandr-$XRANDR_VERSION --depth 1
cd libxrandr
echo 'Running autogen.sh for xrandr...'
./autogen.sh --prefix=/usr;
if [ $? -ne 0 ]; then
  echo 'Error while executing autogen.sh for xrandr' >&2
  exit 1
fi
make -j$(nproc)
if [ $? -ne 0 ]; then
  echo 'Error while executing make for xrandr' >&2
  exit 1
fi
make install
if [ $? -ne 0 ]; then
  echo 'Error while executing make install for xrandr' >&2
  exit 1
fi
cd ..

# Install Wayland
git clone $FREEDESKTOP_GIT'wayland/wayland.git' --branch $WAYLAND_VERSION --depth 1
cd wayland
echo 'Running meson for wayland...'
python -m mesonbuild.mesonmain setup build --prefix=/usr -Ddocumentation=false
if [ $? -ne 0 ]; then
  echo 'Error while executing meson for wayland' >&2
  exit 1
fi
python -m ninja -C build
if [ $? -ne 0 ]; then
  echo 'Error while executing ninja for wayland' >&2
  exit 1
fi
python -m ninja -C build install
if [ $? -ne 0 ]; then
  echo 'Error while executing ninja install for wayland' >&2
  exit 1
fi
cd ..

# Install SPIRV-Headers
git clone https://github.com/KhronosGroup/SPIRV-Headers.git --branch vulkan-sdk-$SPIRV_TOOLS_VERSION --depth 1
cd SPIRV-Headers
echo 'Running cmake for SPIRV-Headers...'
cmake -S . -B build -G Ninja
if [ $? -ne 0 ]; then
  echo 'Error while executing cmake for SPIRV-Headers' >&2
  exit 1
fi
python -m ninja -C build
if [ $? -ne 0 ]; then
  echo 'Error while executing ninja for SPIRV-Headers' >&2
  exit 1
fi
python -m ninja -C build install
if [ $? -ne 0 ]; then
  echo 'Error while executing ninja install for SPIRV-Headers' >&2
  exit 1
fi
cd ..

# Install SPIRV-Tools
git clone https://github.com/KhronosGroup/SPIRV-Tools.git --branch vulkan-sdk-$SPIRV_TOOLS_VERSION --depth 1
cd SPIRV-Tools
echo 'Running cmake for SPIRV-Tools...'
git submodule update --init --recursive
cmake -S . -B build -G Ninja -DSPIRV-Headers_SOURCE_DIR=/app/SPIRV-Headers -DCMAKE_INSTALL_PREFIX=/usr
if [ $? -ne 0 ]; then
  echo 'Error while executing cmake for SPIRV-Tools' >&2
  exit 1
fi
python -m ninja -C build
if [ $? -ne 0 ]; then
  echo 'Error while executing ninja for SPIRV-Tools' >&2
  exit 1
fi
python -m ninja -C build install
if [ $? -ne 0 ]; then
  echo 'Error while executing ninja install for SPIRV-Tools' >&2
  exit 1
fi
cd ..

# Install SPIRV-LLVM-Translator
git clone https://github.com/KhronosGroup/SPIRV-LLVM-Translator.git --branch v$SPIRV_LLVM_VERSION --depth 1
cd SPIRV-LLVM-Translator
echo 'Running cmake for SPIRV-LLVM-Translator...'
cmake -S . -B build -G Ninja -DCMAKE_INSTALL_PREFIX=/usr
if [ $? -ne 0 ]; then
  echo 'Error while executing cmake for SPIRV-LLVM-Translator' >&2
  exit 1
fi
python -m ninja -C build
if [ $? -ne 0 ]; then
  echo 'Error while executing ninja for SPIRV-LLVM-Translator' >&2
  exit 1
fi
python -m ninja -C build install
if [ $? -ne 0 ]; then
  echo 'Error while executing ninja install for SPIRV-LLVM-Translator' >&2
  exit 1
fi
cd ..

# Install glsLang Library
git clone https://github.com/KhronosGroup/glslang.git --branch $GLSLANG_VERSION --depth 1
cd glslang
echo 'Running cmake for glslang...'
cmake -S . -B build -DCMAKE_INSTALL_PREFIX=/usr -G Ninja -DALLOW_EXTERNAL_SPIRV_TOOLS=ON
if [ $? -ne 0 ]; then
  echo 'Error while executing cmake for glslang' >&2
  exit 1
fi
python -m ninja -C build
if [ $? -ne 0 ]; then
  echo 'Error while executing ninja for glslang' >&2
  exit 1
fi
python -m ninja -C build install
if [ $? -ne 0 ]; then
  echo 'Error while executing ninja install for glslang' >&2
  exit 1
fi
cd ..

# Install libglvnd Library
git clone $FREEDESKTOP_GIT'glvnd/libglvnd.git' --branch v$GLVND_VERSION --depth 1
cd libglvnd
echo 'Running meson for libglvnd...'
python -m mesonbuild.mesonmain setup build --prefix=/usr
if [ $? -ne 0 ]; then
  echo 'Error while executing meson for libglvnd' >&2
  exit 1
fi
python -m ninja -C build
if [ $? -ne 0 ]; then
  echo 'Error while executing ninja for libglvnd' >&2
  exit 1
fi
python -m ninja -C build install
if [ $? -ne 0 ]; then
  echo 'Error while executing ninja install for libglvnd' >&2
  exit 1
fi
cd ..

# Install libvdpau Library
git clone $FREEDESKTOP_GIT'vdpau/libvdpau.git' --branch $VDPAU_VERSION --depth 1
cd libvdpau
echo 'Running meson for libvdpau...'
python -m mesonbuild.mesonmain setup build --prefix=/usr
if [ $? -ne 0 ]; then
  echo 'Error while executing meson for libvdpau' >&2
  exit 1
fi
python -m ninja -C build
if [ $? -ne 0 ]; then
  echo 'Error while executing ninja for libvdpau' >&2
  exit 1
fi
python -m ninja -C build install
if [ $? -ne 0 ]; then
  echo 'Error while executing ninja install for libvdpau' >&2
  exit 1
fi
cd ..

# Install libva Library
git clone https://github.com/intel/libva.git --branch $LIBVA_VERSION --depth 1
cd libva
echo 'Running meson for libva...'
python -m mesonbuild.mesonmain setup build --prefix=/usr
if [ $? -ne 0 ]; then
  echo 'Error while executing meson for libva' >&2
  exit 1
fi
python -m ninja -C build
if [ $? -ne 0 ]; then
  echo 'Error while executing ninja for libva' >&2
  exit 1
fi
python -m ninja -C build install
if [ $? -ne 0 ]; then
  echo 'Error while executing ninja install for libva' >&2
  exit 1
fi
cd ..

# Install libpciaccess
git clone $FREEDESKTOP_GIT'xorg/lib/libpciaccess.git' --branch libpciaccess-$PCI_ACCESS --depth 1
cd libpciaccess
echo 'Running meson for libpciaccess...'
python -m mesonbuild.mesonmain setup build --prefix=/usr
if [ $? -ne 0 ]; then
  echo 'Error while executing meson for libpciaccess' >&2
  exit 1
fi
python -m ninja -C build
if [ $? -ne 0 ]; then
  echo 'Error while executing ninja for libpciaccess' >&2
  exit 1
fi
python -m ninja -C build install
if [ $? -ne 0 ]; then
  echo 'Error while executing ninja install for libpciaccess' >&2
  exit 1
fi
cd ..

# Install libdrm Library
git clone $FREEDESKTOP_GIT'mesa/drm.git' --branch libdrm-$DRM_VERSION --depth 1
cd drm
echo 'Running meson for libdrm...'
python -m mesonbuild.mesonmain setup build --prefix=/usr -Dintel=enabled
if [ $? -ne 0 ]; then
  echo 'Error while executing meson for libdrm' >&2
exit 1
fi
python -m ninja -C build
if [ $? -ne 0 ]; then
  echo 'Error while executing ninja for libdrm' >&2
exit 1
fi
python -m ninja -C build install
if [ $? -ne 0 ]; then
  echo 'Error while executing ninja install for libdrm' >&2
exit 1
fi
cd ..

# Build Mesa Library
git clone $FREEDESKTOP_GIT'mesa/mesa.git' --branch mesa-$MESA_VERSION --depth 1
cd mesa
echo 'Fixing Static Linking...'
find src -type f -name "meson.build" \
    ! -path "src/nouveau/*" \
    -exec sed -i 's/shared_library/library/g' {} +
echo 'Running meson for mesa...'
python -m mesonbuild.mesonmain setup build_output --prefix=/app/build_output --libdir=lib --buildtype=release --default-library=static
if [ $? -ne 0 ]; then
  echo 'Error while executing meson for mesa' >&2
  exit 1
fi
python -m ninja -C build_output
if [ $? -ne 0 ]; then
  echo 'Error while executing ninja for mesa' >&2
  exit 1
fi
python -m ninja -C build_output install
if [ $? -ne 0 ]; then
  echo 'Error while executing ninja install for mesa' >&2
  exit 1
fi
cd ..

# Build libdrm
cd drm
echo 'Running meson for libdrm...'
python -m mesonbuild.mesonmain setup build_output --prefix=/app/build_output --libdir=lib --buildtype=release --default-library=static
if [ $? -ne 0 ]; then
  echo 'Error while executing meson for libdrm' >&2
  exit 1
fi
python -m ninja -C build_output
if [ $? -ne 0 ]; then
  echo 'Error while executing ninja for libdrm' >&2
  exit 1
fi
python -m ninja -C build_output install
if [ $? -ne 0 ]; then
  echo 'Error while executing ninja install for libdrm' >&2
  exit 1
fi
cd ..

mkdir -p artifacts/lib
mkdir -p artifacts/include

cp build_output/lib/libgbm.a artifacts/lib/
cp build_output/include/gbm.h artifacts/include/
cp build_output/lib/libdrm.a artifacts/lib/
cp -r build_output/include/libdrm artifacts/include/