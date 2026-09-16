{
  self,
  lib,
  withSystem,
  ...
}:
{
  flake.nixosConfigurations.willheim = withSystem "x86_64-linux" (
    { inputs', ... }:
    self.inputs.nixpkgs.lib.nixosSystem {
      modules = with self.nixosModules; [
        default

        adamhouston
        asampley

        auto-certs
        borgbackup
        borgbackup-notifications
        bittorrent
        cloud
        conan-exiles
        maintenance
        maintenance-notifications
        matrix
        matrix-sops
        nextcloud-sops
        prometheus
        prometheus-ntfy
        prometheus-exporters-borg
        notifications
        ntfy-client-sops
        ntfy-server
        ntfy-server-sops
        sops
        steamcmd
        syncthing-wireguard
        utf-nate
        valheim
        wireguard
        xmpp
        self.inputs.sops-nix.nixosModules.sops
        (
          { config, pkgs, ... }:
          let
            utf-nate-resources = pkgs.symlinkJoin {
              name = "utf-nate-resources";
              paths = [
                "${inputs'.utf-nate.packages.utf-nate}/resources"
              ]
              ++ (map
                (
                  {
                    command,
                    run-service,
                    update-service,
                  }:
                  (pkgs.writeTextFile {
                    name = command;
                    executable = true;
                    destination = "/cmd/${command}";
                    text = ''
                      #!/bin/sh
                      set -euf

                      export PATH="/run/current-system/sw/bin:$PATH"

                      mode="''${1:-}"

                      case "$mode" in
                        start | restart | stop)
                          resources/cmd-template/systemctl.sh $mode '${run-service}'
                          ;;
                        update)
                          resources/cmd-template/systemctl.sh start '${update-service}'
                          ;;
                        *)
                          echo "Mode must be one of the following: start, restart, stop, update"
                          exit
                          ;;
                      esac
                    '';
                  })
                )
                (
                  (lib.optional config.services.conan-exiles.enable {
                    command = "conan";
                    run-service = config.systemd.services.steam-conan-exiles.name;
                    update-service = config.systemd.services.steamcmd-update-conan-exiles.name;
                  })
                  ++ (lib.optional config.services.valheim.enable {
                    command = "valheim";
                    run-service = config.systemd.services.steam-valheim.name;
                    update-service = config.systemd.services.steamcmd-update-valheim.name;
                  })
                )
              );
            };
          in
          {
            imports = [
              ./hardware-configuration.nix
            ];

            # Custom modules
            my.auto-certs.enable = true;

            my.backup.borg.notifications.enable = true;
            my.backup.borg.defaults.jobs = with lib; {
              user = mkOverride 99 config.users.users.borg.name;
              group = mkOverride 99 config.users.users.borg.group;
            };

            my.bittorrent.opentracker = {
              enable = true;
              supportReverseProxy = true;
            };

            my.cloud.nextcloud = {
              enable = true;
              hostName = "cloud.asampley.ca";
              https = true;
              borgbackup.enable = true;
              sops.enable = true;
            };

            my.maintenance = {
              enable = true;
              notifications.enable = true;
            };

            my.matrix.tuwunel = {
              #enable = true;
              publicDomainName = "asampley.ca";
              #sops.enable = true;
            };

            my.monitoring = {
              prometheus = {
                enable = true;
                openFirewall = true;
                ntfy = {
                  enable = true;
                  baseurl = config.my.notifications.ntfy.address;
                  #baseurl = "http://localhost:2586";
                };
              };
            };

            my.users.adamhouston.enable = true;
            #users.users.adamhouston.extraGroups =
            #  [ ] ++ lib.optional config.services.foundryvtt.enable config.users.users.foundryvtt.group;

            my.wireguard = {
              enable = true;
              openFirewall = true;
            };

            my.notifications = {
              enable = true;
              ntfy = {
                enable = true;
                address = "http://localhost:2586";
                sops.enable = true;
              };
            };

            my.ntfy = {
              enable = true;
              base-url = "https://ntfy.asampley.ca";
              openFirewall = true;
              sops.enable = true;
            };

            my.sops.enable = true;

            my.syncthing-wireguard = {
              enable = true;
              peers = [
                self.nixosConfigurations.miranda.config.networking.hostName
              ];
            };

            my.utf-nate.enable = true;

            my.xmpp.prosody = {
              #enable = true;
              publicDomainName = "asampley.ca";
              openFirewall = true;
            };

            # Use the systemd-boot EFI boot loader.
            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;

            system.autoUpgrade = {
              allowReboot = true;
              rebootWindow = {
                lower = "02:00";
                upper = "03:00";
              };
            };

            networking.hostName = "willheim"; # Define your hostname.

            # Enable CUPS to print documents.
            # services.printing.enable = true;

            services.avahi.publish = {
              enable = true;
              addresses = true;
              userServices = true;
            };

            services.openssh = {
              enable = true;
              settings = {
                PasswordAuthentication = false;
                KbdInteractiveAuthentication = false;
              };
            };

            services.conan-exiles = {
              enable = true;
              openFirewall = true;
              modIds = [
                "3725018456"
              ];
            };

            services.prometheus.exporters.node.enable = true;
            services.prometheus.exporters.borg = {
              enable = true;
              user = "borg";
              settings = {
                borg_repos = builtins.attrValues (
                  builtins.mapAttrs (_: value: {
                    path = value.repo;
                    passcommand = "cat ${config.sops.secrets."borg/pass".path}";
                  }) config.services.borgbackup.jobs
                );
              };
            };

            sops.secrets."terraria/pass-env" = {
              owner = config.users.users.terraria.name;
            };

            services.terraria = {
              enable = true;
              openFirewall = true;
              noUPnP = true;
              password = "\${PASS}";
              worldPath = "${config.services.terraria.dataDir}/Joe_Biden's_America.wld";
              package = pkgs.terraria-server.overrideAttrs (
                final: previous: rec {
                  version = "1.4.5.6";
                  urlVersion = lib.replaceStrings [ "." ] [ "" ] version;

                  src = builtins.fetchurl {
                    url = "https://terraria.org/api/download/pc-dedicated-server/terraria-server-${urlVersion}.zip";
                    sha256 = "sha256:0mcigrvmgdbivj4qahswm1shhzrlq58q53wc8hs39z8pq9d4ap6p";
                  };
                }
              );
            };

            services.valheim = {
              enable = true;
              openFirewall = true;
              passwordFile = config.sops.secrets."valheim/password".path;
              name = "Lochheim";
              world = "Lochheim";
            };

            sops.secrets."valheim/password" = {
              owner = config.users.users.steamcmd-valheim.name;
            };

            systemd.services.terraria = {
              serviceConfig = {
                EnvironmentFile = config.sops.secrets."terraria/pass-env".path;
              };
            };

            users.users.terraria.homeMode = "770";

            users.users.borg.extraGroups =
              [ ]
              ++ lib.optionals config.services.terraria.enable [ config.users.users.terraria.group ]
              ++ lib.optionals config.services.conan-exiles.enable [
                config.users.users.${config.my.steamcmd.servers.conan-exiles.user}.group
              ];

            my.backup.borg.jobs.conan-exiles = {
              repo = "ssh://fm2515@fm2515.rsync.net/./backup/conan-exiles";
              paths = "${config.my.steamcmd.servers.conan-exiles.installDir}/ConanSandbox/Saved";

              environment = {
                BORG_REMOTE_PATH = "/usr/local/bin/borg1/borg1";
              };
              encryption = {
                mode = "repokey";
                passCommand = "cat ${config.sops.secrets."borg/pass".path}";
              };
            };

            my.backup.borg.jobs.terraria = {
              repo = "ssh://fm2515@fm2515.rsync.net/./backup/terraria";
              paths = "/var/lib/terraria/";

              environment = {
                BORG_REMOTE_PATH = "/usr/local/bin/borg1/borg1";
              };
              encryption = {
                mode = "repokey";
                passCommand = "cat ${config.sops.secrets."borg/pass".path}";
              };
            };

            my.backup.borg.jobs.valheim = {
              repo = "ssh://fm2515@fm2515.rsync.net/./backup/valheim";
              paths = "${config.my.steamcmd.servers.valheim.homeDir}/.config/unity3d/IronGate/Valheim/worlds_local";

              environment = {
                BORG_REMOTE_PATH = "/usr/local/bin/borg1/borg1";
              };
              encryption = {
                mode = "repokey";
                passCommand = "cat ${config.sops.secrets."borg/pass".path}";
              };
            };

            services.nginx.virtualHosts = {
              "tracker.asampley.ca" = {
                forceSSL = true;
                enableACME = true;
                locations."/" = {
                  proxyPass = "http://localhost:6969/announce";
                  recommendedProxySettings = true;
                };
              };

              "ntfy.asampley.ca" = {
                forceSSL = true;
                enableACME = true;
                locations."/" = {
                  proxyPass = "http://localhost:2586";
                  recommendedProxySettings = true;
                  extraConfig = ''
                    proxy_http_version 1.1;

                    proxy_set_header Upgrade $http_upgrade;
                    proxy_set_header Connection "upgrade";

                    proxy_buffering off;
                    proxy_request_buffering off;
                    proxy_redirect off;

                    proxy_connect_timeout 3m;
                    proxy_send_timeout 3m;
                    proxy_read_timeout 3m;

                    client_max_body_size 0;
                  '';
                };
              };

              "fileshare.asampley.ca" = {
                forceSSL = true;
                enableACME = true;
                locations."/" = {
                  root = "/var/www/";
                  tryFiles = "$uri $uri/ =404";
                  extraConfig = ''
                    autoindex on;
                  '';
                };
              };

              "kairometer.asampley.ca" = {
                forceSSL = true;
                enableACME = true;
                locations."/" = {
                  root = "${inputs'.kairometer.packages.default}";
                  index = "index.html";
                  tryFiles = "$uri $uri.html $uri/ =404";
                };
              };

              "adam.asampley.ca" = {
                forceSSL = true;
                enableACME = true;
                locations."/" = {
                  proxyPass = "http://192.168.4.192:30000";
                  proxyWebsockets = true;
                  recommendedProxySettings = true;
                };
              };
            };

            services.nginx.streamConfig = ''
              server {
                listen 9753 reuseport;
                listen 9753 udp reuseport;
                proxy_timeout 20s;
                proxy_pass 192.168.4.192:30001;
              }
            '';

            environment.etc."utf-nate/1/config.toml".text = ''
              # List of prefixes recognized by the bot
              prefixes = ["!", "‽"]
              # Status setting of the bot
              activity = { Watching = { name = "you." } }
            '';

            environment.etc."utf-nate/2/config.toml".text = ''
              # List of prefixes recognized by the bot
              prefixes = ["?", "‽"]
              # Status setting of the bot
              activity = { Watching = { name = "\U0001F440" } }
            '';

            environment.etc."utf-nate/1/resources".source = "${utf-nate-resources}";
            environment.etc."utf-nate/2/resources".source = "${utf-nate-resources}";

            security.sudo.extraRules = (
              map
                ({ run-service, update-service }: {
                  users = [ config.users.users.utf-nate.name ];
                  commands =
                    (map
                      (mode: {
                        command = "/run/current-system/sw/bin/systemctl ${mode} ${run-service}";
                        options = [ "NOPASSWD" ];
                      })
                      [
                        "start"
                        "stop"
                        "restart"
                      ]
                    )
                    ++ [
                      {
                        command = "/run/current-system/sw/bin/systemctl start ${update-service}";
                        options = [ "NOPASSWD" ];
                      }
                    ];
                })
                (
                  (lib.optional (config.users.users.utf-nate.enable && config.services.conan-exiles.enable) {
                    run-service = config.systemd.services.steam-conan-exiles.name;
                    update-service = config.systemd.services.steamcmd-update-conan-exiles.name;
                  })
                  ++ (lib.optional (config.users.users.utf-nate.enable && config.services.valheim.enable) {
                    run-service = config.systemd.services.steam-valheim.name;
                    update-service = config.systemd.services.steamcmd-update-valheim.name;
                  })
                )
            );

            systemd.targets.multi-user.wants = [
              "utf-nate@1.service"
              "utf-nate@2.service"
            ];

            #services.foundryvtt = {
            #  enable = true;
            #  hostName = "foundryvtt.asampley.ca";
            #  minifyStaticFiles = true;
            #  package = inputs'.foundry-vtt.packages.foundryvtt_14;
            #  proxyPort = 443;
            #  proxySSL = true;
            #  upnp = false;
            #};
            #systemd.services.foundryvtt = {
            #  serviceConfig.StateDirectoryMode = lib.mkForce "0770";
            #};

            sops.secrets."borg/pass" = {
              owner = config.users.users.borg.name;
            };

            my.backup.borg.jobs."${config.my.cloud.nextcloud.borgbackup.name}" = {
              repo = "ssh://fm2515@fm2515.rsync.net/./backup/nextcloud";

              environment = {
                BORG_REMOTE_PATH = "/usr/local/bin/borg1/borg1";
              };

              encryption = {
                mode = "repokey";
                passCommand = "cat ${config.sops.secrets."borg/pass".path}";
              };
            };

            systemd.services.${config.services.prometheus.exporters.borg.serviceName}.serviceConfig = {
              Environment = [
                ''BORG_REMOTE_PATH="/usr/local/bin/borg1/borg1"''
              ];
            };

            # This option defines the first version of NixOS you have installed on this particular machine,
            # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
            #
            # Most users should NEVER change this value after the initial install, for any reason,
            # even if you've upgraded your system to a new NixOS release.
            #
            # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
            # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
            # to actually do that.
            #
            # This value being lower than the current NixOS release does NOT mean your system is
            # out of date, out of support, or vulnerable.
            #
            # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
            # and migrated your data accordingly.
            #
            # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
            system.stateVersion = "25.11"; # Did you read the comment?
          }
        )
      ];
    }
  );
}
