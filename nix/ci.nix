{
  stdenv,
  lib,
  reports,
  artifacts ? [ ],
  ...
}:
stdenv.mkDerivation {
  pname = "kernel_modules";
  version = "0.0.1";
  dontUnpack = true;
  installPhase = ''
    mkdir -p $out

    # Copy all contents from the reports derivation to the output root
    cp -r ${reports}/* $out/

    # Copy build artifacts to the output root
    ${builtins.concatStringsSep "\n" (map (art: "cp -f \"${art}\"/* $out/") artifacts)}
  '';
  meta = {
    description = "ECSE303 Assignment K CI Release Artifacts";
    license = lib.licenses.gpl3Plus;
  };
}
