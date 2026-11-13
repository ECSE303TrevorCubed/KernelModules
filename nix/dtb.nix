{
  stdenv,
  dtc,
  lib,
  ...
}:
stdenv.mkDerivation {
  pname = "dht11_overlay";
  version = "0.0.1";
  src = ../c;
  nativeBuildInputs = [ dtc ];
  buildPhase = ''
    runHook preBuild
    dtc -I dts -O dtb -o dht11-overlay.dtb -b 0 -@ dht11.dts
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    install -Dm644 dht11-overlay.dtb "$out/dht11-overlay.dtb"
    runHook postInstall
  '';
  meta = {
    description = "Device tree overlay for DHT11 sensor";
    license = lib.licenses.gpl3Plus;
  };
}
