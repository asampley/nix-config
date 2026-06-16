{ self, lib, ... }:
{
  flake.lib = {
    color.brighten-hex =
      brighten: c:
      let
        r = lib.fromHexString (builtins.substring 0 2 c);
        g = lib.fromHexString (builtins.substring 2 2 c);
        b = lib.fromHexString (builtins.substring 4 2 c);
        bf = c: c + (255 - c) * brighten;
      in
      lib.strings.concatMapStrings (c: lib.toHexString (builtins.floor (bf c))) [
        r
        g
        b
      ];
  };

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
          base16Scheme = "${pkgs.base16-schemes}/share/themes/darkviolet.yaml";
          override =
            let
              base-scheme = config.lib.base16.mkSchemeAttrs config.stylix.base16Scheme;
              bh = self.lib.color.brighten-hex 0.1;
            in
            # Augment to base-24
            {
              base10 = bh base-scheme.base08;
              base11 = bh base-scheme.base09;
              base12 = bh base-scheme.base0A;
              base13 = bh base-scheme.base0B;
              base14 = bh base-scheme.base0C;
              base15 = bh base-scheme.base0D;
              base16 = bh base-scheme.base0E;
              base17 = bh base-scheme.base0F;
            };
          autoEnable = lib.mkDefault false;
        };

        console.colors = with config.lib.stylix.colors; [
          base00 # "black"
          red
          green
          yellow
          blue
          magenta
          cyan
          base05 # "dark white"

          base03 # "light black"
          bright-red
          bright-green
          bright-yellow
          bright-blue
          bright-magenta
          bright-cyan
          base07 # "white"
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
        stylix.override =
          let
            base-scheme = config.lib.base16.mkSchemeAttrs config.stylix.base16Scheme;
            bh = self.lib.color.brighten-hex 0.1;
          in
          # Augment to base-24
          {
            base10 = bh base-scheme.base08;
            base11 = bh base-scheme.base09;
            base12 = bh base-scheme.base0A;
            base13 = bh base-scheme.base0B;
            base14 = bh base-scheme.base0C;
            base15 = bh base-scheme.base0D;
            base16 = bh base-scheme.base0E;
            base17 = bh base-scheme.base0F;
          };
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
