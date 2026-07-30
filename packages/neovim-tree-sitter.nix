{
  lib,
  stdenv,
  tree-sitter-grammars,
}:
# put parsers into a format usable by neovim
stdenv.mkDerivation {
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
        GRAMMAR="${tree-sitter-grammars."tree-sitter-${lang}"}"
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
            builtins.attrNames tree-sitter-grammars
          )
        ))
      )
    )
  );
}
