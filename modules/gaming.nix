{ self, lib, ... }:
{
  perSystem = { pkgs, ... }: {
    packages.battle-net-installer = pkgs.writeShellScriptBin "battle-net-installer" ''
      set -eux
      export WINEPREFIX=$HOME/.wine-nix/battle-net
      export WINEARCH=win64
      export PATH=${
        lib.makeBinPath [
          pkgs.wineWow64Packages.staging
          pkgs.findutils
          pkgs.cabextract
          pkgs.zstd
        ]
      }
      ${pkgs.winetricks}/bin/winetricks corefonts dxvk ucrtbase2019
      wine ${self.inputs.battle-net}
    '';
  };

  flake.nixosModules.gaming =
    {
      config,
      pkgs,
      ...
    }:
    {
      options.my.gaming = {
        enable = lib.mkEnableOption "gaming service";
      };

      config = lib.mkIf config.my.gaming.enable {
        programs.steam = {
          enable = true;
          extest.enable = true;
          remotePlay.openFirewall = true;
          dedicatedServer.openFirewall = true;
          localNetworkGameTransfers.openFirewall = true;
        };

        hardware.xpadneo.enable = true;

        environment.systemPackages = with pkgs; [
          steam-run
          vulkan-tools
        ];
      };
    };

  flake.homeModules.games =
    { pkgs, ... }:
    {
      config = {
        home.packages = with pkgs; [
          prismlauncher
        ];
      };
    };
}
