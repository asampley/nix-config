{ self, ... }:
{
  flake.templates.default = self.templates.pkgset;

  # Cross compile friendly flake template
  flake.templates.pkgset = {
    path = ../templates/pkgset;
    description = "pkgset for cross compilation flakes";
  };
}
