{
  flake.nixosModules.bluetooth =
    { config, lib, ... }:
    {
      options.my.bluetooth = {
        enable = lib.mkEnableOption "bluetooth";
      };

      config = lib.mkIf config.my.bluetooth.enable {
        hardware.bluetooth.enable = true;
        services.blueman.enable = true;
      };
    };
}
