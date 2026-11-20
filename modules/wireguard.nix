{ lib, ... }:
{
  flake.nixosModules.wireguard =
    { config, pkgs, ... }:
    let
    in
    {
      options.my.wireguard =
        with lib;
        with types;
        {
          enable = mkEnableOption "wireguard peer settings";
          openFirewall = mkEnableOption "open firewall for receiving initial connections";
          networks = mkOption {
            type = attrsOf (submodule {
              options = {
                ip4 = mkOption {
                  type = (
                    submodule {
                      options = {
                        prefix = mkOption {
                          type = str;
                        };
                        emptySuffix = mkOption {
                          type = str;
                        };
                        prefixLength = mkOption {
                          type = ints.positive;
                        };
                      };
                    }
                  );
                };
                ip6 = mkOption {
                  type = (
                    submodule {
                      options = {
                        prefix = mkOption {
                          type = str;
                        };
                        emptySuffix = mkOption {
                          type = str;
                        };
                        prefixLength = mkOption {
                          type = ints.positive;
                        };
                      };
                    }
                  );
                };
                edges = mkOption {
                  type = listOf attrs;
                };
                nodes = mkOption {
                  type = attrs;
                };
              };
            });
            apply =
              value:
              lib.recursiveUpdate value (
                builtins.mapAttrs (name: network: {
                  nodes = builtins.mapAttrs (nodeName: node: {
                    ip4Address =
                      if network ? ip4 && node ? ip4 then "${network.ip4.prefix}${toString node.ip4.suffix}" else null;
                    ip6Address =
                      if network ? ip6 && node ? ip6 then "${network.ip6.prefix}${toString node.ip6.suffix}" else null;
                    publicKey = lib.trim (builtins.readFile ../hosts/${nodeName}/wireguard.pub);
                  }) network.nodes;
                }) value
              );
          };
        };

      config =
        let
          cfg = config.my.wireguard;
        in
        lib.mkIf cfg.enable {
          environment.systemPackages = with pkgs; [
            wireguard-tools
          ];

          networking.wg-quick.interfaces = builtins.mapAttrs (
            networkName: networkCfg:
            let
              local = networkCfg.nodes.${config.networking.hostName};
              edges = builtins.filter (value: value ? ${config.networking.hostName}) networkCfg.edges;
            in
            {
              address =
                [ ]
                ++ lib.optional (
                  local.ip4Address != null
                ) "${local.ip4Address}/${toString networkCfg.ip4.prefixLength}"
                ++ lib.optional (
                  local.ip6Address != null
                ) "${local.ip6Address}/${toString networkCfg.ip6.prefixLength}";
              listenPort = local.listenPort or null;
              privateKeyFile = "/etc/wireguard/privatekey";

              peers = builtins.concatMap (
                edge:
                let
                  peers = lib.filterAttrs (name: _: name != config.networking.hostName) edge;
                in
                builtins.attrValues (
                  builtins.mapAttrs (
                    peer: peerCfg:
                    let
                      peerNode = networkCfg.nodes.${peer};
                    in
                    {
                      endpoint = peerNode.endpoint or null;
                      publicKey = peerNode.publicKey;
                      presharedKeyFile = "/etc/wireguard/presharedkeys/${peer}";
                      allowedIPs =
                        [ ]
                        ++ lib.optional (peerNode.ip4Address != null) (
                          if peerCfg.allowedOnWholeNetwork or false then
                            with networkCfg.ip4; "${prefix}${emptySuffix}/${toString prefixLength}"
                          else
                            "${peerNode.ip4Address}/32"
                        )
                        ++ lib.optional (peerNode.ip6Address != null) (
                          if peerCfg.allowedOnWholeNetwork or false then
                            with networkCfg.ip6; "${prefix}${emptySuffix}/${toString prefixLength}"
                          else
                            "${peerNode.ip6Address}/128"
                        );
                    }
                  ) peers
                )
              ) edges;
            }
            // (local.extraConfig or { })
          ) (lib.filterAttrs (name: network: network.nodes ? ${config.networking.hostName}) cfg.networks);

          networking.firewall.allowedUDPPorts = lib.mkIf cfg.openFirewall (
            builtins.attrValues (
              builtins.mapAttrs (
                networkName: networkCfg: networkCfg.nodes.${config.networking.hostName}.listenPort
              ) cfg.networks
            )
          );

          networking.hosts = builtins.listToAttrs (
            builtins.concatLists (
              builtins.attrValues (
                builtins.mapAttrs (
                  networkName: networkCfg:
                  (builtins.concatMap (
                    edge:
                    let
                      peers = builtins.attrNames (lib.filterAttrs (name: _: name != config.networking.hostName) edge);
                    in
                    lib.concatMap (
                      peer:
                      let
                        peerNode = networkCfg.nodes.${peer};
                      in
                      [ ]
                      ++ lib.optional (peerNode.ip4Address != null) {
                        name = peerNode.ip4Address;
                        value = [ "${networkName}.${peer}.local" ];
                      }
                      ++ lib.optional (peerNode.ip6Address != null) {
                        name = peerNode.ip6Address;
                        value = [ "${networkName}.${peer}.local" ];
                      }
                    ) peers
                  ) networkCfg.edges)
                ) cfg.networks
              )
            )
          );
        };
    };
}
