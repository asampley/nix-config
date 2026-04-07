{ self, withSystem, ... }:
{
a
  flake.nixosConfigurations.miranda = withSystem "x86_64-linux" (
    { ... }:
    self.inputs.nixpkgs.lib.nixosSystem {
      modules = builtins.attrValues self.nixosModules ++ [
        self.inputs.nixos-hardware.nixosModules.framework-12-13th-gen-intel
        self.inputs.sops-nix.nixosModules.sops
        (
          { config, pkgs, ... }:
          {
            imports = [
              # Include the results of the hardware scan.
              ./hardware-configuration.nix
            ];

            # Custom modules
            my.audio.enable = true;
            my.bluetooth.enable = true;
            my.development.enable = true;
            my.dynamic.enable = true;
            #my.emulation.enable = true;
            my.gaming.enable = true;
            my.gui.enable = true;
            #my.http-file-share.enable = true;

            my.maintenance = {
              enable = true;
              notifications.enable = true;
            };

            my.mobile.enable = true;
            my.noise-reduce.enable = true;

            my.notifications = {
              enable = true;
              libnotify.enable = true;
            };

            my.oom.enable = true;
            my.power-saving.enable = true;
            my.sops.enable = true;
            my.wayland.enable = true;
            my.x.enable = false;
            my.zsa-keyboard.enable = true;

            # Use the systemd-boot EFI boot loader.
            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;

            networking.hostName = "miranda"; # Define your hostname.

            # Configure keymap in X11
            services.xserver.xkb.layout = "us";
            services.xserver.xkb.options = "eurosign:e,caps:escape";

            # Enable CUPS to print documents.
            services.printing = {
              enable = true;
              browsing = true;
              drivers = with pkgs; [
                cups-filters
                cups-browsed
                gutenprint
                #hplip
                hplipWithPlugin
              ];
            };

            # Enable touchpad support (enabled default in most desktopManager).
            services.libinput.enable = true;

            swapDevices = [
              {
                device = "/swapfile";
                size = 16 * 1024;
              }
            ];

            # hibernation
            boot.kernelParams = [
              "resume_offset=168685568"
              "mem_sleep_default=deep"
            ]; # a better way to do this than check and hardcode?
            boot.resumeDevice = config.fileSystems."/".device;
            powerManagement.enable = true;
            systemd.sleep.settings.Sleep = {
              HibernateDelaySec = "15m";
              SuspendState = "mem";
            };

            # power keys
            services.logind.settings.Login = {
              HandlePowerKey = "suspend-then-hibernate";
              HandlePowerKeyLongPress = "poweroff";
              HandleLidSwitch = "suspend-then-hibernate";
              HandleLidSwitchDocked = "ignore";
            };

            # This option defines the first version of NixOS you have installed on this particular machine,
            # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
            #
            # Most users should NEVER change this value after the initial install, for any reason,
            # even if you've upgraded your system to a new NixOS release.
            #
            # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
            # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
            # to actually do that.
            #
            # This value being lower than the current NixOS release does NOT mean your system is
            # out of date, out of support, or vulnerable.
            #
            # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
            # and migrated your data accordingly.
            #
            # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
            system.stateVersion = "24.11"; # Did you read the comment?
          }
        )
      ];
    }
  );
}
