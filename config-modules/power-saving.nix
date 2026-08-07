{
  flake.nixosModules.power-saving =
    {
      config,
      lib,
      ...
    }:
    {
      options.my.power-saving = {
        enable = lib.mkEnableOption "power saving processes";
      };

      config = lib.mkIf config.my.power-saving.enable {
        services.tlp.enable = true;
      };
    };
}
