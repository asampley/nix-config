{
  flake.nixosModules.audio =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.audio = {
        enable = lib.mkEnableOption "audio settings";
      };

      config =
        let
          cfg = config.my.audio;
        in
        lib.mkIf cfg.enable {
          services.pipewire = {
            enable = true;
            alsa.enable = true;
            alsa.support32Bit = true;
            pulse.enable = true;
          };

          environment.systemPackages =
            with pkgs;
            [
              alsa-utils
            ]
            ++ lib.optionals config.hardware.graphics.enable [
              pavucontrol
            ];
        };
    };
}
