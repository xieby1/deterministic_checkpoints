{ stdenv
, python3

, testCase
, riscv64-cc
, linux
, dts
, opensbi-common-build
}:
let
  name = "opensbi-${testCase}";
in stdenv.mkDerivation {
  inherit name;

  src = opensbi-common-build;

  buildInputs = [
    python3
    riscv64-cc
  ];

  makeFlags = [
    "CROSS_COMPILE=riscv64-unknown-linux-gnu-"
    "PLATFORM=generic"
    "FW_FDT_PATH=${dts}/xiangshan.dtb"
    "FW_PAYLOAD_PATH=${linux}/arch/riscv/boot/Image.${testCase}"
  ];
  buildPhase = ''
    patchShebangs .

    # Default FW_PAYLOAD memory layout:
    # Refers to https://github.com/riscv-software-src/opensbi/blob/master/platform/generic/objects.mk
    #   ┌───────────────────┬──────────────────────────┬─────┐
    #   │  opensbi firmware │ payload e.g. linux Image │ FDT │
    #   └───────────────────┴──────────────────────────┴─────┘
    #   │                   │                          │
    #   ├─FW_PAYLOAD_OFFSET─┘                          │
    #   │ (default:0x200000=2MB)                       │
    #   │                                              │
    #   └─────────────FW_PAYLOAD_FDT_OFFSET────────────┘
    #             (default:0x2200000=2MB+32MB)
    # Noted: In 64bit system, the FW_PAYLOAD_OFFSET and FW_PAYLOAD_FDT_OFFSET must be aligned to 2MB.

    # Calculate the FW_PAYLOAD_FDT_OFFSET
    ALIGN=0x200000
    FW_PAYLOAD_OFFSET=0x200000
    IMAGE_SIZE=$(ls -l ${linux}/arch/riscv/boot/Image.${testCase} | awk '{print $5}')
    IMAGE_END=$((FW_PAYLOAD_OFFSET + IMAGE_SIZE))
    IMAGE_END_ALIGNED=$(( (IMAGE_END + ALIGN-1) & ~(ALIGN-1) ))
    IMAGE_END_ALIGNED_HEX=$(printf "0x%x" $IMAGE_END_ALIGNED)
    echo FW_PAYLOAD_FDT_OFFSET=$IMAGE_END_ALIGNED_HEX

    make -j $NIX_BUILD_CORES $makeFlags \
      FW_PAYLOAD_OFFSET=$FW_PAYLOAD_OFFSET \
      FW_PAYLOAD_FDT_OFFSET=$IMAGE_END_ALIGNED_HEX
  '';

  installPhase = ''
    mkdir -p $out
    mv build/platform/generic/firmware/fw_payload.bin $out/fw_payload.${testCase}.bin
  '';
}
