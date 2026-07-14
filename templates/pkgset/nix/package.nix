{ lib, stdenv }:
stdenv.mkDerivation {
  pname = "my-package";
  version = "1.0.0";

  # Include source except for nix artifacts
  src =
    with lib.fileset;
    toSource {
      root = ../.;
      fileset = difference ../. (unions [
        ../flake.nix
        ../nix
        (maybeMissing ../flake.lock)
      ]);
    };

  installPhase = ''
    mkdir $out
  '';
}
