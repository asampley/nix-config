{ lib, ... }:
{
  flake.nixosModules.x =
    {
      config,
      ...
    }:
    {
      options.my.x = {
        enable = lib.mkEnableOption "x11 window manager and settings";
      };

      config =
        let
          cfg = config.my.x;
        in
        lib.mkIf cfg.enable {
          # Enable the X11 windowing system.
          services.xserver.enable = true;

          # x server locking tool
          programs.slock.enable = true;

          services.xserver.windowManager.openbox.enable = true;
          services.xserver.windowManager.awesome.enable = true;
        };
    };

  flake.homeModules.x =
    {
      config,
      pkgs,
      ...
    }:
    {
      options.my.x = with lib; {
        enable = mkEnableOption "x11 configuration" // {
          default = true;
        };
        xinit = mkEnableOption "xinit startup files instead of a display manager option";
      };

      config =
        let
          cfg = config.my.x;
        in
        lib.mkIf cfg.enable {
          home.packages = with pkgs; [
            awesome
            scrot
            xclip
            xss-lock
          ];

          home.file = lib.mkIf cfg.xinit {
            ".xsession".source = ../files/.xsession;
            ".xinitrc".source = ../files/.xinitrc;
          };

          xdg.configFile = {
            "awesome".source =
              config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/home-manager/files/.config/awesome";
          };

          systemd.user.services.xautolock-session = {
            Unit = {
              Description = "xautolock, session locker service";
              After = [ "graphical-session.target" ];
              PartOf = [ "graphical-session.target" ];
              # do not start if running under wayland
              ConditionEnvironment = "!WAYLAND_DISPLAY";
            };

            Install = {
              WantedBy = [ "graphical-session.target" ];
            };

            Service = {
              ExecStart = lib.concatStringsSep " " [
                "${pkgs.xautolock}/bin/xautolock"
                "-time 10"
                "-locker '${pkgs.systemd}/bin/loginctl lock-session \${XDG_SESSION_ID}'"
                "-detectsleep"
                "-corners -0-0"
              ];
              Restart = "always";
            };
          };
        };
    };
}
