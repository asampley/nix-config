{ inputs, ... }:

{
  flake.homeModules.stylix =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.stylix = {
        enable = lib.mkEnableOption "stylix styles" // {
          default = true;
        };
      };

      config = lib.mkIf config.my.stylix.enable {
        stylix.enable = lib.mkDefault true;

        stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/darkviolet.yaml";

        stylix.fonts.sizes.desktop = 10;
        stylix.image = ../files/wallpaper.jpg;

        stylix.targets = {
          firefox = {
            enable = true;
            profileNames = [
              "default"
              "work"
            ];
          };

          # Custom css created
          waybar.enable = false;
        };

        xdg.configFile = {
          "tinted-theming.list".text = lib.strings.concatStringsSep "\n" (
            map (key: "${config.lib.stylix.colors.${key}}") (
              builtins.genList (i: "base0" + lib.toHexString i) 16
            )
          );
        };
      };
    };
}
