# TODO: support all spec2006 test cases. Currently only support 403.gcc as an example.
let
  pname = "linux";
  # currently lastest stable linux version
  version = "6.10.7";
  pkgs = import <nixpkgs> {};
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
  # TODO: add same gcc optimization cflags as benchmarks?
  buildPhase = let
    initramfs = import ./initramfs;
    # based on https://github.com/OpenXiangShan/nemu_board/raw/37dc20e77a9bbff54dc2e525dc6c0baa3d50f948/configs/xiangshan_defconfig
    xiangshan_defconfig = pkgs.writeText "xiangshan_defconfig" ''
      CONFIG_DEFAULT_HOSTNAME="(lvna)"
      # CONFIG_CROSS_MEMORY_ATTACH is not set
      CONFIG_LOG_BUF_SHIFT=15
      CONFIG_BLK_DEV_INITRD=y
      CONFIG_INITRAMFS_SOURCE="${initramfs}/403.gcc.cpio"
      CONFIG_EXPERT=y
      # CONFIG_SYSFS_SYSCALL is not set
      # CONFIG_FHANDLE is not set
      # CONFIG_BASE_FULL is not set
      CONFIG_NONPORTABLE=y
      CONFIG_SMP=y
      CONFIG_RISCV_SBI_V01=y
      # CONFIG_BLOCK is not set
      # CONFIG_BINFMT_SCRIPT is not set
      # CONFIG_SLAB_MERGE_DEFAULT is not set
      # CONFIG_COMPAT_BRK is not set
      # CONFIG_COMPACTION is not set
      # CONFIG_VM_EVENT_COUNTERS is not set
      # CONFIG_STANDALONE is not set
      # CONFIG_PREVENT_FIRMWARE_BUILD is not set
      # CONFIG_FW_LOADER is not set
      # CONFIG_ALLOW_DEV_COREDUMP is not set
      # CONFIG_INPUT_KEYBOARD is not set
      # CONFIG_INPUT_MOUSE is not set
      CONFIG_SERIO_LIBPS2=y
      # CONFIG_VT_CONSOLE is not set
      # CONFIG_UNIX98_PTYS is not set
      # CONFIG_LEGACY_PTYS is not set
      CONFIG_SERIAL_8250=y
      CONFIG_SERIAL_8250_CONSOLE=y
      CONFIG_SERIAL_8250_DW=y
      CONFIG_SERIAL_OF_PLATFORM=y
      CONFIG_SERIAL_EARLYCON_RISCV_SBI=y
      CONFIG_SERIAL_UARTLITE=y
      CONFIG_SERIAL_UARTLITE_CONSOLE=y
      CONFIG_HVC_RISCV_SBI=y
      # CONFIG_HW_RANDOM is not set
      # CONFIG_DEVMEM is not set
      # CONFIG_HWMON is not set
      # CONFIG_USB_SUPPORT is not set
      # CONFIG_VIRTIO_MENU is not set
      # CONFIG_FILE_LOCKING is not set
      # CONFIG_DNOTIFY is not set
      # CONFIG_INOTIFY_USER is not set
      # CONFIG_PROC_FS is not set
      # CONFIG_SYSFS is not set
      # CONFIG_MISC_FILESYSTEMS is not set
      CONFIG_PRINTK_TIME=y
      CONFIG_STACKTRACE=y
      CONFIG_RCU_CPU_STALL_TIMEOUT=300
      # CONFIG_RCU_TRACE is not set
      # CONFIG_FTRACE is not set
      # CONFIG_RUNTIME_TESTING_MENU is not set
    '';
  in ''
    export ARCH=riscv
    export RISCV_ROOTFS_HOME=$(realpath ../riscv-rootfs/)
    export CROSS_COMPILE=riscv64-unknown-linux-gnu-
    ln -s ${xiangshan_defconfig} arch/riscv/configs/xiangshan_defconfig

    make xiangshan_defconfig
    make -j
  '';
  installPhase = ''
    mkdir -p $out/arch/riscv/boot/
    cp arch/riscv/boot/Image* $out/arch/riscv/boot/
  '';
}
