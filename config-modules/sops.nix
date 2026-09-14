{ lib, ... }:
{
  flake.nixosModules.sops =
    { config, pkgs, ... }:
    {
      options.my.sops = with lib; {
        enable = mkEnableOption "sops secret management";
      };

      config =
        let
          cfg = config.my.sops;
        in
        lib.mkIf cfg.enable {
          environment.systemPackages = with pkgs; [
            sops
            (writeShellScriptBin "sops-edit" ''
              export SOPS_AGE_KEY_CMD="${ssh-to-age}/bin/ssh-to-age -private-key -i '${builtins.elemAt config.sops.age.sshKeyPaths 0}'"
              ${sops}/bin/sops edit ${config.sops.defaultSopsFile}
            '')
          ];
          sops.defaultSopsFile = lib.mkDefault "/root/sops/secrets/main.yaml";
          sops.validateSopsFiles = lib.mkDefault false;
          sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        };
    };

  flake.nixosModules.sops-syncthing =
    { config, ... }:
    {
      options.my.sops.syncthing = with lib; {
        enable = mkEnableOption "source sops file from syncthing";
      };

      config =
        let
          cfg = config.my.sops.syncthing;
        in
        lib.mkIf cfg.enable {
          sops.defaultSopsFile = "/var/lib/syncthing/sops/secrets/main.yaml";
        };
    };

  flake.homeModules.sops =
    { config, pkgs, ... }:
    {
      config = {
        home.packages = with pkgs; [
          age
          sops
        ];

        sops = {
          defaultSopsFile = "${config.home.homeDirectory}/.secrets/${config.home.username}.yaml";
          age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
          # runtime evaluation of files, without storing in the store
          validateSopsFiles = false;
        };
      };
    };
}
