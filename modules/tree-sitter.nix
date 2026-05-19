{ self, lib, moduleWithSystem, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        # put parsers into a format usable by neovim
        neovim-tree-sitter = pkgs.stdenv.mkDerivation {
          name = "neovim-tree-sitter";

          unpackPhase = null;

          phases = [ "installPhase" ];

          installPhase = lib.strings.concatStringsSep "\n" (
            [
              ''
                set -x
                mkdir -p $out/parser
              ''
            ]
            ++ (map
              (lang: ''
                GRAMMAR="${pkgs.tree-sitter-grammars."tree-sitter-${lang}"}"
                ln -s "$GRAMMAR/parser" "$out/parser/${lang}.so"
                QUERIES="$GRAMMAR/queries"

                if [ -e "$QUERIES" ]; then
                  find "$QUERIES" -type f -print0 | while read -d "" QUERY; do
                    DIR=$(dirname "$QUERY")
                    OUT=queries/${lang}/''${QUERY##$QUERIES}
                    mkdir -p "$out/$(dirname $OUT)"

                    substitute "$QUERY" "$out/$OUT" --replace-quiet '(#is-not? local)' ""
                  done
                fi
              '')
              (
                let
                  prefix = "tree-sitter-";
                  prefixLength = builtins.stringLength prefix;
                in
                #[
                #  "rust"
                #]
                (map (name: builtins.substring prefixLength (builtins.stringLength name) name) (
                  builtins.filter (name: (builtins.substring 0 prefixLength name) == prefix) (
                    builtins.attrNames pkgs.tree-sitter-grammars
                  )
                ))
              )
            )
          );
        };
      };
    };

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
