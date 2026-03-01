{ lib, ... }:
{
  flake.nixosModules.borgbackup-notifications =
    { config, ... }:
    {
      options.my.backup.borg.notifications = {
        enable = lib.mkEnableOption "notifications on successful and unsuccessful borg backups";
      };

      config = lib.mkIf config.my.backup.borg.notifications.enable {
        systemd.services = builtins.listToAttrs (
          map (
            name:
            let
              service = "borgbackup-job-${name}";
            in
            {
              name = service;
              value = {
                unitConfig = {
                  #OnSuccess = [ "notify-on-success@${service}.service" ];
                  OnFailure = [ "notify-on-failure@${service}.service" ];
                };
              };
            }
          ) (builtins.attrNames config.services.borgbackup.jobs)
        );
      };
    };
}
