{ stdenv
, fetchFromGitHub
, dtc
}:
let
  name = "xiangshan.dtb";
in stdenv.mkDerivation {
  inherit name;
  src = fetchFromGitHub {
    owner = "OpenXiangShan";
    repo = "nemu_board";
    rev = "37dc20e77a9bbff54dc2e525dc6c0baa3d50f948";
    hash = "sha256-MvmYZqxA1jxHR4Xrw+18EO+b3iqvmn2m9LkcpxqlUg8=";
  };

  buildInputs = [
    dtc
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
