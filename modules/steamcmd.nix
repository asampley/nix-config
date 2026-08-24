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
          installDir = mkOption {
            type = path;
            default = "/var/lib/steamcmd-servers";
          };

          servers = mkOption {
            type = attrsOf (submodule {
              options = {
                serviceName = mkOption { type = nullOr str; };
                appId = mkOption { type = str; };
                workshop = mkOption {
                  type = nullOr (submodule {
                    options = {
                      id = mkOption { type = nullOr str; };
                      modIds = mkOption {
                        type = listOf str;
                        default = [ ];
                      };
                    };
                  });
                };
                user = mkOption { type = nullOr str; };
                start = mkOption { type = package; };
                preUpdate = mkOption {
                  type = lines;
                  default = "";
                };
                preSteamUpdate = mkOption {
                  type = lines;
                  default = "";
                };
                postUpdate = mkOption {
                  type = lines;
                  default = "";
                };
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

                homeDir = mkOption {
                  type = path;
                  readOnly = true;
                };
                installDir = mkOption {
                  type = path;
                  readOnly = true;
                };
              };
            });
            apply =
              value:
              builtins.mapAttrs (
                name: server:
                server
                // {
                  user = if server.user != null then server.user else "steamcmd-${name}";
                  homeDir = "${config.my.steamcmd.installDir}/${name}";
                  installDir = "${config.my.steamcmd.installDir}/${name}/game";
                }
              ) value;
          };
        };

      config =
        let
          cfg = config.my.steamcmd;
        in
        lib.mkIf cfg.enable {

          users.users =
            builtins.listToAttrs (
              builtins.attrValues (
                builtins.mapAttrs (name: server: {
                  name = "steamcmd-${name}";
                  value = {
                    name = server.user;
                    home = server.homeDir;
                    homeMode = "750";
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
                home = cfg.installDir;
                createHome = true;
                homeMode = "750";
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
                      serviceConfig = {
                        User = server.user;
                        Group = config.users.groups.steamcmd.name;
                        WorkingDirectory = server.installDir;
                        ExecStart = server.start;
                      };
                    };
                  }
                  {
                    name = "steamcmd-update-${name}";
                    value = {
                      after = [ "network.target" ];
                      serviceConfig = {
                        User = server.user;
                        Group = config.users.groups.steamcmd.name;
                        WorkingDirectory = cfg.installDir;
                        ExecStart = pkgs.writeShellScript "steamcmd-update-${name}.bash" ''
                          ${server.preUpdate}
                          "${pkgs.steamcmd}/bin/steamcmd +runscript ${pkgs.writeText "steamcmd-update-${name}.steamcmd" ''
                            force_install_dir ${server.installDir}
                            login anonymous
                            ${if server.preSteamUpdate != null then server.preSteamUpdate else ""}
                            app_update ${server.appId}
                            ${
                              if server.workshop != null && builtins.length server.workshop.modIds != 0 then
                                lib.strings.concatLines (
                                  map (modId: "workshop_download_item ${server.workshop.id} ${modId}") server.workshop.modIds
                                )
                              else
                                ""
                            }
                            quit
                          ''}";
                          ${server.postUpdate}
                        '';
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
