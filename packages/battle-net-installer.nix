{
  lib,
  battle-net-installer-input,
  cabextract,
  findutils,
  winetricks,
  wineWow64Packages,
  writeShellScriptBin,
  zstd,
}:
writeShellScriptBin "battle-net-installer" ''
  set -eux
  export WINEPREFIX=$HOME/.wine-nix/battle-net
  export WINEARCH=win64
  export PATH=${
    lib.makeBinPath [
      cabextract
      findutils
      wineWow64Packages.staging
      zstd
    ]
  }
  ${winetricks}/bin/winetricks corefonts dxvk ucrtbase2019
  wine ${battle-net-installer-input}
''
