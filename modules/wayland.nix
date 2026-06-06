{ moduleWithSystem, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages = with pkgs; {
        monitors-power = (
          writeShellScriptBin "monitors-power" (builtins.readFile ../scripts/wayland/monitors-power)
        );
        fuzzel-power-menu = (
          writeShellScriptBin "fuzzel-power-menu" (builtins.readFile ../scripts/wayland/fuzzel-power-menu)
        );
        niri-fuzzel-monitor-orientation = (
          writeShellScriptBin "niri-fuzzel-monitor-orientation" (
            builtins.readFile ../scripts/wayland/niri-fuzzel-monitor-orientation
          )
        );
      };
    };

  flake.nixosModules.wayland =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.wayland = {
        enable = lib.mkEnableOption "wayland window manager and settings";
      };

      config =
        let
          cfg = config.my.wayland;
        in
        lib.mkIf cfg.enable {
          # Make sure we use a wayland supported display manager
          services.displayManager.ly = {
            enable = true;
            settings = {
              full_color = false;
              bg = "0x0001";
              fg = "0x0008";
              border_fg = "0x0008";
              error_bg = "0x0001";
              error_fg = "0x0002";

              animation = "gameoflife";
              gameoflife_fg = "0x0005";
              gameoflife_frame_delay = 6;
              gameoflife_entropy_interval = 10;

              bigclock = "en";

              default_input = "password";

              vi_mode = true;
              vi_default_mode = "insert";
            };
          };

          # Window manager which I haven't found a way yet to use home-manager
          programs.niri.enable = true;
        };
    };

  flake.homeModules.wayland = moduleWithSystem (
    { self', ... }:
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      config = {
        xdg.configFile = {
          "niri".source = pkgs.symlinkJoin {
            name = "niri-config";
            paths = [
              ../files/.config/niri
              (
                with config.lib.stylix.colors;
                pkgs.writeTextDir "style.kdl" ''
                  overview {
                    backdrop-color "#${base00}"
                    workspace-shadow {
                      color "#${base05}"
                    }
                  }

                  layout {
                    focus-ring {
                      active-color "#${base0D}"
                      inactive-color "#${base03}"
                    }

                    border {
                      active-color "#${base0D}"
                      inactive-color "#${base03}"
                      urgent-color "#${base08}"
                    }

                    shadow {
                      color "#${base05}77"
                    }
                  }
                ''
              )
            ];
          };

          # Generated from stylix
          "waybar/stylix.css".text = ''
            * {
                font-family: "${config.stylix.fonts.monospace.name}";
                font-size: ${toString config.stylix.fonts.sizes.desktop}pt;
            }
          ''
          + lib.strings.concatMapStrings (
            key: "@define-color base0${key} #${config.lib.stylix.colors."base0${key}"};\n"
          ) (builtins.genList (i: lib.toHexString i) 16);
        }
        // (
          let
            entries = builtins.readDir ../files/.config/waybar;
            names = builtins.attrNames entries;
          in
          builtins.listToAttrs (
            map (name: {
              name = "waybar/${name}";
              value = {
                source = ../files/.config/waybar/${name};
              };
            }) names
          )
        );

        home.packages = with pkgs; [
          self'.packages.fuzzel-power-menu
          self'.packages.niri-fuzzel-monitor-orientation
          # command line brightness
          brightnessctl
          # render icons in waybar
          nerd-fonts.symbols-only
          # on screen keyboard
          squeekboard
          # desktop background
          swaybg
          # clipboard command line and integration
          wl-clipboard
          # x application shim
          xwayland-satellite
        ];

        # Niri default terminal
        programs.alacritty.enable = true;

        # App launcher
        programs.fuzzel.enable = true;

        # Lock
        programs.swaylock.enable = true;

        programs.waybar = {
          enable = true;
          systemd = {
            enable = true;
          };
        };

        # Notifications
        services.mako.enable = true;

        # Idle timeout
        services.swayidle =
          let
            lock = "${pkgs.swaylock}/bin/swaylock --daemonize";
            lockWarn = "${pkgs.libnotify}/bin/notify-send 'Locking in ${toString lockNotifySecs} seconds' --urgency low --expire-time ${toString lockNotifySecs}000";
            monitors-power = "${self'.packages.monitors-power}/bin/monitors-power";
            lockSecs = 900;
            lockNotifySecs = 30;
          in
          {
            enable = true;
            extraArgs = [
              "-d"
            ];
            timeouts = [
              {
                timeout = lockSecs - lockNotifySecs;
                command = lockWarn;
              }
              {
                timeout = lockSecs;
                command = lock;
              }
              {
                timeout = lockSecs + 5;
                command = "${monitors-power} off";
                resumeCommand = "${monitors-power} on";
              }
            ];
            events = {
              before-sleep = "${monitors-power} off; ${lock}";
              lock = "${monitors-power} off; ${lock}";
              after-resume = "${monitors-power} on";
              unlock = "${monitors-power} on";
            };
          };

        services.polkit-gnome.enable = true;

        systemd.user.services = {
          waybar-profile = {
            Unit = {
              Description = "set up window manager config for waybar";
              After = [ "graphical-session.target" ];
              PartOf = [ "graphical-session.target" ];
            };

            Install = {
              WantedBy = [
                "graphical-session.target"
                "waybar.service"
              ];
            };

            Service = {
              Type = "oneshot";
              ExecStart =
                with pkgs;
                "${writeShellScript "waybar-wm" ''
                  set -eux
                  cd "${config.home.homeDirectory}/.config/waybar/"

                  wm_file="wm/$XDG_SESSION_DESKTOP.jsonc"
                  wm_target="wm.jsonc"

                  if [ -e "$wm_file" ]; then
                    ${coreutils}/bin/ln -sf "$wm_file" "$wm_target"
                  elif [ -e "$wm_target" ]; then
                    rm "$wm_target"
                  fi
                ''}";
            };
          };

          on-screen-keyboard = {
            Unit = {
              Description = "on screen keyboard";
              After = [ "graphical-session.target" ];
              PartOf = [ "graphical-session.target" ];
              ConditionEnvironment = "WAYLAND_DISPLAY";
            };

            Install = {
              WantedBy = [ "graphical-session.target" ];
            };

            Service = {
              ExecStart = with pkgs; "${squeekboard}/bin/squeekboard";
            };
          };

          swaybg = {
            Unit = {
              Description = "set background";
              After = [ "graphical-session.target" ];
              PartOf = [ "graphical-session.target" ];
              ConditionEnvironment = "WAYLAND_DISPLAY";
            };

            Install = {
              WantedBy = [ "graphical-session.target" ];
            };

            Service = {
              ExecStart = with pkgs; "${swaybg}/bin/swaybg -i ${config.stylix.image}";
            };
          };
        };
      };
    }
  );
}
