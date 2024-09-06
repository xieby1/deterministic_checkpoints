{ stdenv
, bc
, flex
, bison

, testCase ? "403.gcc"
, riscv64-cc
, initramfs
}:
let
  name = "linux-${testCase}";
in stdenv.mkDerivation {
  inherit name;
  src = import ./common-build.nix;
  buildInputs = [
    bc
    flex
    bison
    riscv64-cc
  ];

  buildPhase = ''
    export ARCH=riscv
    export RISCV_ROOTFS_HOME=$(realpath ../riscv-rootfs/)
    export CROSS_COMPILE=riscv64-unknown-linux-gnu-

    # Prepare testCase config
    TESTCASE_DEFCONFIG=arch/riscv/configs/xiangshan_${testCase}_defconfig
    cat arch/riscv/configs/xiangshan_defconfig > $TESTCASE_DEFCONFIG
    echo CONFIG_INITRAMFS_SOURCE=\"${initramfs}/${testCase}.cpio\" >> $TESTCASE_DEFCONFIG

    make xiangshan_${testCase}_defconfig
    make -j $NIX_BUILD_CORES
    mv arch/riscv/boot/Image arch/riscv/boot/Image.${testCase}
  '';
  installPhase = ''
    mkdir -p $out/arch/riscv/boot/
    cp arch/riscv/boot/Image.${testCase} $out/arch/riscv/boot/
  '';
}
