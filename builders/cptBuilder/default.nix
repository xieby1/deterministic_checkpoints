{ callPackage

, imgBuilder
, ...
}@args: let
  # TODO: move folders to cptBuilder/
  qemu = callPackage ./qemu {};
  nemu = callPackage ./nemu {};
  gcpt = imgBuilder.gcpt;
  stage1-profiling = callPackage ./1.profiling.nix {
    inherit qemu nemu gcpt;
  };
  simpoint = callPackage ./simpoint {};
  stage2-cluster = callPackage ./2.cluster.nix ({
    inherit simpoint stage1-profiling;
  } // args);
  stage3-checkpoint = callPackage ./3.checkpoint.nix {
    inherit qemu nemu gcpt stage2-cluster;
  };
in stage3-checkpoint.overrideAttrs (old: {
  passthru = {
    inherit qemu nemu simpoint;
    inherit stage1-profiling stage2-cluster stage3-checkpoint;
  };
})
