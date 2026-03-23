{ moduleWithSystem, ... }:
{
  flake.nixosModules.default = moduleWithSystem (
    { inputs', ... }:
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      time.timeZone = lib.mkDefault "Canada/Mountain";

      # Pick only one of the below networking options.
      # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
      networking.networkmanager.enable = lib.mkDefault true; # Easiest to use and most distros use this by default.

      i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Don't forget to set a password with ‘passwd’.
      users.users.asampley = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "plugdev"
        ]
        ++ lib.optional config.services.nginx.enable "nginx"
        ++ lib.optional config.virtualisation.docker.enable "docker";
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGDHPkbNhmExKEsUQ9gn+IzYzRhnG49Q+rwZ/S+mascf asampley@amanda"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDDtgero+Wbw7kq/5t8ylM+tUnRh1o0ca1jTrh9r32PS asampley@miranda"
        ];
      };

      nixpkgs.config.allowUnfreePredicate =
        pkg:
        builtins.elem (lib.getName pkg) [
          "hplip"
          "nvidia-x11"
          "nvidia-settings"
          "nvidia-persistenced"
          "steam"
          "steam-original"
          "steam-unwrapped"
          "steam-run"
          "terraria-server"
        ];

      # List packages installed in system profile. To search, run:
      # $ nix search wget
      environment.systemPackages = with pkgs; [
        git
        inputs'.nix-alien.packages.nix-alien
        vim
        wget
      ];

      services.avahi = {
        # Enable avahi to discover local services
        enable = true;
        # Enable transparent query to avahi daemon
        nssmdns4 = true;
      };

      # Allow users to specify allow_other or allow_root on fuse mounts
      programs.fuse.userAllowOther = true;

      security.acme.defaults = {
        webroot = "/var/lib/acme/acme-challenge";
        email = "alex.sampley@gmail.com";
      };

      services.rsnapshot = {
        extraConfig = ''
          retain hourly 24
          retain daily 365
          retain monthly 12
          retain yearly 10
        '';
        cronIntervals = {
          hourly = "0 * * * *";
          daily = "1 0 * * *";
          monthly = "2 0 1 * *";
          yearly = "3 0 1 1 *";
        };
      };

      # Default virtual host to block unknown server names.
      services.nginx.virtualHosts."_" = {
        default = true;
        extraConfig = "return 404;";
      };

      services.libinput.touchpad = {
        clickMethod = "clickfinger";
      };

      programs.ssh.knownHosts = {
        "fm2515.rsync.net" = {
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINdUkGe6kKn5ssz4WRZKjcws0InbQqZayenzk9obmP1z";
        };
      };

      hardware.steam-hardware.enable = true;
    }
  );

  flake.homeModules.default =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      config = rec {
        # Home Manager needs a bit of information about you and the paths it should
        # manage.
        home.username = "asampley";
        home.homeDirectory = "/home/asampley";

        # This value determines the Home Manager release that your configuration is
        # compatible with. This helps avoid breakage when a new Home Manager release
        # introduces backwards incompatible changes.
        #
        # You should not change this value, even if you update Home Manager. If you do
        # want to update the value, then make sure to first check the Home Manager
        # release notes.
        home.stateVersion = "24.11"; # Please read the comment before changing.

        # Let Home Manager install and manage itself.
        programs.home-manager.enable = true;

        nix.package = pkgs.nix;
        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
        nix.settings.bash-prompt-prefix = "nix-env:";

        nix.gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 30d";
          persistent = true;
          randomizedDelaySec = "45min";
        };

        # The home.packages option allows you to install Nix packages into your
        # environment.
        home.packages = with pkgs; [
          # # Adds the 'hello' command to your environment. It prints a friendly
          # # "Hello, world!" when run.
          # pkgs.hello

          # # It is sometimes useful to fine-tune packages, for example, by applying
          # # overrides. You can do that directly here, just don't forget the
          # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
          # # fonts?
          # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

          # # You can also create simple shell scripts directly inside your
          # # configuration. For example, this adds a command 'my-hello' to your
          # # environment:
          # (pkgs.writeShellScriptBin "my-hello" ''
          #   echo "Hello, ${config.home.username}!"
          # '')

          # terminal packages
          git
          glibcLocales
          keychain
          neovim
          nh
          nixd
          openconnect
          (openssh.override { withKerberos = true; })
          sshfs
          tcpdump
          ripgrep
          unzip
        ];

        nixpkgs.config.allowUnfreePredicate =
          pkg:
          builtins.elem (pkgs.lib.getName pkg) [
            "discord"
          ];

        # Home Manager is pretty good at managing dotfiles. The primary way to manage
        # plain files is through 'home.file'.
        home.file = {
          ".profile".text = (builtins.readFile ../files/.profile) + ''
            . $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh
          '';
          ".bashrc".source = ../files/.bashrc;
          ".bash_profile".source = ../files/.bash_profile;
          ".bash_logout".source = ../files/.bash_logout;
          ".editorconfig".source = ../files/.editorconfig;
        };

        xdg.configFile = {
          # Link to repository in home-manager for easy changes and testing as it's already stored in its own repo
          # Though this does disable rollbacks, they can be done with git easily enough
          "nvim".source =
            config.lib.file.mkOutOfStoreSymlink "${home.homeDirectory}/.config/home-manager/files/.config/nvim";
        };
        # Home Manager can also manage your environment variables through
        # 'home.sessionVariables'. These will be explicitly sourced when using a
        # shell provided by Home Manager. If you don't want to manage your shell
        # through Home Manager then you have to manually source 'hm-session-vars.sh'
        # located at either
        #
        #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
        #
        # or
        #
        #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
        #
        # or
        #
        #  /etc/profiles/per-user/asampley/etc/profile.d/hm-session-vars.sh
        #
        home.sessionVariables = {
          EDITOR = "nvim";
          VISUAL = "nvim";
          NH_HOME_FLAKE = "${home.homeDirectory}/.config/home-manager";
        };

        services.home-manager.autoUpgrade = {
          enable = true;
          useFlake = true;
          frequency = "Mon *-*-* 00:00:00";
        };

        systemd.user.services.home-manager-auto-upgrade.Unit = {
          OnFailure = lib.mkIf (
            config.systemd.user.services ? "notify-on-failure@"
          ) "notify-on-failure@home-manager-auto-upgrade.service";
          OnSuccess = lib.mkIf (
            config.systemd.user.services ? "notify-on-success@"
          ) "notify-on-success@home-manager-auto-upgrade.service";
        };
      };
    };
}
