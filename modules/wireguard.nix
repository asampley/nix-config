{ lib, ... }:
{
  flake.nixosModules.wireguard =
    { config, pkgs, ... }:
    {
      options.my.wireguard = with lib; {
        enable = mkEnableOption "wireguard peer settings";
        openFirewall = mkEnableOption "open firewall for receiving initial connections";
      };

      config =
        let
          cfg = config.my.wireguard;
          addressMap = builtins.mapAttrs (n: v: v // { address = [ "192.168.4.${toString v.index}" ]; }) {
            "miranda" = {
              index = 2;
              publicKey = "nRSWAlds+OpZM0t2QJuMD3jXc4reQUICorxy/PGFnww=";
            };
            "willheim" = rec {
              index = 1;
              listenPort = 55820;
              endpoint = "asampley.ca:${toString listenPort}";
              publicKey = "fp6yv+ur1tO/J76yIE9HcU0CMUpOa7WNO6jNIs8MUiM=";
            };
          };
          local = addressMap.${config.networking.hostName};
          others = lib.filterAttrs (name: _: name != config.networking.hostName) addressMap;
        in
        lib.mkIf cfg.enable {
          environment.systemPackages = with pkgs; [
            wireguard-tools
          ];

          networking.wg-quick.interfaces =
            let
            in
            {
              wg0 = {
                address = map (a: "${a}/24") local.address;
                listenPort = if local ? "listenPort" then local.listenPort else null;
                privateKeyFile = "/etc/wireguard/privatekey";

                peers = map (host: {
                  endpoint = if host ? "endpoint" then host.endpoint else null;
                  publicKey = host.publicKey;
                  presharedKeyFile = "/etc/wireguard/presharedkey";
                  allowedIPs = map (a: "${a}/32") host.address;
                }) (builtins.attrValues others);
              };
            };

            networking.firewall.allowedUDPPorts = lib.mkIf cfg.openFirewall [ local.listenPort ];

            networking.hosts = builtins.zipAttrsWith
              (_: values: values)
              (builtins.attrValues
                (builtins.mapAttrs
                  (name: v:
                    builtins.listToAttrs
                    (map
                      (address: { name = address; value = "wg.${name}.local"; })
                      v.address
                    )
                  )
                  others
                )
              );
        };
    };
}
