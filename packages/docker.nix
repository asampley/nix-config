{
  podman,
  writeShellScriptBin,
}:
writeShellScriptBin "docker" "exec -a $0 ${podman}/bin/podman \"$@\""
