{ pkgs
, benchmark
}: let
  riscv64-cc = pkgs.pkgsCross.riscv64.stdenv.cc;
  riscv64-libc-static = pkgs.pkgsCross.riscv64.stdenv.cc.libc.static;

  # TODO: move folders to imgBuilder/
  before_workload = pkgs.callPackage ./linux/initramfs/overlays/before_workload {
    inherit riscv64-cc riscv64-libc-static;
  };
  busybox = pkgs.pkgsCross.riscv64.busybox.override {
    enableStatic = true;
    useMusl = true;
  };
  qemu_trap = pkgs.callPackage ./linux/initramfs/overlays/qemu_trap {
    inherit riscv64-cc riscv64-libc-static;
  };
  nemu_trap = pkgs.callPackage ./linux/initramfs/overlays/nemu_trap {
    inherit riscv64-cc riscv64-libc-static;
  };  
  initramfs_overlays = pkgs.callPackage ./linux/initramfs/overlays {
    inherit before_workload busybox qemu_trap nemu_trap;
  };
  gen_init_cpio = pkgs.callPackage ./linux/initramfs/base/gen_init_cpio {};
  initramfs_base = pkgs.callPackage ./linux/initramfs/base {
    inherit gen_init_cpio;
  };
  cpio = pkgs.cpio.overrideAttrs (old: {
    patches = [./linux/initramfs/cpio_reset_timestamp.patch];
  });
  initramfs = pkgs.callPackage ./linux/initramfs {
    inherit cpio initramfs_base initramfs_overlays benchmark;
  };
  linux-common-build = pkgs.callPackage ./linux/common-build.nix {
    inherit riscv64-cc;
  };
  linux-image = pkgs.callPackage ./linux {
    inherit riscv64-cc initramfs linux-common-build;
  };
  dts = pkgs.callPackage ./opensbi/dts {};
  opensbi-common-build = pkgs.callPackage ./opensbi/common-build.nix {
    inherit riscv64-cc dts;
  };
  opensbi-bin = pkgs.callPackage ./opensbi {
    inherit riscv64-cc dts opensbi-common-build linux-image;
  };
  gcpt-bin = pkgs.callPackage ./gcpt {
    inherit riscv64-cc opensbi-bin;
  };
in gcpt-bin.overrideAttrs (old: {
  passthru = {
    inherit riscv64-cc riscv64-libc-static;
    inherit before_workload busybox qemu_trap nemu_trap;
    inherit initramfs_overlays gen_init_cpio cpio initramfs;
    inherit linux-common-build linux-image;
    inherit dts opensbi-common-build opensbi-bin;
  };
})
