{ lib, moduleWithSystem, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.sc-controller = pkgs.sc-controller.overrideAttrs (final: prev:
        {
          # Seems required for loading bluetooth
          postFixup = prev.postFixup + ''
            wrapProgram $out/bin/scc-daemon --set PATH ${with pkgs; lib.makeBinPath [ binutils ]}
          '';
        }
      );
    };

  flake.homeModules.sc-controller = moduleWithSystem (
    { self', ... }:
    { config, pkgs, ... }:
    {
      options.my.programs.sc-controller = with lib; {
        enable = mkEnableOption "sc-controller with software" // { default = true; };
        package = mkPackageOption self'.packages "sc-controller" { };
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
            "scc/profiles".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/home-manager/files/.config/scc/profiles";
          };
        };
    }
  );
}
