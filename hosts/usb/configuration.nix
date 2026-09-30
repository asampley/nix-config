{ self, ... }:
{
  flake.nixosConfigurations.x86_64-linux-usb = self.inputs.nixpkgs.lib.nixosSystem {
    modules = with self.nixosModules; [
      default

      asampley

      installer
      {
        imports = [
          "${self.inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        ];

        nixpkgs.system = "x86_64-linux";

        isoImage.edition = "asampley";
      }
    ];
  };
}
