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
                ipBlock = mkOption {
                  type = str;
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
                    address = "${network.ipBlock}.${toString node.index}";
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
              address = [ "${local.address}/24" ];
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
                      presharedKeyFile = "/etc/wireguard/presharedkey";
                      allowedIPs = [
                        "${peerNode.address}/32"
                      ]
                      ++ lib.optionals peerCfg.allowedOnWholeNetwork or false [ "${networkCfg.ipBlock}.0/24" ];
                    }
                  ) peers
                )
              ) edges;

              preUp = local.preUp or "";
              postUp = local.postUp or "";
              preDown = local.preDown or "";
              postDown = local.postDown or "";
            }
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
                    map (
                      peer:
                      let
                        peerNode = networkCfg.nodes.${peer};
                      in
                      {
                        name = peerNode.address;
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
