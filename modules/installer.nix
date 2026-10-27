{ lib, ... }:
{
  flake.nixosModules.installer =
    { ... }:
    {
      config = {
        networking.hostName = lib.mkDefault "installer";

        services.avahi.settings.publish = {
          disable-publishing = false;
          publish-addresses = true;
          disable-user-service-publishing = false;
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
