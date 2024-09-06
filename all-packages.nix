{ pkgs }:
rec {
  riscv64-cc = pkgs.pkgsCross.riscv64.stdenv.cc;
  riscv64-libc-static = pkgs.pkgsCross.riscv64.stdenv.cc.libc.static;

  before_workload = pkgs.callPackage ./linux/initramfs/overlays/before_workload {
    inherit riscv64-cc riscv64-libc-static;
  };
  busybox = pkgs.callPackage ./linux/initramfs/overlays/busybox {
    inherit riscv64-cc riscv64-libc-static;
  };
  qemu_trap = pkgs.callPackage ./linux/initramfs/overlays/qemu_trap {
    inherit riscv64-cc riscv64-libc-static;
  };
  initramfs_overlays = pkgs.callPackage ./linux/initramfs/overlays {
    inherit before_workload busybox qemu_trap;
  };
  gen_init_cpio = pkgs.callPackage ./linux/initramfs/base/gen_init_cpio {};
  initramfs_base = pkgs.callPackage ./linux/initramfs/base {
    inherit gen_init_cpio;
  };
}
