{ moduleWithSystem, ... }:
{
  perSystem =
    { self', pkgs, ... }:
    {
      packages = {
        accel-rotation = pkgs.writeShellScriptBin "accel-rotation" (
          builtins.readFile ../scripts/accel-rotation
        );

        niri-accel-rotate = pkgs.writeShellScriptBin "niri-accel-rotate" ''
          set -eu
          ACCEL_DISPLAY=$1
          niri msg output eDP-1 transform "$(${self'.packages.accel-rotation}/bin/accel-rotation "$ACCEL_DISPLAY" | sed 's/^0$/normal/')"
        '';

        niri-accel-auto-rotate = pkgs.writeShellScriptBin "niri-accel-auto-rotate" ''
          ${pkgs.iio-sensor-proxy}/bin/monitor-sensor --accel\
            | ${pkgs.gnused}/bin/sed -u -n '
              /Accelerometer orientation changed/!d;
              s/.*:\s*//;
              s/left-up/90/; s/inverted/180/; s/right-up/270/;
              p'\
            | while read rotation; do
                niri msg output eDP-1 transform "$rotation"
              done
        '';
      };
    };

  flake.homeModules.tablet = moduleWithSystem (
    { self', ... }:
    { config, lib, ... }:
    {
      options.my.tablet = with lib; {
        niri = mkEnableOption "enable niri tablet tools";
      };

      config =
        let
          cfg = config.my.tablet;
        in
        lib.mkIf cfg.niri {
          home.packages = with self'.packages; [
            # Used by waybar to rotate screen
            niri-accel-rotate
          ];
        };
    }
  );
}
