{
  flake.nixosModules.oom =
    { config, lib, ... }:
    {
      options.my.oom = {
        enable = lib.mkEnableOption "Enable early oom service";
      };

      config =
        let
          cfg = config.my.oom;
        in
        lib.mkIf cfg.enable {
          services.earlyoom = {
            enable = true;
            enableNotifications = true;
            freeMemThreshold = 10;
            freeSwapThreshold = 10;
            extraArgs = [
              "--prefer"
              "(nix|rust-analyzer|firefox|chromium)"
            ];
          };
        };
    };
}
