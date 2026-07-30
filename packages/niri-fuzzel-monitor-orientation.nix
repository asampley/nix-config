{
  writeShellScriptBin,
}:
writeShellScriptBin "niri-fuzzel-monitor-orientation" (
  builtins.readFile ../scripts/wayland/niri-fuzzel-monitor-orientation
)
