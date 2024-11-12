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
  gcpt-bin = pkgs.callPackage ./gcpt {
    inherit riscv64-cc riscv64-libc-static riscv64-busybox;
    inherit benchmark;
  };
in gcpt-bin.overrideAttrs (old: {
  passthru = {
    inherit riscv64-cc riscv64-libc-static;
  };
})
