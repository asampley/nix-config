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
      # Systems to produce flake outputs for
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in
    {
      # Nix formatter, called by nix fmt, change to whatever you'd like.
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      # Exposes packages that are defined in makePkgs. Leave as is.
      legacyPackages = forAllSystems (system: self.lib.makePkgs nixpkgs.legacyPackages.${system});

      # Expose packages where build == host. Leave as is.
      packages = forAllSystems (
        system: nixpkgs.lib.filterAttrs (_: nixpkgs.lib.isDerivation) self.legacyPackages.${system}
      );

      # Function to make cross aware package set like nixpkgs
      # myPkgs contains a callPackage function like nixpkgs to support
      # all the cross compilation facilities built into nixpkgs.
      # in theory these can then be chained with multiple wrapping newScope
      # calls.
      #
      # Is a function to allow consumers to use a different nixpkgs for cross compiling.
      lib.makePkgs =
        pkgs:
        nix-pkgset.lib.makePackageSet "pkgs" pkgs.newScope (myPkgs: {
          # Specify your packages here. They will have all cross compilation that nixpkgs has.

          default = pkgs.hello;
          cross = (
            forAllSystems (
              crossSystem:
              self.lib.makePkgs (
                import nixpkgs {
                  localSystem = pkgs.stdenv.buildPlatform;
                  inherit crossSystem;
                }
              )
            )
          );
        });
    };
}
