{
  writeShellScriptBin,
}:
writeShellScriptBin "accel-rotation" (
  builtins.readFile ../scripts/accel-rotation
)
