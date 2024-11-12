{ pkgs
, benchmark
}: let
  riscv64-cc = pkgs.pkgsCross.riscv64.stdenv.cc;
  riscv64-libc-static = pkgs.pkgsCross.riscv64.stdenv.cc.libc.static;
  riscv64-busybox = pkgs.pkgsCross.riscv64.busybox.override {
    enableStatic = true;
    useMusl = true;
  };

  # TODO: move folders to imgBuilder/
  linux-common-build = pkgs.callPackage ./linux/common-build.nix {
    inherit riscv64-cc;
  };
  linux-image = pkgs.callPackage ./linux {
    inherit linux-common-build;
    inherit riscv64-cc riscv64-libc-static riscv64-busybox;
    inherit benchmark;
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
    inherit linux-common-build linux-image;
    inherit dts opensbi-common-build opensbi-bin;
  };
})
