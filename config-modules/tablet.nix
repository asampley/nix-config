{ moduleWithSystem, ... }:
{
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
