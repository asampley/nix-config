{
  inputs,
  lib,
  moduleWithSystem,
  ...
}:
{
  flake.homeModules.gui = moduleWithSystem (
    { inputs', ... }:
    {
      config,
      pkgs,
      ...
    }:
    {
      config = {
        home.packages = with pkgs; [
          bitwarden-desktop
          chromium
          dconf
          dex
          discord
          gnome-network-displays
          inkscape
          kdePackages.kdenlive
          libreoffice
          mpv
          qbittorrent
          thunar
          xournalpp
        ];

        home.file =
          let
            c = "${inputs.firefox-csshacks}/chrome";
            imports = map (i: if builtins.pathExists i then i else throw "Error: path ${i} does not exist") [
              "${c}/icon_only_tabs.css"
            ];
          in
          builtins.listToAttrs (
            map (name: {
              name = ".mozilla/firefox/${name}/chrome/userChrome.css";
              value = {
                text = lib.strings.concatLines (map (i: "@import \"${i}\";") imports);
              };
            }) (builtins.attrNames config.programs.firefox.profiles)
          );

        programs.alacritty = {
          enable = true;
        };

        programs.firefox = {
          enable = true;
          policies = {
            DisableTelemetry = true;
            DisableFirefoxAccounts = true;
            EnableTrackingProtection.Value = true;
          };
          profiles =
            let
              shared-profile = {
                search = {
                  force = true;
                  default = "ddg";
                  privateDefault = "ddg";

                  engines = {
                    "Nix Packages" = {
                      urls = [
                        {
                          template = "https://search.nixos.org/packages";
                          params = [
                            {
                              name = "channel";
                              value = "unstable";
                            }
                            {
                              name = "query";
                              value = "{searchTerms}";
                            }
                          ];
                        }
                      ];
                      icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                      definedAliases = [ "@np" ];

                    };

                    "Nix Options" = {
                      urls = [
                        {
                          template = "https://search.nixos.org/options";
                          params = [
                            {
                              name = "channel";
                              value = "unstable";
                            }
                            {
                              name = "query";
                              value = "{searchTerms}";
                            }
                          ];
                        }
                      ];
                      icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                      definedAliases = [ "@no" ];
                    };

                    "NixOS Wiki" = {
                      urls = [
                        {
                          template = "https://wiki.nixos.org/w/index.php";
                          params = [
                            {
                              name = "search";
                              value = "{searchTerms}";
                            }
                          ];
                        }
                      ];
                      icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                      definedAliases = [ "@nw" ];
                    };
                  };
                };

                settings = {
                  # Automatically reload session after closing
                  "browser.sessionstore.resume_session_once" = true;
                  # Automatically install plugins
                  "extensions.autoDisableScopes" = 0;
                  # Finger-printing protection with dark mode support
                  "privacy.fingerprintingProtection" = true;
                  "privacy.fingerprintingProtection.overrides" = "+AllTargets,-CssPrefersColorScheme";
                  # Use custom css defined in userChrome.css
                  "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
                };

                extensions = {
                  packages = with inputs'.firefox-addons.packages; [
                    ublock-origin
                  ];
                };
              };
            in
            {
              default = lib.mkMerge [
                shared-profile
                {
                  id = 0;
                }
              ];
              work = lib.mkMerge [
                shared-profile
                {
                  id = 1;
                }
              ];
            };
        };

        programs.obs-studio = {
          enable = true;
          plugins = [
            pkgs.obs-studio-plugins.obs-pipewire-audio-capture
          ];
        };

        dconf.settings = {
          "org/gnome/desktop/interface" = {
            color-scheme = lib.mkForce "prefer-dark";
          };
        };

        fonts.fontconfig.enable = true;
      };
    }
  );
}
