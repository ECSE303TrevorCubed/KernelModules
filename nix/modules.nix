{
  stdenv,
  lib,
  kernel,
  buildPackages,
  ...
}:
stdenv.mkDerivation {
  pname = "kernel_modules";
  version = "0.0.1";
  src = ../c;

  nativeBuildInputs = kernel.moduleBuildDependencies;
  depsBuildBuild = [ buildPackages.stdenv.cc ];
  makeFlags = [
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "ARCH=${stdenv.hostPlatform.linuxArch}"
    "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
  ];
  buildFlags = [ "modules" ];

  installPhase = ''
    runHook preInstall
    install -Dm644 blink_km.ko "$out/blink_km.ko"
    install -Dm644 dht11.ko "$out/dht11.ko"
    runHook postInstall
  '';

  meta = {
    description = "ECSE303 Lab K kernel modules (blink_km, dht11)";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
