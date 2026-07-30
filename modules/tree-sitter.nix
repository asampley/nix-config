{
  self,
  lib,
  moduleWithSystem,
  ...
}:
{
  # Replace some older tree-sitter-grammars
  flake.overlays.tree-sitter-svelte = final: prev: {
    tree-sitter-grammars = prev.tree-sitter-grammars // {
      tree-sitter-svelte = prev.tree-sitter-grammars.tree-sitter-svelte.overrideAttrs {
        src = self.inputs.tree-sitter-svelte;
      };
    };
  };

  flake.homeModules.tree-sitter-nvim = moduleWithSystem (
    { self', ... }:
    {
      options.my.tree-sitter.nvim = {
        enable = lib.mkEnable "neovim treesitter parsers and highlighters" // {
          default = true;
        };
      };

      config = {
        xdg.dataFile = {
          "nvim/home-manager".source = self'.packages.neovim-tree-sitter;
        };
      };
    }
  );
}
