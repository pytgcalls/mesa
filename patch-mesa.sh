function patch_mesa() {
  find src -type f -name 'meson.build' ! -path 'src/nouveau/*' -exec sed -i 's/shared_library/library/g' {} +
}