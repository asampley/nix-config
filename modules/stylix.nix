{
  flake.nixosModules.stylix =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.stylix = {
        enable = lib.mkEnableOption "stylix styles";
      };

      config = lib.mkIf config.my.stylix.enable {
        stylix = {
          enable = lib.mkDefault true;
          overlays.enable = lib.mkDefault false;
          base16Scheme = lib.mkDefault "${pkgs.base16-schemes}/share/themes/darkviolet.yaml";
          autoEnable = lib.mkDefault false;
        };

        console.colors = with config.lib.stylix.colors; [
          base00
          base08
          base0B
          base0A
          base0D
          base0F
          base0C
          base05
          base00
          base08
          base0B
          base0A
          base0D
          base0F
          base0C
          base05
        ];
      };
    };

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

        stylix.overlays.enable = false;

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
