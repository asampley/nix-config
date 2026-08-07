{
  flake.nixosModules.auto-certs =
    {
      config,
      lib,
      ...
    }:
    {
      options.my.auto-certs = {
        enable = lib.mkEnableOption "auto generate certs using ACME";
      };

      config =
        let
          cfg = config.my.auto-certs;
        in
        lib.mkIf cfg.enable {
          security.acme = {
            acceptTerms = true;

            certs =
              let
                hosts = config.services.nginx.virtualHosts;
              in
              builtins.listToAttrs (
                map (name: {
                  inherit name;
                  value = { };
                }) (builtins.filter (name: hosts."${name}".enableACME) (builtins.attrNames hosts))
              );
          };
        };
    };
}
