{ pkgs
, gcpt-bin
}: let
  riscv64-cc = pkgs.pkgsCross.riscv64.stdenv.cc;
  # TODO: move folders to cptBuilder/
  qemu = pkgs.callPackage ./qemu {};
  nemu = pkgs.callPackage ./nemu {inherit riscv64-cc;};
  stage1-profiling = pkgs.callPackage ./1.profiling.nix {
    inherit qemu nemu gcpt-bin;
  };
  simpoint = pkgs.callPackage ./simpoint {};
  stage2-cluster = pkgs.callPackage ./2.cluster.nix {
    inherit simpoint stage1-profiling;
  };
  stage3-checkpoint = pkgs.callPackage ./3.checkpoint.nix {
    inherit qemu nemu gcpt-bin stage2-cluster;
  };
in stage3-checkpoint.overrideAttrs (old: {
  passthru = {
    inherit riscv64-cc qemu nemu simpoint;
    inherit stage1-profiling stage2-cluster stage3-checkpoint;
  };
})
