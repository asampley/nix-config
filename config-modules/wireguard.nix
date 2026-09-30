{ lib, ... }:
{
  flake.nixosModules.wireguard-config =
    { pkgs, ... }:
    {
      config.my.wireguard = {
        networks = {
          wg0 = rec {
            ipBlock = "192.168.2";
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
                    { rule = "FORWARD -i wg0 -o wg0 -j ACCEPT"; }
                    {
                      table = "nat";
                      rule = "POSTROUTING -s ${ipBlock}.0/24 -o wg0 -j MASQUERADE";
                      excludeIp6 = true;
                    }
                  ];
                in
                rec {
                  index = 1;
                  listenPort = 55821;
                  endpoint = "asampley.ca:${toString listenPort}";
                  postUp = lib.strings.concatLines (
                    map (append: ''
                      ${pkgs.iptables}/bin/iptables ${
                        if append ? table then "-t ${append.table}" else ""
                      } -A ${append.rule}
                      ${
                        if !(append.excludeIp6 or false) then
                          "${pkgs.iptables}/bin/ip6tables ${
                            if append ? table then "-t ${append.table}" else ""
                          } -A ${append.rule}"
                        else
                          ""
                      }
                    '') firewallAppend
                  );
                  preDown = lib.strings.concatLines (
                    map (append: ''
                      ${pkgs.iptables}/bin/iptables ${
                        if append ? table then "-t ${append.table}" else ""
                      } -D ${append.rule}
                      ${
                        if !(append.excludeIp6 or false) then
                          "${pkgs.iptables}/bin/ip6tables ${
                            if append ? table then "-t ${append.table}" else ""
                          } -D ${append.rule}"
                        else
                          ""
                      }
                    '') firewallAppend
                  );
                };
              "miranda" = {
                index = 2;
              };
              "amanda" = {
                index = 3;
              };
              "phone" = {
                index = 4;
              };
            };
          };
          wg1 = {
            ipBlock = "192.168.4";
            edges = [
              {
                "willheim" = { };
                "adam" = { };
              }
            ];
            nodes = {
              "willheim" = rec {
                index = 1;
                listenPort = 55820;
                endpoint = "asampley.ca:${toString listenPort}";
              };
              "adam" = {
                index = 192;
              };
            };

          };
        };
      };
    };
}
