{ lib, ... }:
{
  flake.nixosModules.cloud =
    {
      config,
      pkgs,
      ...
    }:
    {
      options.my.cloud = with lib; {
        nextcloud = {
          enable = mkEnableOption "host nextcloud instance";

          hostName = mkOption {
            type = types.str;
            default = "${config.services.avahi.hostName}.${config.services.avahi.domainName}";
          };

          borgbackup = {
            enable = mkEnableOption "borg backups of nextcloud";
            name = mkOption {
              type = types.str;
              default = "nextcloud";
            };
          };

          adminPassFile = mkOption {
            type = types.str;
          };

          https = lib.mkEnableOption "https for nextcloud";
        };
      };

      config =
        let
          cfg = config.my.cloud;
          cfgnc = config.services.nextcloud;
        in
        lib.mkMerge [
          (lib.mkIf cfg.nextcloud.enable {
            services.nextcloud = {
              enable = true;

              https = cfg.nextcloud.https;

              package = pkgs.nextcloud32;
              hostName = "${cfg.nextcloud.hostName}";

              extraAppsEnable = true;
              extraApps = with cfgnc.package.packages.apps; {
                inherit
                  contacts
                  calendar
                  news
                  notes
                  tasks
                  ;
              };

              config = {
                adminpassFile = cfg.nextcloud.adminPassFile;
                dbtype = "pgsql";
                dbname = "nextcloud";
                dbuser = "nextcloud";
                dbhost = "/run/postgresql";
              };

              settings = {
                log_type = "systemd";
              };
            };

            systemd.services.nextcloud-custom-config = {
              path = [
                cfgnc.occ
              ];
              script = ''
                nextcloud-occ theming:config url "https://${cfg.nextcloud.hostName}";
              '';
              after = [ "nextcloud-setup.service" ];
              wantedBy = [ "multi-user.target" ];
            };

            services.nginx.virtualHosts."${cfg.nextcloud.hostName}" = {
              enableACME = cfg.nextcloud.https;
              forceSSL = cfg.nextcloud.https;
            };

            networking.firewall.allowedTCPPorts = lib.optionals cfg.nextcloud.https [
              443
              80
            ];

            services.postgresql = {
              enable = true;

              ensureDatabases = [ "nextcloud" ];
              ensureUsers = [
                {
                  name = "nextcloud";
                  ensureDBOwnership = true;
                }
              ];
            };

            systemd.services."nextcloud-setup" = {
              requires = [ "postgresql.service" ];
              after = [ "postgresql.service" ];
            };

            users.users.borg.extraGroups = lib.mkIf cfg.nextcloud.borgbackup.enable [ "nextcloud" ];
            security.sudo.extraRules = lib.mkIf cfg.nextcloud.borgbackup.enable [
              {
                users = [ config.users.users.borg.name ];
                host = "ALL";
                runAs = "nextcloud:nextcloud";
                commands = [
                  {
                    command = "${cfgnc.occ}/bin/nextcloud-occ maintenance\\:mode --on";
                    options = [ "NOPASSWD" ];
                  }
                  {
                    command = "${cfgnc.occ}/bin/nextcloud-occ maintenance\\:mode --off";
                    options = [ "NOPASSWD" ];
                  }
                  {
                    command = "${config.services.postgresql.package}/bin/pg_dump ${cfgnc.config.dbname} -f /tmp/output/pg_dump.sql";
                    options = [ "NOPASSWD" ];
                  }
                ];
              }
            ];

            my.backup.borg.jobs = lib.mkIf cfg.nextcloud.borgbackup.enable {
              "${cfg.nextcloud.borgbackup.name}" =
                let
                  sudo-nc = "/run/wrappers/bin/sudo -u nextcloud -g nextcloud";
                in
                {
                  paths = [
                    cfgnc.datadir
                    "/tmp/output"
                  ];

                  readWritePaths = [ "${cfgnc.datadir}" ];

                  privateTmp = true;

                  preHook = ''
                    # Make directory for additional outputs
                    ${pkgs.coreutils}/bin/mkdir -m 777 /tmp/output/

                    # Lock nextcloud files for consistency
                    ${sudo-nc} ${cfgnc.occ}/bin/nextcloud-occ maintenance:mode --on

                    # Backup database while locked
                    ${sudo-nc} ${config.services.postgresql.package}/bin/pg_dump ${cfgnc.config.dbname} -f /tmp/output/pg_dump.sql
                  '';

                  postHook = ''
                    # Unlock nextcloud files
                    ${sudo-nc} ${cfgnc.occ}/bin/nextcloud-occ maintenance:mode --off
                  '';

                  startAt = lib.mkDefault "*-*-* *:00:00";
                  persistentTimer = lib.mkDefault true;
                };
            };
          })
        ];
    };

  flake.nixosModules.nextcloud-sops =
    { config, ... }:
    {
      options.my.cloud.nextcloud.sops = with lib; {
        enable = mkEnableOption "sops management for nextcloud";
      };

      config = lib.mkIf config.my.cloud.nextcloud.sops.enable {
        sops.secrets.nextcloud-admin-pass.owner = config.users.users.nextcloud.name;

        my.cloud.nextcloud.adminPassFile = config.sops.secrets.nextcloud-admin-pass.path;
      };
    };
  flake.homeModules.nextcloud =
    { config, ... }:
    {
      options.my.nextcloud = with lib; {
        passFile = mkOption {
          type = types.str;
          default = "${config.home.homeDirectory}/secrets/nextcloud";
        };
      };
      config =
        let
          cfg = config.my.nextcloud;
        in
        {
          # rclone creates cached fuse mounts for webdav
          programs.rclone = {
            enable = true;
            remotes = {
              nextcloud = {
                config = {
                  type = "webdav";
                  url = "https://cloud.asampley.ca/remote.php/dav/files/asampley";
                  vendor = "nextcloud";
                  user = "asampley";
                };
                secrets = {
                  pass = cfg.passFile;
                };
                mounts = {
                  "/" = {
                    enable = true;
                    mountPoint = "${config.home.homeDirectory}/nextcloud";
                    options = {
                      dir-cache-time = "10m";
                      poll-interval = "10s";
                    };
                  };
                };
              };
            };
          };
        };
    };

  flake.homeModules.nextcloud-sops =
    { config, ... }:
    {
      sops.secrets.nextcloud = { };
      my.nextcloud.passFile = config.sops.secrets.nextcloud.path;
    };
}
