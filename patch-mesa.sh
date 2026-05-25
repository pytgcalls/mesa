function patch_mesa() {
  find src -type f -name 'meson.build' ! -path 'src/nouveau/*' ! -path 'src/asahi/lib/*' -exec sed -i 's/shared_library/library/g' {} +
}