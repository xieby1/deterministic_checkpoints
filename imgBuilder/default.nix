{ pkgs
, benchmark
}: let
  riscv64-cc = pkgs.pkgsCross.riscv64.stdenv.cc;
  riscv64-libc-static = pkgs.pkgsCross.riscv64.stdenv.cc.libc.static;

  # TODO: move folders to imgBuilder/
  nemu_trap = pkgs.callPackage ./linux/initramfs/overlays/nemu_trap {
    inherit riscv64-cc riscv64-libc-static;
  };  
  initramfs_overlays = pkgs.callPackage ./linux/initramfs/overlays {
    inherit nemu_trap;
    inherit riscv64-cc riscv64-libc-static;
    riscv64-busybox = pkgs.pkgsCross.riscv64.busybox.override {
      enableStatic = true;
      useMusl = true;
    };
  };
  initramfs = pkgs.callPackage ./linux/initramfs {
    inherit initramfs_overlays benchmark;
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
    inherit nemu_trap;
    inherit initramfs_overlays initramfs;
    inherit linux-common-build linux-image;
    inherit dts opensbi-common-build opensbi-bin;
  };
})
