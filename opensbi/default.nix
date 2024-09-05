{
  testCase ? "403.gcc"
}:
let
  name = "opensbi-${testCase}";
  pkgs = import <nixpkgs> {};
  linux = import ../linux {inherit testCase;};
  dts = import ./dts;
in pkgs.stdenv.mkDerivation {
  inherit name;

  src = import ./common-build.nix;

  buildInputs = [
    pkgs.python3
    pkgs.pkgsCross.riscv64.stdenv.cc
  ];

  makeFlags = [
    "CROSS_COMPILE=riscv64-unknown-linux-gnu-"
    "PLATFORM=generic"
    "FW_FDT_PATH=${dts}/xiangshan.dtb"
    "FW_PAYLOAD_OFFSET=0x200000"
  ];
  buildPhase = ''
    patchShebangs .

    make -j $NIX_BUILD_CORES $makeFlags FW_PAYLOAD_PATH=${linux}/arch/riscv/boot/Image.${testCase}
  '';

  installPhase = ''
    mkdir -p $out
    mv build/platform/generic/firmware/fw_payload.bin $out/fw_payload.${testCase}.bin
  '';
}
