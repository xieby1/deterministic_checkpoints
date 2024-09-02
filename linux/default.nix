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
    # based on https://github.com/OpenXiangShan/riscv-rootfs/blob/checkpoint/rootfsimg/initramfs-spec.txt
    initramfs_txt = let
      busybox = import ./initramfs/busybox;
      inittab = pkgs.writeText "inittab" ''
        ::sysinit:/bin/busybox --install -s
        /dev/console::sysinit:-/bin/sh /run/run.sh
      '';
      before_workload = import ./initramfs/before_workload;
      qemu_trap = import ./initramfs/qemu_trap;
      spec2006 = import ../spec2006;
      run_sh = pkgs.writeText "run.sh" ''
        before_workload
        echo start
        cd /run
        for f in 166 200 c-typeck cp-decl expr expr2 g23 s04 scilab; do
          echo $f: running...
          ./403.gcc $f.i -o $f.s
          echo $f: finished
        done
        echo exit
        qemu_trap
      '';
    in pkgs.writeText "initramfs.txt" ''
      dir /bin 755 0 0
      dir /etc 755 0 0
      dir /dev 755 0 0
      dir /lib 755 0 0
      dir /proc 755 0 0
      dir /sbin 755 0 0
      dir /sys 755 0 0
      dir /tmp 755 0 0
      dir /usr 755 0 0
      dir /mnt 755 0 0
      dir /usr/bin 755 0 0
      dir /usr/lib 755 0 0
      dir /usr/sbin 755 0 0
      dir /var 755 0 0
      dir /var/tmp 755 0 0
      dir /root 755 0 0
      dir /var/log 755 0 0

      nod /dev/console 644 0 0 c 5 1
      nod /dev/null 644 0 0 c 1 3

      # busybox
      file /bin/busybox ${busybox}/bin/busybox 755 0 0
      file /etc/inittab ${inittab} 755 0 0
      slink /init /bin/busybox 755 0 0

      # traps
      file /bin/before_workload ${before_workload}/bin/before_workload 755 0 0
      file /bin/qemu_trap ${qemu_trap}/bin/qemu_trap 755 0 0

      dir  /run 755 0 0
      file /run/run.sh     ${run_sh} 644 0 0
      file /run/403.gcc    ${spec2006}/403.gcc/build/403.gcc             755 0 0
      file /run/166.i      ${spec2006}/403.gcc/data/ref/input/166.i      644 0 0
      file /run/200.i      ${spec2006}/403.gcc/data/ref/input/200.i      644 0 0
      file /run/c-typeck.i ${spec2006}/403.gcc/data/ref/input/c-typeck.i 644 0 0
      file /run/cp-decl.i  ${spec2006}/403.gcc/data/ref/input/cp-decl.i  644 0 0
      file /run/expr.i     ${spec2006}/403.gcc/data/ref/input/expr.i     644 0 0
      file /run/expr2.i    ${spec2006}/403.gcc/data/ref/input/expr2.i    644 0 0
      file /run/g23.i      ${spec2006}/403.gcc/data/ref/input/g23.i      644 0 0
      file /run/s04.i      ${spec2006}/403.gcc/data/ref/input/s04.i      644 0 0
      file /run/scilab.i   ${spec2006}/403.gcc/data/ref/input/scilab.i   644 0 0
    '';
    # based on https://github.com/OpenXiangShan/nemu_board/raw/37dc20e77a9bbff54dc2e525dc6c0baa3d50f948/configs/xiangshan_defconfig
    xiangshan_defconfig = pkgs.writeText "xiangshan_defconfig" ''
      CONFIG_DEFAULT_HOSTNAME="(lvna)"
      # CONFIG_CROSS_MEMORY_ATTACH is not set
      CONFIG_LOG_BUF_SHIFT=15
      CONFIG_BLK_DEV_INITRD=y
      CONFIG_INITRAMFS_SOURCE="${initramfs_txt}"
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
