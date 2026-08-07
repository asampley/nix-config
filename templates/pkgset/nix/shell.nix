{
  mkShell,
  my-package,
}:
mkShell {
  inputsFrom = [ my-package ];
}
