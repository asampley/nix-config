{ lib, ... }:
{
  flake.nixosModules.users =
    { config, ... }:
    {
      options.my.users = with lib; {
        adamhouston.enable = lib.mkEnableOption "user adamhouston";
        asampley.enable = mkEnableOption "user asampley";
      };

      config = {
        users.users = {
          asampley = {
            enable = config.my.users.asampley.enable;
            isNormalUser = true;
            extraGroups = [
              "wheel"
              "plugdev"
            ]
            ++ lib.optional config.services.nginx.enable "nginx"
            ++ lib.optional config.virtualisation.docker.enable "docker";
            openssh.authorizedKeys.keyFiles = [
              ../hosts/amanda/ssh.pub
              ../hosts/miranda/ssh.pub
            ];
          };

          adamhouston = {
            enable = config.my.users.adamhouston.enable;
            isNormalUser = true;
            openssh.authorizedKeys.keyFiles = [
              ../hosts/adam/ssh.pub
            ];
          };
        };
      };
    };
}
