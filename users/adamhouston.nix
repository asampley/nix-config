{ lib, ... }:
{
  flake.nixosModules.adamhouston =
    { config, ... }:
    {
      options.my.users.adamhouston = with lib; {
        enable = mkEnableOption "user adamhouston";
      };

      config.users.users.adamhouston = {
        enable = config.my.users.adamhouston.enable;
        isNormalUser = true;
        openssh.authorizedKeys.keyFiles = [
          ../files/ssh/adamhouston.pub
        ];
      };
    };
}
