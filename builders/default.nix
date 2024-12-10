{ lib
, callPackage
}:
# TODO: remove with self
{ benchmark }: lib.makeScope lib.callPackageWith (self: with self; {
  inherit benchmark;
  gen_init_cpio = callPackage ./imgBuilder/linux/initramfs/base/gen_init_cpio {};
  initramfs_base = callPackage ./imgBuilder/linux/initramfs/base {
    inherit gen_init_cpio;
  };

  before_workload = callPackage ./imgBuilder/linux/initramfs/overlays/before_workload {};
  nemu_trap = callPackage ./imgBuilder/linux/initramfs/overlays/nemu_trap {};
  qemu_trap = callPackage ./imgBuilder/linux/initramfs/overlays/qemu_trap {};
  initramfs_overlays = callPackage ./imgBuilder/linux/initramfs/overlays {
    inherit before_workload qemu_trap nemu_trap;
    benchmark-run = self.benchmark.run;
  };

  initramfs = callPackage ./imgBuilder/linux/initramfs {
    inherit (self) benchmark;
    base = initramfs_base;
    overlays = initramfs_overlays;
  };

  linux-common-build = callPackage ./imgBuilder/linux/common-build.nix {};
  linux = callPackage ./imgBuilder/linux {
    inherit initramfs;
    common-build = linux-common-build;
  };

  dts = callPackage ./imgBuilder/opensbi/dts {};
  opensbi-common-build = callPackage ./imgBuilder/opensbi/common-build.nix {
    inherit dts;
  };
  opensbi = callPackage ./imgBuilder/opensbi {
    inherit dts linux;
    common-build = opensbi-common-build;
  };
  gcpt = callPackage ./imgBuilder/gcpt {
    inherit opensbi;
  };
  img = callPackage ./imgBuilder {
    inherit gcpt;
  };

  nemu = callPackage ./cptBuilder/nemu {};
  qemu = callPackage ./cptBuilder/qemu {};
  simpoint = callPackage ./cptBuilder/simpoint {};
  stage1-profiling = callPackage ./cptBuilder/1.profiling.nix {
    inherit qemu nemu img;
  };
  stage2-cluster = callPackage ./cptBuilder/2.cluster.nix {
    inherit simpoint stage1-profiling;
  };
  stage3-checkpoint = callPackage ./cptBuilder/3.checkpoint.nix {
    inherit qemu nemu img stage2-cluster;
  };
  cpt = callPackage ./cptBuilder {
    inherit stage3-checkpoint;
  };
})
