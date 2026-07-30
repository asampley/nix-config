{
  inputs = {
    systems = {
      url = ./systems.nix;
      flake = false;
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nix-pkgset = {
      url = "github:szlend/nix-pkgset";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    base16.url = "github:SenchoPens/base16.nix";

    # Unified style settings for many programs
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
      inputs.base16.follows = "base16";
    };

    kairometer = {
      url = "github:asampley/kairometer";
      inputs.nixpkgs.follows = "nixpkgs";
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

    battle-net-installer-input = {
      url = "file+https://downloader.battle.net//download/getInstallerForGame?os=win&gameProgram=BATTLENET_APP&version=Live";
      flake = false;
    };

    tree-sitter-svelte = {
      url = "github:tree-sitter-grammars/tree-sitter-svelte";
      flake = false;
    };

    foundry-vtt = {
      url = "github:reckenrode/nix-foundryvtt";
      #inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      base16,
      flake-parts,
      home-manager,
      import-tree,
      nix-pkgset,
      nixpkgs,
      sops-nix,
      ...
    }:
    let
      # List of systems to produce cross outputs for
      # Not all of these will work, might be best to add your own triples.
      forHostSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.doubles.all;
    in
    flake-parts.lib.mkFlake { inherit inputs; } (top: {
      imports = [
        home-manager.flakeModules.home-manager
        (import-tree ./modules)
        (import-tree ./config-modules)
        ((import-tree.filter (p: nixpkgs.lib.baseNameOf p != "hardware-configuration.nix"))
          ./hosts
        )
      ];
      systems = import ./systems.nix;
      flake = {
          # Function to make cross aware package set like nixpkgs
          # myPkgs contains a callPackage function like nixpkgs to support
          # all the cross compilation facilities built into nixpkgs.
          # in theory these can then be chained with multiple wrapping newScope
          # calls.
          #
          # Is a function to allow consumers to use a different nixpkgs for cross compiling.
          lib = {
            makePkgs =
              pkgs:
              nix-pkgset.lib.makePackageSet "pkgs" pkgs.newScope (myPkgs: 
                nixpkgs.lib.filesystem.packagesFromDirectoryRecursive {
                  inherit (myPkgs) callPackage;
                  directory = ./packages;
                } // {
                  inherit (inputs) battle-net-installer-input;
                  cross = (
                  forHostSystems (
                    crossSystem:
                    self.lib.makePkgs (
                      import nixpkgs {
                        localSystem = pkgs.stdenv.buildPlatform;
                        inherit crossSystem;
                      }
                    )
                  )
                );
              }
            );
          color.brighten-hex =
            brighten: c:
            let
              r = nixpkgs.lib.fromHexString (builtins.substring 0 2 c);
              g = nixpkgs.lib.fromHexString (builtins.substring 2 2 c);
              b = nixpkgs.lib.fromHexString (builtins.substring 4 2 c);
              bf = c: c + (255 - c) * brighten;
            in
            nixpkgs.lib.strings.concatMapStrings (c: nixpkgs.lib.toHexString (builtins.floor (bf c))) [
              r
              g
              b
            ];
        };
      };
      perSystem =
        { pkgs, system, ... }:
        {
          _module.args.pkgs = import nixpkgs {
            inherit system;

            overlays = [
              self.overlays.tree-sitter-svelte
            ];
          };

          formatter = pkgs.nixfmt-tree;

          packages = nixpkgs.lib.filterAttrs (_: nixpkgs.lib.isDerivation) self.legacyPackages.${system};

          legacyPackages = self.lib.makePkgs nixpkgs.legacyPackages.${system} //
          {
            # Home configurations defined as legacy packages to allow having a default for all systems.
            #
            # Currently it seemse like legacyPackages is checked first for a valid configuration, so all must be here.
            homeConfigurations =
              builtins.mapAttrs (_: value: home-manager.lib.homeManagerConfiguration value)
                {
                  "asampley" = {
                    inherit pkgs;
                    modules = with self.homeModules; [
                      default
                    ];
                  };
                  "asampley@amanda" = {
                    inherit pkgs;
                    modules = with self.homeModules; [
                      inputs.stylix.homeModules.stylix
                      base16.homeManagerModule
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
                    modules = with self.homeModules; [
                      sops-nix.homeModules.sops
                      inputs.stylix.homeModules.stylix
                      base16.homeManagerModule
                      default
                      games
                      gui
                      nextcloud
                      nextcloud-sops
                      notifications
                      ntfy-client-sops
                      podman
                      sc-controller
                      sops
                      stylix
                      tablet
                      tree-sitter-nvim
                      wayland
                      wine
                      x
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
