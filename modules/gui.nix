{
  inputs,
  lib,
  moduleWithSystem,
  ...
}:
{
  flake.nixosModules.gui =
    { config, pkgs, ... }:
    {
      options.my.gui = with lib; {
        enable = mkEnableOption "gui setup";
      };

      config = lib.mkIf config.my.gui.enable {
        environment.systemPackages = with pkgs; [
          firefox
        ];
      };
    };

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
                  # Use custom css defined in userChrome.css
                  "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
                  # Enable HTTPS-Only Mode
                  "dom.security.https_only_mode" = true;
                  "dom.security.https_only_mode_ever_enabled" = true;
                  # Privacy settings
                  "privacy.donottrackheader.enabled" = true;
                  "privacy.fingerprintingProtection" = true;
                  "privacy.fingerprintingProtection.overrides" = "+AllTargets,-CSSPrefersColorScheme";
                  "privacy.trackingprotection.enabled" = true;
                  "privacy.trackingprotection.crytpomining.enabled" = true;
                  "privacy.trackingprotection.emailtracking.enabled" = true;
                  "privacy.trackingprotection.emailtracking.pbmode.enabled" = true;
                  "privacy.trackingprotection.pbmode.enabled" = false;
                  "privacy.trackingprotection.socialtracking.enabled" = true;
                  "privacy.partition.network_state.ocsp_cache" = true;
                  # Disable Firefox 'experiments'
                  "experiments.activeExperiment" = false;
                  "experiments.enabled" = false;
                  "experiments.supported" = false;
                  "network.allow-experiments" = false;
                  # Disable Firefox features
                  "extensions.pocket.enabled" = false;
                  "identity.fxaccounts.enabled" = false;
                  # Disable telemetry
                  "datareporting.healthreport.uploadEnabled" = false;
                  "datareporting.policy.dataSubmissionEnabled" = false;
                  "datareporting.usage.uploadEnabled" = false;
                  "toolkit.telemetry.archive.enabled" = false;
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
