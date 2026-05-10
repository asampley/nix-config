{ lib, ... }:
{
  flake.nixosModules.borgbackup =
    { config, options, ... }:
    {
      options.my.backup.borg =
        with lib;
        with types;
        {
          defaults.jobs = mkOption {
            type = attrs;
            default = {
              user = mkOverride 99 config.users.users.borg.name;
              group = mkOverride 99 config.users.groups.borg.name;
            };
          };
          jobs = mkOption {
            type = options.services.borgbackup.jobs.type;
            default = { };
          };
        };

      config =
        let
          cfg = config.my.backup.borg;
        in
        {
          users.users.borg = {
            isSystemUser = true;
            # Home directory needed for running borg
            home = "/home/${config.users.users.borg.name}";
            createHome = true;
            group = config.users.groups.borg.name;
          };
          users.groups.borg = { };

          services.borgbackup.jobs = builtins.mapAttrs (
            name: value:
            lib.mkMerge [
              value
              cfg.defaults.jobs
            ]
          ) cfg.jobs;
        };
    };

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
