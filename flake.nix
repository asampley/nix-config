{
  inputs = {
    systems = {
      url = ./systems.nix;
      flake = false;
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Unified style settings for many programs
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };

    utf-nate = {
      url = "github:asampley/UTF-Nate";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-alien.url = "github:thiagokokada/nix-alien";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "git+https://gitlab.com/rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-csshacks = {
      url = "github:MrOtherGuy/firefox-csshacks";
      flake = false;
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (top: {
      imports = [
        inputs.home-manager.flakeModules.home-manager
        (inputs.import-tree ./modules)
        ((inputs.import-tree.filter (p: inputs.nixpkgs.lib.baseNameOf p != "hardware-configuration.nix"))
          ./hosts
        )
      ];
      systems = import ./systems.nix;
      perSystem =
        { pkgs, ... }:
        {
          formatter = pkgs.nixfmt-tree;
          legacyPackages = {
            # Home configurations defined as legacy packages to allow having a default for all systems.
            #
            # Currently it seemse like legacyPackages is checked first for a valid configuration, so all must be here.
            homeConfigurations =
              builtins.mapAttrs (_: value: inputs.home-manager.lib.homeManagerConfiguration value)
                {
                  "asampley" = {
                    inherit pkgs;
                    modules = with inputs.self.homeModules; [
                      default
                    ];
                  };
                  "asampley@amanda" = {
                    inherit pkgs;
                    modules = with inputs.self.homeModules; [
                      inputs.stylix.homeModules.stylix
                      default
                      games
                      gui
                      notifications
                      podman
                      stylix
                      wayland
                      wine
                      {
                        config.my.notifications = {
                          enable = true;
                          libnotify.enable = true;
                        };
                      }
                    ];
                  };
                  "asampley@miranda" = {
                    inherit pkgs;
                    modules = with inputs.self.homeModules; [
                      inputs.sops-nix.homeModules.sops
                      inputs.stylix.homeModules.stylix
                      default
                      games
                      gui
                      nextcloud
                      nextcloud-sops
                      notifications
                      ntfy-client-sops
                      podman
                      sops
                      stylix
                      tablet
                      wayland
                      wine
                      {
                        config.my.tablet.niri = true;
                        config.my.notifications = {
                          enable = true;
                          libnotify.enable = true;
                          ntfy = {
                            enable = true;
                            address = "https://ntfy.asampley.ca";
                            sops.enable = true;
                          };
                        };
                      }
                    ];
                  };
                };
          };
        };
    });
}
