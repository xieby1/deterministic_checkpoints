{ pkgs ? import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/e8c38b73aeb218e27163376a2d617e61a2ad9b59.tar.gz";
    sha256 = "1n6gdjny8k5rwkxh6sp1iwg1y3ni1pm7lvh9sisifgjb18jdvzbm";
  }) {}
  , ...
} @ args:
# TODO: support overlay
rec {
  riscv64-pkgs = pkgs.pkgsCross.riscv64;
  # TODO: gcc14 have a bug to compile spec2006 & spec2017's xalan
  #   * https://github.com/llvm/llvm-project/issues/109966
  #   * https://gcc.gnu.org/bugzilla/show_bug.cgi?id=116064
  riscv64-stdenv = riscv64-pkgs.gcc13Stdenv;
  riscv64-cc = riscv64-stdenv.cc;
  riscv64-libc-static = riscv64-stdenv.cc.libc.static;
  riscv64-fortran = riscv64-pkgs.wrapCCWith {
    cc = riscv64-stdenv.cc.cc.override {
      name = "gfortran";
      langFortran = true;
      langCC = false;
      langC = false;
      profiledCompiler = false;
    };
    # fixup wrapped prefix, which only appear if hostPlatform!=targetPlatform
    #   for more details see <nixpkgs>/pkgs/build-support/cc-wrapper/default.nix
    stdenvNoCC = riscv64-pkgs.stdenvNoCC.override {
      hostPlatform = pkgs.stdenv.hostPlatform;
    };
    # Beginning from 24.05, wrapCCWith receive `runtimeShell`.
    # If leave it empty, the default uses riscv64-pkgs.runtimeShell,
    # thus executing the sheBang will throw error:
    #   `cannot execute: required file not found`.
    runtimeShell = pkgs.runtimeShell;
  };
  scope = pkgs.lib.makeScope pkgs.newScope (self: {
    inherit riscv64-pkgs riscv64-stdenv riscv64-cc riscv64-libc-static riscv64-fortran;
  });

  spec2006-build-all = scope.callPackage ./benchmarks/spec2006/build-all.nix {
    src = if args ? spec2006-src
      then args.spec2006-src
      else throw ''
        Please specify the path of spec2006, for example:
          nix-build ... --arg spec2006-src /path/of/spec2006.tar.gz ...
      '';
  };
  spec2006 = scope.callPackage ./benchmarks/spec2006 {
    build-all = spec2006-build-all;
  };

  openblas = scope.callPackage ./benchmarks/openblas {};

  gen_init_cpio = scope.callPackage ./builders/imgBuilder/linux/initramfs/base/gen_init_cpio {};
  initramfs_base = scope.callPackage ./builders/imgBuilder/linux/initramfs/base {
    inherit gen_init_cpio;
  };

  before_workload = scope.callPackage ./builders/imgBuilder/linux/initramfs/overlays/before_workload {};
  nemu_trap = scope.callPackage ./builders/imgBuilder/linux/initramfs/overlays/nemu_trap {};
  qemu_trap = scope.callPackage ./builders/imgBuilder/linux/initramfs/overlays/qemu_trap {};
  build-initramfs_overlays = benchmark-run: scope.callPackage ./builders/imgBuilder/linux/initramfs/overlays {
    inherit before_workload qemu_trap nemu_trap benchmark-run;
  };

  build-initramfs = benchmark: scope.callPackage ./builders/imgBuilder/linux/initramfs {
    inherit benchmark;
    base = initramfs_base;
    overlays = build-initramfs_overlays benchmark.run;
  };

  linux-common-build = scope.callPackage ./builders/imgBuilder/linux/common-build.nix {};
  build-linux = benchmark: scope.callPackage ./builders/imgBuilder/linux {
    inherit benchmark;
    initramfs = build-initramfs benchmark;
    common-build = linux-common-build;
  };

  dts = scope.callPackage ./builders/imgBuilder/opensbi/dts {};
  opensbi-common-build = scope.callPackage ./builders/imgBuilder/opensbi/common-build.nix {
    inherit dts;
  };
  build-opensbi = benchmark: scope.callPackage ./builders/imgBuilder/opensbi {
    inherit benchmark dts;
    linux = build-linux benchmark;
    common-build = opensbi-common-build;
  };
  build-gcpt = benchmark: scope.callPackage ./builders/imgBuilder/gcpt {
    inherit benchmark;
    opensbi = build-opensbi benchmark;
  };
  build-img = benchmark: scope.callPackage ./builders/imgBuilder {
    gcpt = build-gcpt benchmark;
  };

  nemu = scope.callPackage ./builders/cptBuilder/nemu {};
  qemu = scope.callPackage ./builders/cptBuilder/qemu {};
  simpoint = scope.callPackage ./builders/cptBuilder/simpoint {};
  build-stage1-profiling = benchmark: scope.callPackage ./builders/cptBuilder/1.profiling.nix {
    inherit qemu nemu;
    img = build-img benchmark;
  };
  build-stage2-cluster = benchmark: scope.callPackage ./builders/cptBuilder/2.cluster.nix {
    inherit simpoint;
    stage1-profiling = build-stage1-profiling benchmark;
  };
  build-stage3-checkpoint = benchmark: scope.callPackage ./builders/cptBuilder/3.checkpoint.nix {
    inherit qemu nemu;
    img = build-img benchmark;
    stage2-cluster = build-stage2-cluster benchmark;
  };
  build-cpt = benchmark: scope.callPackage ./builders/cptBuilder {
    inherit benchmark build-stage3-checkpoint;
  };


  # TODO: 483_xalancbmk maxK="100"
  cpt-spec2006 = let
    attrs = builtins.mapAttrs (name: benchmark:
      build-cpt benchmark
    ) (pkgs.lib.filterAttrs (n: v: (pkgs.lib.isDerivation v)) spec2006);
  in (pkgs.linkFarm "checkpoints" (
    pkgs.lib.mapAttrsToList ( name: path: {inherit name path; } ) attrs
  )).overrideAttrs (old: { passthru = attrs; });

  cpt-openblas = build-cpt openblas;
}
