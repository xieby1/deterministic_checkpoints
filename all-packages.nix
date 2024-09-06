{ pkgs }:
rec {
  riscv64-cc = pkgs.pkgsCross.riscv64.stdenv.cc;
  riscv64-libc-static = pkgs.pkgsCross.riscv64.stdenv.cc.libc.static;
  riscv64-fortran = let
    pkgs2311 = import (fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/tarball/release-23.11";
      sha256 = "sha256:1f5d2g1p6nfwycpmrnnmc2xmcszp804adp16knjvdkj8nz36y1fg";
    }) {};
  # TODO: Why pkgs 24.05 gfortran does not work, but 23.11 works?
  in pkgs2311.pkgsCross.riscv64.wrapCCWith {
    cc = pkgs.pkgsCross.riscv64.stdenv.cc.cc.override {
      name = "gfortran";
      langFortran = true;
      langCC = false;
      langC = false;
      profiledCompiler = false;
    };
    # fixup wrapped prefix, which only appear if hostPlatform!=targetPlatform
    #   for more details see <nixpkgs>/pkgs/build-support/cc-wrapper/default.nix
    stdenvNoCC = pkgs.pkgsCross.riscv64.stdenvNoCC.override {
      hostPlatform = pkgs.stdenv.hostPlatform;
    };
  };
  riscv64-jemalloc = pkgs.pkgsCross.riscv64.jemalloc;

  spec2006 = pkgs.callPackage ./spec2006 {
    inherit riscv64-cc riscv64-fortran riscv64-libc-static;
    inherit riscv64-jemalloc;
  };

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
  initramfs = pkgs.callPackage ./linux/initramfs {
    inherit initramfs_base initramfs_overlays spec2006;
  };
}
