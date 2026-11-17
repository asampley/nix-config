{ lib, ... }:
{
  flake.nixosModules.wireguard-config =
    { pkgs, ... }:
    {
      config.my.wireguard = {
        networks = {
          # Forwarding to other hosts in the network through willheim
          wg0 = rec {
            ip4 = {
              prefix = "10.2.0.";
              emptySuffix = "0";
              prefixLength = 24;
            };
            ip6 = {
              prefix = "fd02:";
              emptySuffix = ":";
              prefixLength = 16;
            };
            edges = [
              {
                "willheim" = {
                  allowedOnWholeNetwork = true;
                };
                "miranda" = { };
                "phone" = { };
              }
            ];
            nodes = {
              "willheim" =
                let
                  firewallAppend = [
                    {
                      ip4.rule = "FORWARD -i wg0 -o wg0 -j ACCEPT";
                      ip6.rule = "FORWARD -i wg0 -o wg0 -j ACCEPT";
                    }
                    {
                      table = "nat";
                      ip4.rule = "POSTROUTING -s '${ip4.prefix}${ip4.emptySuffix}/${toString ip4.prefixLength}' -o wg0 -j MASQUERADE";
                      ip6.rule = "POSTROUTING -s '${ip6.prefix}${ip6.emptySuffix}/${toString ip6.prefixLength}' -o wg0 -j MASQUERADE";
                    }
                  ];
                in
                rec {
                  ip4.suffix = "1";
                  ip6.suffix = ":1";
                  listenPort = 55821;
                  endpoint = "asampley.ca:${toString listenPort}";
                  postUp = lib.strings.concatLines (
                    map (append: ''
                      ${
                        if append ? ip4 then
                          "${pkgs.iptables}/bin/iptables ${
                            if append ? table then "-t ${append.table}" else ""
                          } -A ${append.ip4.rule}"
                        else
                          ""
                      }
                      ${
                        if append ? ip6 then
                          "${pkgs.iptables}/bin/ip6tables ${
                            if append ? table then "-t ${append.table}" else ""
                          } -A ${append.ip6.rule}"
                        else
                          ""
                      }
                    '') firewallAppend
                  );
                  preDown = lib.strings.concatLines (
                    map (append: ''
                      ${
                        if append ? ip4 then
                          "${pkgs.iptables}/bin/iptables ${
                            if append ? table then "-t ${append.table}" else ""
                          } -D ${append.ip4.rule}"
                        else
                          ""
                      }
                      ${
                        if append ? ip6 then
                          "${pkgs.iptables}/bin/ip6tables ${
                            if append ? table then "-t ${append.table}" else ""
                          } -D ${append.ip6.rule}"
                        else
                          ""
                      }
                    '') firewallAppend
                  );
                };
              "miranda" = {
                ip4.suffix = "2";
                ip6.suffix = ":2";
              };
              "amanda" = {
                ip4.suffix = "3";
                ip6.suffix = ":3";
              };
              "phone" = {
                ip4.suffix = "4";
                ip6.suffix = ":4";
              };
            };
          };
          # Only allow communication to willheim from all other nodes
          wg1 = rec {
            ip4 = {
              prefix = "10.4.";
              emptySuffix = "0.0";
              prefixLength = 16;
            };
            ip6 = {
              prefix = "fd04:";
              emptySuffix = ":";
              prefixLength = 16;
            };
            nodes = {
              "willheim" = rec {
                ip4.suffix = "0.1";
                ip6.suffix = ":1";
                listenPort = 55820;
                endpoint = "asampley.ca:${toString listenPort}";
              };
              "miranda" = {
                ip4.suffix = "0.2";
                ip6.suffix = ":2";
              };
              "adam" = {
                ip4.suffix = "1.1";
                ip6.suffix = ":1:1";
              };
            };
            edges = map (other: {
              "willheim" = { };
              ${other} = { };
            }) (builtins.filter (name: name != "willheim") (builtins.attrNames nodes));
          };
        };
      };
    };
}
