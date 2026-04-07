{ lib, ... }:
{
  flake.nixosModules.maintenance =
    { config, ... }:
    {
      options.my.maintenance = {
        enable = lib.mkEnableOption "automatic maintenance tasks";
      };

      config = lib.mkIf config.my.maintenance.enable {
        nix.gc = {
          options = "--delete-older-than 30d";
        };

        system.autoUpgrade = {
          enable = lib.mkDefault true;
          dates = lib.mkDefault "Mon *-*-* 00:00:00";
          runGarbageCollection = lib.mkDefault true;
          randomizedDelaySec = lib.mkDefault "0m";
          persistent = lib.mkDefault true;
          flake = lib.mkDefault "/etc/nixos";
          flags = [
            "-L"
          ]
          ++ lib.optionals (config.system.autoUpgrade.flake != null) [
            "--recreate-lock-file"
          ];
        };

        # Retry once just in case network conditions are bad (e.g. hibernation)
        systemd.services.nixos-upgrade = {
          unitConfig = {
            StartLimitIntervalSec = "5m";
            StartLimitBurst = "2";
          };

          serviceConfig = {
            Restart = "on-failure";
            RestartSec = "1m";
          };
        };
      };
    };

  flake.nixosModules.maintenance-notifications =
    { config, ... }:
    {
      options.my.maintenance.notifications = {
        enable = lib.mkEnableOption "notifications for maintenance tasks";
      };

      config = lib.mkIf config.my.maintenance.notifications.enable {
        systemd.services.nixos-upgrade = {
          unitConfig = {
            OnSuccess = [ "notify-on-success@nixos-upgrade.service" ];
            OnFailure = [ "notify-on-failure@nixos-upgrade.service" ];
          };
        };
      };
    };
}
