{ stdenv
, fetchFromGitHub
, riscv64-cc
, testCase
, opensbi-bin
}:
let
    name = "gcpt-${testCase}";
in stdenv.mkDerivation {
    inherit name;

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
        "GCPT_PAYLOAD_PATH=${opensbi-bin}/fw_payload.${testCase}.bin"
    ];
    buildPhase = ''
        make clean
        make -j $NIX_BUILD_CORES $makeFlags
    '';

    installPhase = ''
        mkdir -p $out
        cp build/gcpt.bin $out/gcpt.${testCase}.bin
        # cp build/gcpt.txt $out/gcpt.${testCase}.txt
    '';
}