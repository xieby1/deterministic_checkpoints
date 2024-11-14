{ stdenv
, callPackage
, bc
, flex
, bison

, riscv64-cc
, riscv64-libc-static
, riscv64-busybox
, benchmark
}: let
  initramfs = callPackage ./initramfs {
    inherit riscv64-cc riscv64-libc-static riscv64-busybox;
    inherit benchmark;
  };
  # TODO: use overlayfs to reduce disk usage
  common-build = callPackage ./common-build.nix {inherit riscv64-cc;};
in stdenv.mkDerivation {
  name = "${benchmark.name}.linux";
  src = common-build;
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

    # Prepare benchmark config
    TESTCASE_DEFCONFIG=arch/riscv/configs/xiangshan_benchmark_defconfig
    cat arch/riscv/configs/xiangshan_defconfig > $TESTCASE_DEFCONFIG
    echo CONFIG_INITRAMFS_SOURCE=\"${initramfs}\" >> $TESTCASE_DEFCONFIG

    export KBUILD_BUILD_TIMESTAMP=@0
    make xiangshan_benchmark_defconfig
    make -j $NIX_BUILD_CORES
  '';
  installPhase = ''
    cp arch/riscv/boot/Image $out
  '';
}
