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

  installPhase =
    let
      prefix = "tree-sitter-";
      prefixLength = builtins.stringLength prefix;
      langs = map (name: builtins.substring prefixLength (builtins.stringLength name) name) (
        builtins.filter (name: (builtins.substring 0 prefixLength name) == prefix) (
          builtins.attrNames tree-sitter-grammars
        )
      );
      langPaths = map (lang: "${tree-sitter-grammars."tree-sitter-${lang}"}") langs;
      count = builtins.length langs;
    in
    ''
      mkdir -p $out/parser
      GRAMMARS=(${lib.strings.concatStringsSep " " langPaths})
      LANGS=(${lib.strings.concatStringsSep " " langs})

      for i in $(seq 0 ${toString (count - 1)}); do
        GRAMMAR=''${GRAMMARS[i]}
        LANG=''${LANGS[i]}
        ln -s "$GRAMMAR/parser" "$out/parser/$LANG.so"
        QUERIES="$GRAMMAR/queries"

        if [ -e "$QUERIES" ]; then
          find "$QUERIES" -type f -print0 | while read -d "" QUERY; do
            DIR=$(dirname "$QUERY")
            OUT=queries/$LANG/''${QUERY##$QUERIES}
            mkdir -p "$out/$(dirname $OUT)"

            substitute "$QUERY" "$out/$OUT" --replace-quiet '(#is-not? local)' ""
          done
        fi
      done
    '';
}
