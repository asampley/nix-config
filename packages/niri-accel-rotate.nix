{
  accel-rotation,
  writeShellScriptBin,
}:
writeShellScriptBin "niri-accel-rotate" ''
  set -eu
  ACCEL_DISPLAY=$1
  niri msg output eDP-1 transform "$(${accel-rotation}/bin/accel-rotation "$ACCEL_DISPLAY" | sed 's/^0$/normal/')"
''
