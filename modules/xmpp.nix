{
  flake.nixosModules.xmpp =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.xmpp = with lib; {
        prosody = {
          enable = mkEnableOption "prosody XMPP server";
          domainName = mkOption {
            type = types.str;
            default = "xmpp.${config.my.xmpp.prosody.publicDomainName}";
          };
          publicDomainName = mkOption {
            type = types.str;
          };
          openFirewall = mkEnableOption "open firewall for basic client server ports";
        };
      };

      config =
        let
          cfg = config.my.xmpp;
          sslCertDir = config.security.acme.certs."${cfg.prosody.publicDomainName}".directory;
        in
        lib.mkMerge [
          (lib.mkIf cfg.prosody.enable {
            networking.firewall = {
              allowedTCPPorts = lib.optionals cfg.prosody.openFirewall [
                5222
                5223
                5269
                5270
              ];
            };

            services.prosody = {
              enable = true;
              admins = [ "asampley@${cfg.prosody.publicDomainName}" ];
              allowRegistration = lib.mkDefault false;
              authentication = "internal_plain";
              s2sSecureAuth = lib.mkDefault true;
              s2sRequireEncryption = lib.mkDefault true;
              c2sRequireEncryption = lib.mkDefault true;
              ssl = {
                cert = "${sslCertDir}/fullchain.pem";
                key = "${sslCertDir}/key.pem";
              };
              virtualHosts = {
                "${cfg.prosody.publicDomainName}" = {
                  domain = "${cfg.prosody.publicDomainName}";
                  enabled = true;
                };
              };
              modules = {
                admin_adhoc = lib.mkDefault false;
                bosh = lib.mkDefault true;
                cloud_notify = lib.mkDefault false;
                blocklist = lib.mkDefault true;
                bookmarks = lib.mkDefault true;
                dialback = lib.mkDefault false;
                ping = lib.mkDefault false;
                private = lib.mkDefault false;
                register = lib.mkDefault false;
                vcard_legacy = lib.mkDefault true;
                websocket = lib.mkDefault true;
              };
              muc = [
                {
                  domain = "conference.${cfg.prosody.domainName}";
                  restrictRoomCreation = false;
                }
              ];
              httpFileShare = {
                domain = "upload.${cfg.prosody.domainName}";
              };
              disco_items = [
                {
                  description = "http file share";
                  url = "upload.${cfg.prosody.domainName}";
                }
              ];
              xmppComplianceSuite = lib.mkDefault true;
              extraConfig = ''
                c2s_direct_tls_ports = { 5223 }
                s2s_direct_tls_ports = { 5270 }
              '';
            };

            # certs for xmpp
            security.acme.certs."${cfg.prosody.publicDomainName}" = {
              extraDomainNames = [
                "upload.${cfg.prosody.domainName}"
                "conference.${cfg.prosody.domainName}"
              ];
              postRun = ''
                ${pkgs.acl}/bin/setfacl -m u:prosody:rx "${
                  config.security.acme.certs.${cfg.prosody.publicDomainName}.directory
                }"
                ${pkgs.acl}/bin/setfacl -m u:prosody:r "${
                  config.security.acme.certs.${cfg.prosody.publicDomainName}.directory
                }"/*.pem
              '';
              reloadServices = [ "prosody" ];
            };

            services.nginx.virtualHosts."${cfg.prosody.publicDomainName}" = {
              serverAliases = [
                "conference.${cfg.prosody.domainName}"
                "upload.${cfg.prosody.domainName}"
              ];
              enableACME = true;
            };
          })
        ];
    };
}
