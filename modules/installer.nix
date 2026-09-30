{ lib, ... }:
{
  flake.nixosModules.installer =
    { ... }:
    {
      config = {
        networking.hostName = lib.mkDefault "installer";

        services.avahi.publish = {
          enable = true;
          addresses = true;
          userServices = true;
        };

        services.openssh = {
          enable = true;
          settings = {
            PermitRootLogin = "no";
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;
          };
        };
      };
    };
}
