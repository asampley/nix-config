{
  mkShell,
  myPackage,
}:
mkShell {
  withInputsFrom = myPackage;
}
