{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-pkgset = {
      url = "github:szlend/nix-pkgset";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nix-pkgset,
      nixpkgs,
      ...
    }:
    let
      # List of systems to produce flake outputs for
      forBuildSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
      # List of systems to produce cross outputs for
      # Not all of these will work, might be best to add your own triples.
      forHostSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.doubles.all;
    in
    {
      # Nix formatter, called by nix fmt, change to whatever you'd like.
      formatter = forBuildSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      # Exposes packages that are defined in makePkgs. Leave as is.
      legacyPackages = forBuildSystems (system: self.lib.makePkgs nixpkgs.legacyPackages.${system});

      # Expose packages where build == host. Leave as is.
      packages = forBuildSystems (
        system: nixpkgs.lib.filterAttrs (_: nixpkgs.lib.isDerivation) self.legacyPackages.${system}
      );

      # Expose dev shells where build == host. Leave as is
      devShells = forBuildSystems (system: {
        default = (self.lib.makePkgs nixpkgs.legacyPackages.${system}).callPackage nix/shell.nix { };
      });

      # Function to make cross aware package set like nixpkgs
      # myPkgs contains a callPackage function like nixpkgs to support
      # all the cross compilation facilities built into nixpkgs.
      # in theory these can then be chained with multiple wrapping newScope
      # calls.
      #
      # Is a function to allow consumers to use a different nixpkgs for cross compiling.
      lib.makePkgs =
        pkgs:
        nix-pkgset.lib.makePackageSet "pkgs" pkgs.newScope (
          myPkgs:
          # Put your packages in nix/packages. They will have all cross compilation that nixpkgs has.
          # These can be build using flakes like `nix build .#cross.<crossSystem>.myPackage
          nixpkgs.lib.filesystem.packagesFromDirectoryRecursive {
            inherit (myPkgs) callPackage;
            directory = ./nix/packages;
          }
          // {
            default = myPkgs.my-package;
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
    };
}
