{ pkgs ? import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/tarball/release-23.11";
    sha256 = "sha256:1f5d2g1p6nfwycpmrnnmc2xmcszp804adp16knjvdkj8nz36y1fg";
  }) {}
}:
let
  testCases = [
    "400.perlbench"
    "401.bzip2"
    "403.gcc"
    "410.bwaves"
    "416.gamess"
    "429.mcf"
    "433.milc"
    "434.zeusmp"
    "435.gromacs"
    "436.cactusADM"
    "437.leslie3d"
    "444.namd"
    "445.gobmk"
    "447.dealII"
    "450.soplex"
    "453.povray"
    "454.calculix"
    "456.hmmer"
    "458.sjeng"
    "459.GemsFDTD"
    "462.libquantum"
    "464.h264ref"
    "465.tonto"
    "470.lbm"
    "471.omnetpp"
    "473.astar"
    "481.wrf"
    "482.sphinx3"
    "483.xalancbmk"
  ];
  lib-customized = pkgs.callPackage ./lib-customized.nix {};
in rec {
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
    inherit cpio initramfs_base initramfs_overlays spec2006;
  };
  linux-common-build = pkgs.callPackage ./linux/common-build.nix {
    inherit riscv64-cc;
  };
  linux-images = let
    linux-images-list = builtins.map (testCase: (
      pkgs.callPackage ./linux {
        inherit testCase riscv64-cc initramfs linux-common-build;
      }
    )) testCases;
  in pkgs.symlinkJoin {
    name = "linux-images";
    paths = linux-images-list;
    passthru = builtins.listToAttrs (
      pkgs.lib.zipListsWith (
        name: value: {inherit name value;}
      ) testCases linux-images-list
    );
  };
  dts = pkgs.callPackage ./opensbi/dts {};
  opensbi-common-build = pkgs.callPackage ./opensbi/common-build.nix {
    inherit riscv64-cc dts;
  };
  opensbi-bins = let
    opensbi-bins-list = builtins.map (testCase: (
      pkgs.callPackage ./opensbi {
        inherit testCase riscv64-cc dts opensbi-common-build;
        linux-image = builtins.getAttr testCase linux-images;
      }
    )) testCases;
  in pkgs.symlinkJoin {
    name = "opensbi-bins";
    paths = opensbi-bins-list;
    passthru = builtins.listToAttrs (
      pkgs.lib.zipListsWith (
        name: value: {inherit name value;}
      ) testCases opensbi-bins-list
    );
  };

  gcpt-bins = let
    gcpt-bins-list = builtins.map (testCase: (
      pkgs.callPackage ./gcpt {
        inherit testCase riscv64-cc;
        opensbi-bin = builtins.getAttr testCase opensbi-bins;
      }
    )) testCases;
  in pkgs.symlinkJoin {
    name = "gcpt-bins";
    paths = gcpt-bins-list;
    passthru = builtins.listToAttrs (
      pkgs.lib.zipListsWith (
        name: value: {inherit name value;}
      ) testCases gcpt-bins-list
    );
  };

  qemu = pkgs.callPackage ./qemu {};

  nemu = pkgs.callPackage ./nemu {inherit riscv64-cc;};

  stage1-profilings = let
    stage1-profilings-list = builtins.map (testCase: (
      pkgs.callPackage ./checkpoints/1.profiling.nix {
        inherit testCase qemu nemu;
        gcpt-bin = builtins.getAttr testCase gcpt-bins;
      }
    )) testCases;
  in lib-customized.linkFarmNoEntries "1.profilings" (
    pkgs.lib.zipListsWith (
      name: path: {inherit name path;}
    ) testCases stage1-profilings-list
  );

  simpoint = pkgs.callPackage ./simpoint {};
  stage2-clusters = let
    stage2-clusters-list = builtins.map (testCase: (
      pkgs.callPackage ./checkpoints/2.cluster.nix {
        inherit testCase simpoint;
        stage1-profiling = builtins.getAttr testCase stage1-profilings;
      }
    )) testCases;
  in lib-customized.linkFarmNoEntries "2.clusters" (
    pkgs.lib.zipListsWith (
      name: path: {inherit name path;}
    ) testCases stage2-clusters-list
  );

  stage3-checkpoints = let
    stage3-checkpoints-list = builtins.map (testCase: (
      pkgs.callPackage ./checkpoints/3.checkpoint.nix {
        inherit testCase qemu nemu;
        gcpt-bin = builtins.getAttr testCase gcpt-bins;
        stage2-cluster = builtins.getAttr testCase stage2-clusters;
      }
    )) testCases;
  in lib-customized.linkFarmNoEntries "3.checkpoints" (
    pkgs.lib.zipListsWith (
      name: path: {inherit name path;}
    ) testCases stage3-checkpoints-list
  );
  checkpoints = stage3-checkpoints;
}
