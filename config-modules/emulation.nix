{
  flake.nixosModules.emulation =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.emulation = {
        enable = lib.mkEnableOption "emulation service";
      };

      config = lib.mkIf config.my.emulation.enable {
        boot.binfmt.emulatedSystems = builtins.filter (system: system != pkgs.hostPlatform) [
          "aarch64-linux"
        ];
      };
    };
}
