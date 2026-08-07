{ lib, ... }:
{
  flake.nixosModules.asampley =
    { config, ... }:
    {
      options.my.users.asampley = with lib; {
        enable = mkEnableOption "user asampley";
      };

      config.users.users.asampley = {
        enable = config.my.users.asampley.enable;
        isNormalUser = true;
        extraGroups = [
          config.users.groups.wheel.name
        ]
        ++ lib.optional config.virtualisation.docker.enable "docker"
        ++ lib.optional (config.users.groups ? plugdev) config.users.groups.plugdev.name;
        openssh.authorizedKeys.keyFiles = [
          ../files/ssh/asampley${"@"}amanda.pub
          ../files/ssh/asampley${"@"}miranda.pub
        ];
      };
    };
}
