{
  stdenv,
  typst,
  lib,
  ...
}:
stdenv.mkDerivation {
  pname = "kernel_modules_report";
  version = "0.0.1";
  src = ../report;
  nativeBuildInputs = [ typst ];
  buildPhase = ''
    runHook preBuild
    typst compile report.typ report.pdf
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    install -Dm644 report.pdf "$out/kernel_modules_report.pdf"
    runHook postInstall
  '';
  meta = {
    description = "ECSE303 Lab K Report";
    license = lib.licenses.gpl3Plus;
  };
}
