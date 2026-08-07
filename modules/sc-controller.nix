{
  lib,
  ...
}:
{
  flake.overlays.sc-controller = final: prev: {
    sc-controller = prev.sc-controller.overrideAttrs (
      final-pkg: prev-pkg: {
        # Seems required for loading bluetooth
        postFixup = prev-pkg.postFixup + ''
          wrapProgram $out/bin/scc-daemon --set PATH ${lib.makeBinPath [ final.binutils ]}
        '';
      }
    );
  };

  flake.homeModules.sc-controller =
    { config, pkgs, ... }:
    {
      options.my.programs.sc-controller = with lib; {
        enable = mkEnableOption "sc-controller with software" // {
          default = true;
        };
        package = mkPackageOption pkgs "sc-controller" { };
      };

      config =
        let
          cfg = config.my.programs.sc-controller;
        in
        lib.mkIf cfg.enable {
          home.packages = [
            cfg.package
          ];

          xdg.configFile = {
            # Make out of store symlink to allow sc-controller to make changes to be saved
            "scc/profiles".source =
              config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/home-manager/files/.config/scc/profiles";
          };
        };
    };
}
