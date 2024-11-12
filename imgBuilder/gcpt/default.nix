{ stdenv
, fetchFromGitHub
, callPackage

, riscv64-cc
, riscv64-libc-static
, riscv64-busybox
, benchmark
}: let
  opensbi = callPackage ../opensbi {
    inherit riscv64-cc riscv64-libc-static riscv64-busybox benchmark;
  };
in stdenv.mkDerivation {
  name = "${benchmark.name}.gcpt";

    src = fetchFromGitHub {
        owner = "OpenXiangShan";
        repo = "LibCheckpointAlpha";
        rev = "c5c2fef74133fb2b8ef8642633f60e0996493f29";
        hash = "sha256-Rxlv47QY273jbcSX/A1PuT7+2aCB2sVW32pL91G3BmI=";
    };

    buildInputs = [
        riscv64-cc
    ];
    makeFlags = [
        "CROSS_COMPILE=riscv64-unknown-linux-gnu-"
        "GCPT_PAYLOAD_PATH=${opensbi}"
    ];
    buildPhase = ''
        make clean
        make -j $NIX_BUILD_CORES $makeFlags
    '';

    installPhase = ''
        cp build/gcpt.bin $out
    '';
}
