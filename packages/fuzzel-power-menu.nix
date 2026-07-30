{
  writeShellScriptBin,
}:
writeShellScriptBin "fuzzel-power-menu" (builtins.readFile ../scripts/wayland/fuzzel-power-menu)
