{
  lib,
  ...
}:
{
  flake.nixosModules.valheim =
    { config, pkgs, ... }:
    {
      options.services.valheim =
        with lib;
        with types;
        {
          enable = mkEnableOption "Valheim server";
          openFirewall = mkEnableOption "open firewall ports";
          passwordFile = mkOption {
            type = path;
          };
          port = mkOption {
            type = port;
            default = 2456;
          };
          name = mkOption {
            type = str;
            default = "Valheim server";
          };
          world = mkOption {
            type = str;
            default = "Valheim";
          };
        };

      config =
        let
          cfg = config.services.valheim;
        in
        {
          my.steamcmd = {
            enable = cfg.enable;
            servers.valheim = {
              appId = "896660";
              start = pkgs.writeShellScript "valheim_start.sh" ''
                export LD_LIBRARY_PATH=./linux64:$LD_LIBRARY_PATH
                export SteamAppId=892970

                echo "Starting server PRESS CTRL-C to exit"

                # Tip: Make a local copy of this script to avoid it being overwritten by steam.
                # NOTE: Minimum password length is 5 characters & Password cant be in the server name.
                # NOTE: You need to make sure the ports 2456-2458 is being forwarded to your server through your local router & firewall.
                ${pkgs.steam-run}/bin/steam-run ./valheim_server.x86_64 -nographics -name '${cfg.name}' -port ${toString cfg.port} -world '${cfg.world}' -password $(cat '${cfg.passwordFile}')
              '';
              openFirewall = lib.mkIf cfg.openFirewall {
                allowedTCPPorts = [
                  cfg.port
                  (cfg.port + 1)
                  (cfg.port + 2)
                ];
                allowedUDPPorts = [
                  cfg.port
                  (cfg.port + 1)
                  (cfg.port + 2)
                ];
              };
            };
          };
        };
    };
}
