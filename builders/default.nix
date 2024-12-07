{ riscv64-scope }:
{ benchmark
, overlays ? [] # TODO
}: let
  # TODO: callPackage = riscv64-scope.callPackage
  scope = riscv64-scope;
in rec {
  # TODO: inherit riscv64-scope benchmark;
  gen_init_cpio = scope.callPackage ./imgBuilder/linux/initramfs/base/gen_init_cpio {};
  initramfs_base = scope.callPackage ./imgBuilder/linux/initramfs/base {
    inherit gen_init_cpio;
  };

  before_workload = scope.callPackage ./imgBuilder/linux/initramfs/overlays/before_workload {};
  nemu_trap = scope.callPackage ./imgBuilder/linux/initramfs/overlays/nemu_trap {};
  qemu_trap = scope.callPackage ./imgBuilder/linux/initramfs/overlays/qemu_trap {};
  initramfs_overlays = scope.callPackage ./imgBuilder/linux/initramfs/overlays {
    inherit before_workload qemu_trap nemu_trap;
    benchmark-run = benchmark.run;
  };

  initramfs = scope.callPackage ./imgBuilder/linux/initramfs {
    inherit benchmark;
    base = initramfs_base;
    overlays = initramfs_overlays;
  };

  linux-common-build = scope.callPackage ./imgBuilder/linux/common-build.nix {};
  linux = scope.callPackage ./imgBuilder/linux {
    inherit benchmark initramfs;
    common-build = linux-common-build;
  };

  dts = scope.callPackage ./imgBuilder/opensbi/dts {};
  opensbi-common-build = scope.callPackage ./imgBuilder/opensbi/common-build.nix {
    inherit dts;
  };
  opensbi = scope.callPackage ./imgBuilder/opensbi {
    inherit benchmark dts linux;
    common-build = opensbi-common-build;
  };
  gcpt = scope.callPackage ./imgBuilder/gcpt {
    inherit benchmark opensbi;
  };
  img = scope.callPackage ./imgBuilder {
    inherit gcpt;
  };

  nemu = scope.callPackage ./cptBuilder/nemu {};
  qemu = scope.callPackage ./cptBuilder/qemu {};
  simpoint = scope.callPackage ./cptBuilder/simpoint {};
  stage1-profiling = scope.callPackage ./cptBuilder/1.profiling.nix {
    inherit qemu nemu img;
  };
  stage2-cluster = scope.callPackage ./cptBuilder/2.cluster.nix {
    inherit simpoint stage1-profiling;
  };
  stage3-checkpoint = scope.callPackage ./cptBuilder/3.checkpoint.nix {
    inherit qemu nemu img stage2-cluster;
  };
  cpt = scope.callPackage ./cptBuilder {
    inherit stage3-checkpoint;
  };

}
