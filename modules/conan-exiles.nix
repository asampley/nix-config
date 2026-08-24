{
  lib,
  ...
}:
{
  flake.nixosModules.conan-exiles =
    { config, pkgs, ... }:
    {
      options.services.conan-exiles =
        with lib;
        with types;
        {
          enable = mkEnableOption "Conan Exiles server";
          openFirewall = mkEnableOption "open firewall ports";
          modIds = mkOption {
            type = listOf str;
            default = [ ];
          };
        };

      config =
        let
          cfg = config.services.conan-exiles;
        in
        {
          my.steamcmd = {
            enable = cfg.enable;
            servers.conan-exiles = {
              appId = "443030";
              workshop = {
                id = "440900";
                modIds = cfg.modIds;
              };
              start = pkgs.writeShellScript "conan-exiles-start.sh" ''
                ${pkgs.steam-run}/bin/steam-run ./ConanSandboxServer.sh
              '';
              openFirewall = lib.mkIf cfg.openFirewall {
                allowedTCPPorts = [
                  7777
                ];
                allowedUDPPorts = [
                  7777
                  7778
                  27015
                ];
              };
            };
          };
        };
    };
}
