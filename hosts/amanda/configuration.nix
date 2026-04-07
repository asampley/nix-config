{ self, withSystem, ... }:
{
  flake.nixosConfigurations.amanda = withSystem "x86_64-linux" (
    { ... }:
    self.inputs.nixpkgs.lib.nixosSystem {
      modules = builtins.attrValues self.nixosModules ++ [
        self.inputs.sops-nix.nixosModules.sops
        (
          { pkgs, ... }:
          {
            imports = [
              ./hardware-configuration.nix
            ];

            # Custom modules
            my.audio.enable = true;
            my.auto-certs.enable = true;
            my.bluetooth.enable = true;
            my.development.enable = true;
            my.dynamic.enable = true;
            my.gaming.enable = true;
            my.gui.enable = true;
            my.http-file-share.enable = true;

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
            my.wayland.enable = true;

            # Open http ports for file share
            networking.firewall.allowedTCPPorts = [ 80 ];

            # Use the systemd-boot EFI boot loader.
            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;

            networking.hostName = "amanda"; # Define your hostname.

            # enable userspace oom killer
            systemd.oomd = {
              enable = true;
              enableUserSlices = true;
            };

            # enable real-time kit for audio
            security.rtkit.enable = true;

            # Configure keymap in X11
            services.xserver.xkb.layout = "us";
            services.xserver.xkb.options = "eurosign:e,caps:escape";

            # Enable CUPS to print documents.
            # services.printing.enable = true;

            hardware.graphics.enable = true;
            hardware.graphics.enable32Bit = true;

            environment.systemPackages = with pkgs; [
              vulkan-tools
            ];

            services.avahi.publish = {
              enable = true;
              addresses = true;
              userServices = true;
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
