{ lib, moduleWithSystem, ... }:
{
  perSystem =
    { config, pkgs, ... }:
    {
      packages = {
        borg-exporter = pkgs.rustPlatform.buildRustPackage (finalAttrs: rec {
          pname = "borg-exporter";
          version = "0.1.1";

          src = pkgs.fetchgit {
            #url = "https://github.com/asampley/borg-exporter.git";
            #rev = "de38a83c37c57158335c9fd2566eea9fe0bdebb6";
            #hash = "sha256-RIwcj8J37ixmP0aZLDUjImL3DRo9FhLDuXQECbRZVkU=";
            url = "https://codeberg.org/mmakowski/borg-exporter.git";
            rev = "6f25798e13e7e9b327068119ed9d28ab7defa64e";
            hash = "sha256-Zzw61PfSYwb0EUbnvZyck1quN6/+vjOpCpwXsMfIe5I=";
          };

          cargoLock.lockFile = "${finalAttrs.src}/Cargo.lock";

          buildInputs = [ pkgs.makeWrapper ];
          postInstall = "wrapProgram $out/bin/${pname} --prefix PATH : ${pkgs.borgbackup}/bin";
        });
      };
    };

  flake.nixosModules.prometheus =
    { config, ... }:
    {
      options.my.monitoring.prometheus = {
        enable = lib.mkEnableOption "prometheus server";
        openFirewall = lib.mkEnableOption "open firewall for access through http";
      };

      config =
        let
          cfg = config.my.monitoring.prometheus;
        in
        lib.mkIf cfg.enable {
          services.prometheus = {
            enable = true;
            globalConfig = {
              scrape_interval = "1m";
            };
            scrapeConfigs = [
              {
                job_name = "self";
                static_configs = [
                  {
                    targets =
                      [ ]
                      ++ (
                        with config.services.prometheus.exporters.node;
                        lib.optionals enable [ "localhost:${toString port}" ]
                      )
                      ++ (
                        with config.services.prometheus.exporters.borg;
                        lib.optionals enable [ "localhost:${toString (settings.http_server.port or 9884)}" ]
                      );
                  }
                ];
              }
            ];
            alertmanagers = lib.mkIf config.services.prometheus.alertmanager.enable [
              {
                static_configs = [
                  {
                    targets =
                      [ ]
                      ++ (
                        with config.services.prometheus.alertmanager; lib.optionals enable [ "localhost:${toString port}" ]
                      );
                  }
                ];
              }
            ];
            rules = [
              ''
                groups:
                - name: asampley
                  rules:
                  - alert: LowRootSpace
                    expr: node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes < 0.1
                    annotations:
                      summary: Low disk space on root partition
                  - alert: DailyBackupMissing
                    expr: |
                      borg_last_archive_completion_time_seconds + 1d + 1h < time()
                        or absent_over_time(borg_last_archive_completion_time_seconds[1d]) > 0
                    annotations:
                      summary: Backups may be missing
              ''
            ];
          };

          networking.firewall.allowedTCPPorts = lib.optionals cfg.openFirewall [
            config.services.prometheus.port
          ];
        };
    };

  flake.nixosModules.prometheus-exporters-borg = moduleWithSystem (
    { self', ... }:
    { config, pkgs, ... }:
    {
      options.services.prometheus.exporters.borg =
        with lib;
        with types;
        {
          enable = mkEnableOption "borg exporter";
          serviceName = mkOption {
            type = str;
            default = "prometheus-borg-exporter";
          };
          settings = mkOption {
            type = attrs;
            default = { };
          };
          user = mkOption {
            type = str;
            default = "borg-exporter";
          };
          group = mkOption {
            type = str;
            default = config.services.prometheus.exporters.borg.user;
          };
        };

      config =
        let
          cfg = config.services.prometheus.exporters.borg;
          config-file = (pkgs.formats.yaml { }).generate "borg-exporter.yaml" cfg.settings;
        in
        lib.mkIf cfg.enable {
          users.users.${cfg.user} = {
            isSystemUser = true;
            group = cfg.group;
          };
          users.groups.${cfg.group} = { };
          systemd.services.${cfg.serviceName} = {
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            serviceConfig = with lib; {
              Restart = mkDefault "always";
              PrivateTmp = mkDefault true;
              WorkingDirectory = mkDefault /tmp;
              User = cfg.user;
              Group = cfg.group;
              ExecStart = "${self'.packages.borg-exporter}/bin/borg-exporter '${config-file}'";
            };
          };
        };
    }
  );

  flake.nixosModules.prometheus-ntfy =
    { config, ... }:
    {
      options.my.monitoring.prometheus.ntfy = with lib; {
        enable = mkEnableOption "send notifications through ntfy";
        baseurl = mkOption {
          type = types.str;
        };
      };

      config =
        let
          cfg = config.my.monitoring.prometheus.ntfy;
        in
        lib.mkIf cfg.enable {
          sops.secrets.alertmanager-ntfy = { };

          services.prometheus = {
            alertmanager-ntfy = {
              enable = true;
              settings = {
                http.addr = "127.0.0.1:9089";
                ntfy = {
                  baseurl = cfg.baseurl;
                  notification.topic = "system";
                };
              };
              extraConfigFiles = [ config.sops.secrets.alertmanager-ntfy.path ];
            };
            alertmanager = {
              enable = true;
              configuration = {
                route = {
                  receiver = "alertmanager-ntfy";
                };
                receivers = [
                  {
                    name = "alertmanager-ntfy";
                    webhook_configs = [
                      {
                        url = "http://${config.services.prometheus.alertmanager-ntfy.settings.http.addr}/hook";
                      }
                    ];
                  }
                ];
              };
            };
          };
        };
    };
}
