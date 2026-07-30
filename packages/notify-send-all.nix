{
  libnotify,
  sudo,
  writeShellScriptBin,
}:
writeShellScriptBin "notify-send-all" ''
  for BUS in /run/user/*/bus; do
    USER_ID=''${BUS#/run/user/}
    USER_ID=''${USER_ID%/bus}
    ${sudo}/bin/sudo -u "#$USER_ID" DBUS_SESSION_BUS_ADDRESS=unix:path="$BUS" ${libnotify}/bin/notify-send "$@"
  done

  exit 0
''
