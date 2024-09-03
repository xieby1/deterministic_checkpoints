let
  name = "opensbi";
  pkgs = import <nixpkgs> {};
in pkgs.stdenv.mkDerivation {
  inherit name;

  src = pkgs.fetchFromGitHub {
    owner = "riscv-software-src";
    repo = "opensbi";
    rev = "c4940a9517486413cd676fc8032bb55f9d4e2778";
    hash = "sha256-cV+2DJjlqdG9zR3W6cH6BIZqnuB1kdH3mjc4PO+VPeE=";
  };

  buildInputs = [
    pkgs.python3
    pkgs.pkgsCross.riscv64.stdenv.cc
  ];

  preBuild = ''
    patchShebangs .
  '';

  makeFlags = let
    linux = import ../linux;
    dts = import ./dts;
  in [
    "CROSS_COMPILE=riscv64-unknown-linux-gnu-"
    "PLATFORM=generic"
    "FW_PAYLOAD_PATH=${linux}/arch/riscv/boot/Image"
    "FW_FDT_PATH=${dts}/xiangshan.dtb"
    "FW_PAYLOAD_OFFSET=0x200000"
  ];

  installPhase = ''
    mkdir -p $out
    cp build/platform/generic/firmware/fw_payload.bin $out/
  '';
}
