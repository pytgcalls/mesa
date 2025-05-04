source /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/pytgcalls/build-toolkit/refs/heads/master/build-toolkit.sh)"

require rust
require venv

import libraries.properties
import libraries.properties from "github.com/pytgcalls/libx11"
import mako from python3
import meson from python3
import ninja from python3
import pyyaml from python3
import packaging from python3
import pycparser from python3
import cbindgen from rust
import bindgen-cli from rust

build_and_install "macros" configure
build_and_install "libXshmfence" configure
build_and_install "libXrandr" configure
build_and_install "xorgproto" configure
build_and_install "libXfixes" configure
build_and_install "libXxf86vm" configure
build_and_install "libffi" configure
build_and_install "libxml2" autogen \
  PYTHON_CFLAGS="$(/opt/python/cp312-cp312/bin/python3-config --cflags)" \
  PYTHON_LIBS="$(/opt/python/cp312-cp312/bin/python3-config --libs)"
build_and_install "SPIRV-Headers" cmake --skip-build
build_and_install "wayland" meson-static -Ddocumentation=false
build_and_install "SPIRV-Tools" cmake --update-submodules \
  -DSPIRV-Headers_SOURCE_DIR="$DEFAULT_BUILD_FOLDER/SPIRV-Headers"
build_and_install "SPIRV-LLVM-Translator" cmake
build_and_install "glslang" cmake -DALLOW_EXTERNAL_SPIRV_TOOLS=ON
build_and_install "libglvnd" meson
build_and_install "libvdpau" meson
build_and_install "libva" meson
build_and_install "libpciaccess" meson

build_and_install "drm" meson-static -Dintel=enabled
build_and_install "mesa" meson-static \
  --setup-commands="find src -type f -name 'meson.build' ! -path 'src/nouveau/*' -exec sed -i 's/shared_library/library/g' {} +"

copy_libs "drm" "artifacts"
copy_libs "mesa" "artifacts" "gbm"