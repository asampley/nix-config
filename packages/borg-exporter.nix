{
  borgbackup,
  rustPlatform,
  fetchgit,
  makeWrapper,
}:
rustPlatform.buildRustPackage (finalAttrs: rec {
  pname = "borg-exporter";
  version = "0.1.1";

  src = fetchgit {
    url = "https://codeberg.org/mmakowski/borg-exporter.git";
    rev = "6f25798e13e7e9b327068119ed9d28ab7defa64e";
    hash = "sha256-Zzw61PfSYwb0EUbnvZyck1quN6/+vjOpCpwXsMfIe5I=";
  };

  cargoLock.lockFile = "${finalAttrs.src}/Cargo.lock";

  buildInputs = [ makeWrapper ];
  postInstall = "wrapProgram $out/bin/${pname} --prefix PATH : ${borgbackup}/bin";
})
