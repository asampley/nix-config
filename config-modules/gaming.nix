{ lib, ... }:
{
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
