{ lib, ... }:
{
  flake.nixosModules.matrix =
    {
      config,
      ...
    }:
    {
      options.my.matrix = with lib; {
        tuwunel = {
          enable = mkEnableOption "tuwunel matrix server";
          domainName = mkOption {
            type = types.str;
            default = "matrix.${config.my.matrix.tuwunel.publicDomainName}";
          };
          publicDomainName = mkOption {
            type = types.str;
          };
          registrationTokenFile = mkOption {
            type = types.str;
            description = "allow registration with a token";
          };
        };
      };

      config =
        let
          cfg = config.my.matrix;
        in
        lib.mkMerge [
          (lib.mkIf cfg.tuwunel.enable {
            services.matrix-tuwunel = {
              enable = true;
              settings.global = {
                server_name = "${cfg.tuwunel.publicDomainName}";
                port = [ 8008 ];
                allow_federation = false;
                allow_registration = (cfg.tuwunel.registrationTokenFile != null);
                registration_token_file = "${cfg.tuwunel.registrationTokenFile}";
              };
            };

            services.nginx.virtualHosts."${cfg.tuwunel.publicDomainName}" =
              lib.mkIf (cfg.tuwunel.publicDomainName != null)
                {
                  forceSSL = true;
                  enableACME = true;
                  locations = {
                    "= /.well-known/matrix/server" = {
                      extraConfig = ''
                        add_header Access-Control-Allow-Origin *;
                        default_type application/json;
                      '';
                      return = "200 '{\"m.server\": \"${cfg.tuwunel.domainName}:443\"}'";
                    };

                    "= /.well-known/matrix/client" = {
                      extraConfig = ''
                        add_header Access-Control-Allow-Origin *;
                        default_type application/json;
                      '';
                      return = "200 '{\"m.homeserver\": {\"base_url\": \"https://${cfg.tuwunel.domainName}\"}}'";
                    };
                  };
                };

            services.nginx.virtualHosts."${cfg.tuwunel.domainName}" =
              lib.mkIf (cfg.tuwunel.domainName != null)
                {
                  enableACME = true;
                  forceSSL = true;
                  locations = {
                    "/" = {
                      proxyPass = "http://localhost:${toString (builtins.elemAt config.services.matrix-tuwunel.settings.global.port 0)}";
                      recommendedProxySettings = true;
                    };
                  };
                };
          })
        ];
    };

  flake.nixosModules.matrix-sops =
    { config, ... }:
    {
      options.my.matrix = with lib; {
        tuwunel.sops.enable = mkEnableOption "sops management of secrets";
      };

      config = lib.mkIf config.my.matrix.tuwunel.sops.enable {
        sops.secrets."tuwunel/registration-token" = {
          owner = config.services.matrix-tuwunel.user;
          restartUnits = [ "tuwunel.service" ];
        };

        my.matrix.tuwunel.registrationTokenFile = config.sops.secrets."tuwunel/registration-token".path;
      };
    };
}
