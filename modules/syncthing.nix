{
  lib,
  ...
}:
{
  flake.nixosModules.syncthing-wireguard =
    { config, ... }:
    {
      options.my.syncthing-wireguard =
        with lib;
        with types;
        {
          enable = mkEnableOption "syncthing over wireguard";
          peers = mkOption {
            type = listOf str;
            default = [ ];
          };
        };

      config =
        let
          cfg = config.my.syncthing-wireguard;
        in
        lib.mkIf cfg.enable {
          services.syncthing = {
            enable = lib.mkDefault true;
            # TODO
            #guiPasswordFile = "/etc/syncthing.passwd";
            openDefaultPorts = true;
            overrideDevices = true;
            overrideFolders = true;

            settings = {
              gui.user = "admin";
              devices = builtins.listToAttrs (
                map (peer: {
                  name = peer;
                  value = {
                    addresses = map (address: "tcp://${address}:22000") config.my.wireguard.addressMap.${peer}.address;
                    id = lib.trim (builtins.readFile ../hosts/${peer}/syncthing.id);
                  };
                }) cfg.peers
              );

              folders = {
                "${config.users.users.syncthing.home}/sync" = {
                  devices = cfg.peers;
                };
              };
            };
          };
        };
    };
}
