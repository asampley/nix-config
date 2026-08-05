{
  gnused,
  iio-sensor-proxy,
  writeShellScriptBin,
}:
writeShellScriptBin "niri-accel-auto-rotate" ''
  ${iio-sensor-proxy}/bin/monitor-sensor --accel\
    | ${gnused}/bin/sed -u -n '
      /Accelerometer orientation changed/!d;
      s/.*:\s*//;
      s/left-up/90/; s/inverted/180/; s/right-up/270/;
      p'\
    | while read rotation; do
        niri msg output eDP-1 transform "$rotation"
      done
''
