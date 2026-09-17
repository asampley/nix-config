{ lib, ... }:
{
  flake.nixosModules.wireguard =
    { config, pkgs, ... }:
    {
      options.my.wireguard =
        with lib;
        with types;
        {
          enable = mkEnableOption "wireguard peer settings";
          openFirewall = mkEnableOption "open firewall for receiving initial connections";
          addressMap = mkOption {
            type = attrs;
            default = {
              "willheim" = rec {
                index = 1;
                listenPort = 55820;
                endpoint = "asampley.ca:${toString listenPort}";
                peers = [
                  "miranda"
                  "phone"
                  "adam"
                ];
              };
              "miranda" = {
                index = 2;
                networkpeer = "willheim";
              };
              "phone" = {
                index = 4;
                networkpeer = "willheim";
              };
              "adam" = {
                index = 192;
                peers = [ "willheim" ];
              };
            };
            apply =
              value:
              builtins.mapAttrs (
                n: v:
                v
                // {
                  address = [ "192.168.4.${toString v.index}" ];
                  publicKey = lib.trim (builtins.readFile ../hosts/${n}/wireguard.pub);
                }
              ) value;
          };
        };

      config =
        let
          cfg = config.my.wireguard;
          local = cfg.addressMap.${config.networking.hostName};
          others = lib.filterAttrs (name: _: builtins.any (n: n == name) local.peers or [ ]) cfg.addressMap;
        in
        lib.mkIf cfg.enable {
          environment.systemPackages = with pkgs; [
            wireguard-tools
          ];

          networking.wg-quick.interfaces = {
            wg0 = {
              address = map (a: "${a}/24") local.address;
              listenPort = local.listenPort or null;
              privateKeyFile = "/etc/wireguard/privatekey";

              peers =
                map (host: {
                  endpoint = host.endpoint or null;
                  publicKey = host.publicKey;
                  presharedKeyFile = "/etc/wireguard/presharedkey";
                  allowedIPs = map (a: "${a}/32") host.address;
                }) (builtins.attrValues others)
                ++ lib.optional (local ? networkpeer) (
                  let
                    peer = cfg.addressMap.${local.networkpeer};
                  in
                  {
                    endpoint = peer.endpoint or null;
                    publicKey = peer.publicKey;
                    presharedKeyFile = "/etc/wireguard/presharedkey";
                    allowedIPs = [ "192.168.4.0/24" ];
                  }
                );

              preUp = local.preUp or "";
              postUp = local.postUp or "";
              preDown = local.preDown or "";
              postDown = local.postDown or "";
            };
          };

          networking.firewall.allowedUDPPorts = lib.mkIf cfg.openFirewall [ local.listenPort ];

          networking.hosts = builtins.zipAttrsWith (_: values: values) (
            builtins.attrValues (
              builtins.mapAttrs (
                name: v:
                builtins.listToAttrs (
                  map (address: {
                    name = address;
                    value = "wg.${name}.local";
                  }) v.address
                )
              ) others
            )
          );
        };
    };
}
