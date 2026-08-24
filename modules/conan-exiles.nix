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
              postUpdate = ''
                MOD_DIR='${config.my.steamcmd.servers.conan-exiles.installDir}/Mods'
                mkdir -p "$MOD_DIR"
                echo > "$MOD_DIR/modlist.txt"
                ${lib.strings.concatLines (
                  map (
                    modId:
                    ''find '${config.my.steamcmd.servers.conan-exiles.modDir}/steamapps/workshop/content/${config.my.steamcmd.servers.conan-exiles.workshop.id}/${modId}/' -name '*.pak' >> "$MOD_DIR/modlist.txt"''
                  ) cfg.modIds
                )}
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
