{
  lib,
  ...
}:
{
  flake.nixosModules.steamcmd =
    { config, pkgs, ... }:
    {
      options.my.steamcmd =
        with lib;
        with types;
        {
          enable = mkEnableOption "steamcmd download systemd services";
          dataDir = mkOption {
            type = path;
            default = "/var/lib/steamcmd-servers";
          };

          servers = mkOption {
            type = attrsOf (submodule {
              options = {
                serviceName = mkOption { type = nullOr str; };
                appId = mkOption { type = str; };
                user = mkOption { type = nullOr str; };
                start = mkOption { type = package; };
                preSteamUpdate = mkOption { type = nullOr lines; };
                openFirewall = mkOption {
                  type = submodule {
                    options = {
                      allowedTCPPorts = mkOption {
                        type = listOf port;
                        default = [ ];
                      };
                      allowedUDPPorts = mkOption {
                        type = listOf port;
                        default = [ ];
                      };
                    };
                  };
                };
              };
            });
          };
        };

      config =
        let
          cfg = config.my.steamcmd;
          user = name: server: if server.user != null then server.user else "steamcmd-${name}";
          homeDir = name: server: "${cfg.dataDir}/${name}";
          serverDir = name: server: "${homeDir name server}/game";
        in
        lib.mkIf cfg.enable {
          users.users =
            builtins.listToAttrs (
              builtins.attrValues (
                builtins.mapAttrs (name: server: {
                  name = "steamcmd-${name}";
                  value = {
                    name = user name server;
                    home = homeDir name server;
                    createHome = true;
                    isSystemUser = true;
                    group = config.users.groups.steamcmd.name;
                  };
                }) cfg.servers
              )
            )
            // {
              steamcmd = {
                name = "steamcmd";
                home = cfg.dataDir;
                createHome = true;
                homeMode = "770";
                isSystemUser = true;
                group = config.users.groups.steamcmd.name;
              };
            };

          users.groups.steamcmd = { };

          systemd.services = builtins.listToAttrs (
            builtins.concatLists (
              builtins.attrValues (
                builtins.mapAttrs (name: server: [
                  {
                    name = if server.serviceName != null then server.serviceName else "steam-${name}";
                    value = {
                      after = [
                        "network.target"
                        "${config.systemd.services."steamcmd-update-${name}".name}"
                      ];
                      serviceConfig = with lib; {
                        User = user name server;
                        Group = config.users.groups.steamcmd.name;
                        WorkingDirectory = "${serverDir name server}";
                        ExecStart = server.start;
                      };
                    };
                  }
                  {
                    name = "steamcmd-update-${name}";
                    value = {
                      after = [ "network.target" ];
                      serviceConfig = {
                        User = user name server;
                        Group = config.users.groups.steamcmd.name;
                        WorkingDirectory = cfg.dataDir;
                        ExecStart = "${pkgs.steamcmd}/bin/steamcmd +runscript ${pkgs.writeText "steamcmd-update-${name}.steamcmd" ''
                          force_install_dir ${serverDir name server}
                          login anonymous
                          ${if server.preSteamUpdate != null then server.preSteamUpdate else ""}
                          app_update ${server.appId}
                          quit
                        ''}";
                      };
                    };
                  }
                ]) cfg.servers
              )
            )
          );

          networking.firewall = builtins.zipAttrsWith (name: values: builtins.concatLists values) (
            builtins.attrValues (builtins.mapAttrs (name: server: server.openFirewall) cfg.servers)
          );
        };
    };
}
