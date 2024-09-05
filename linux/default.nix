# TODO: support all spec2006 test cases. Currently only support 403.gcc as an example.
let
  pname = "linux";
  # currently lastest stable linux version
  version = "6.10.7";
  pkgs = import <nixpkgs> {};
  initramfs = import ./initramfs;
in pkgs.stdenv.mkDerivation {
  inherit pname version;
  src = builtins.fetchurl {
    url = "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${version}.tar.xz";
    sha256 = "1adkbn6dqbpzlr3x87a18mhnygphmvx3ffscwa67090qy1zmc3ch";
  };
  buildInputs = [
    pkgs.bc
    pkgs.flex
    pkgs.bison
    pkgs.pkgsCross.riscv64.stdenv.cc
  ];

  patches = [
    # Shutdown QEMU when the kernel raises a panic.
    # This feature prevents the kernel from entering an endless loop,
    # allowing for quicker identification of failed SPEC CPU testCases.
    ./panic_shutdown.patch
  ];

  # TODO: add same gcc optimization cflags as benchmarks?
  # TODO: make create Image parallel
  buildPhase = let
    # based on https://github.com/OpenXiangShan/nemu_board/raw/37dc20e77a9bbff54dc2e525dc6c0baa3d50f948/configs/xiangshan_defconfig
    # TODO: seperate xiangshan_defconfig into an independent file
    xiangshan_defconfig = pkgs.writeText "xiangshan_defconfig" ''
      CONFIG_DEFAULT_HOSTNAME="(lvna)"
      CONFIG_LOG_BUF_SHIFT=15
      CONFIG_BLK_DEV_INITRD=y
      CONFIG_EXPERT=y
      CONFIG_NONPORTABLE=y
      CONFIG_SMP=y
      CONFIG_RISCV_SBI_V01=y
      CONFIG_SERIO_LIBPS2=y
      CONFIG_SERIAL_8250=y
      CONFIG_SERIAL_8250_CONSOLE=y
      CONFIG_SERIAL_8250_DW=y
      CONFIG_SERIAL_OF_PLATFORM=y
      CONFIG_SERIAL_EARLYCON_RISCV_SBI=y
      CONFIG_SERIAL_UARTLITE=y
      CONFIG_SERIAL_UARTLITE_CONSOLE=y
      CONFIG_HVC_RISCV_SBI=y
      CONFIG_PRINTK_TIME=y
      CONFIG_STACKTRACE=y
      CONFIG_RCU_CPU_STALL_TIMEOUT=300
    '';
  in ''
    export ARCH=riscv
    export RISCV_ROOTFS_HOME=$(realpath ../riscv-rootfs/)
    export CROSS_COMPILE=riscv64-unknown-linux-gnu-

    for CPIO in ${initramfs}/[0-9][0-9][0-9].*; do
      TESTCASE_NAME=''${CPIO##*/}
      TESTCASE_NAME=''${TESTCASE_NAME%.cpio}

      # Prepare xiangshan_defconfig for <TESTCASE_NAME>
      TESTCASE_DEFCONFIG=arch/riscv/configs/xiangshan_''${TESTCASE_NAME}_defconfig
      cat ${xiangshan_defconfig} > $TESTCASE_DEFCONFIG
      echo CONFIG_INITRAMFS_SOURCE=\"$CPIO\" >> $TESTCASE_DEFCONFIG

      echo create Linux Kernel Image for $TESTCASE_NAME
      make ''${TESTCASE_DEFCONFIG##*/}
      make -j $NIX_BUILD_CORES
      mv arch/riscv/boot/Image arch/riscv/boot/Image.$TESTCASE_NAME
      # Perform a minor cleanup to trigger the next make -j command for generating a new image.
      rm .config
    done
  '';
  installPhase = ''
    mkdir -p $out/arch/riscv/boot/
    cp arch/riscv/boot/Image.[0-9]* $out/arch/riscv/boot/
  '';
}
