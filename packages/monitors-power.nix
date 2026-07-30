{
  writeShellScriptBin,
}:
writeShellScriptBin "monitors-power" (builtins.readFile ../scripts/wayland/monitors-power)
