{
  lib,
  ...
}:
{
  flake.nixosModules.anti-virus =
    {
      config,
      ...
    }:
    {
      options.my.anti-virus = {
        enable = lib.mkEnableOption "anti-virus";
      };

      config =
        let
          cfg = config.my.anti-virus;
        in
        lib.mkIf cfg.enable {
          services.clamav = {
            # Required for clamdscan
            daemon.enable = lib.mkDefault true;
            # Periodic file scans
            scanner.enable = lib.mkDefault true;
            # Update definitions
            updater.enable = lib.mkDefault true;
            # Extra lists
            fangfrisch.enable = true;
          };
        };
    };
}
