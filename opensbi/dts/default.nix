let
  name = "xiangshan.dtb";
  pkgs = import <nixpkgs> {};
in pkgs.stdenv.mkDerivation {
  inherit name;
  src = pkgs.fetchFromGitHub {
    owner = "OpenXiangShan";
    repo = "nemu_board";
    rev = "37dc20e77a9bbff54dc2e525dc6c0baa3d50f948";
    hash = "sha256-MvmYZqxA1jxHR4Xrw+18EO+b3iqvmn2m9LkcpxqlUg8=";
  };

  buildInputs = [
    pkgs.dtc
  ];
  buildPhase = ''
    cd dts
    dtc -O dtb -o ${name} system.dts
  '';
  installPhase = ''
    mkdir -p $out
    cp ${name} $out/
  '';
}
