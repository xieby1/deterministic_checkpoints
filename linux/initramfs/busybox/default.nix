let
  pname = "busybox";
  version = "1_32_1";
  pkgs = import <nixpkgs> {};
in pkgs.stdenv.mkDerivation {
  inherit pname version;
  src = pkgs.fetchFromGitHub {
    owner = "mirror";
    repo = pname;
    rev = version;
    hash = "sha256-t3S4zfuYN0Jc7tfR+26RZvJZ8PJhbiFsq1zHYQPCsW4=";
  };

  buildInputs = [
    pkgs.pkgsCross.riscv64.stdenv.cc
    pkgs.pkgsCross.riscv64.stdenv.cc.libc.static
  ];

  hardeningDisable = [ "format" "pie" ];

  configurePhase = let
    config = builtins.fetchurl {
      url = "https://github.com/OpenXiangShan/riscv-rootfs/raw/da983ec95858dfd6f30e9feadd534b79db37e618/apps/busybox/config";
      sha256 = "06rhsx949whp8dhfj9snn8494vzi66m7z2wb6xyyfglvcy89x39v";
    };
  in ''
    cp ${config} .config
    chmod +w .config
    echo CONFIG_STATIC=y >> .config
  '';

  doCheck = false;

  installPhase = ''
    mkdir -p $out/bin
    cp busybox $out/bin/
  '';
}
