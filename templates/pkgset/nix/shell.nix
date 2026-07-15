{
  mkShell,
  myPackage,
}:
mkShell {
  inputsFrom = [ myPackage ];
}
