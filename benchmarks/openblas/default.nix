{ pkgs ? import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/tarball/release-23.11";
    sha256 = "sha256:1f5d2g1p6nfwycpmrnnmc2xmcszp804adp16knjvdkj8nz36y1fg";
  }) {}
}: pkgs.stdenv.mkDerivation {
  pname = "openblas";
  version = "0.3.28";
  src = pkgs.fetchFromGitHub {
    owner = "OpenMathLib";
    repo = "OpenBLAS";
    rev = "v0.3.28";
    hash = "sha256-430zG47FoBNojcPFsVC7FA43FhVPxrulxAW3Fs6CHo8=";
  };

  depsBuildBuild = [
    pkgs.stdenv.cc
    pkgs.gfortran
    pkgs.glibc
    pkgs.glibc.static
  ];

  buildPhase = let
    makeFlags_common = [
      "CC=${pkgs.stdenv.cc}/bin/gcc"
      "FC=${pkgs.gfortran}/bin/gfortran"
    ];
    makeFlags1 = makeFlags_common ++ [
      "NO_STATIC=0"
      "NO_SHARED=1"
    ];
    makeFlags2 = makeFlags_common ++ [
      # benchmark/Makefile uses `cc` to compile and link, does not use `ld` directly.
      # Therefore, benchmark/Makefile does not receive LDFLAGS, only receives CFLAGS
      "CFLAGS=\"-L${pkgs.gfortran.cc}/lib -static\""
      "FFLAGS=\"-L${pkgs.gfortran.cc}/lib -static\""
      "-C benchmark"
    ];
  in ''
    # 1. compile libopenblas
    make ${builtins.toString makeFlags1}
    # 2. compile benchmark
    make ${builtins.toString makeFlags2}
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp benchmark/*.goto $out/bin/
  '';
  doCheck = false;
}
