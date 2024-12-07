{ stage3-checkpoint }: let
  stage2-cluster = stage3-checkpoint.stage2-cluster;
  stage1-profiling = stage2-cluster.stage1-profiling;
in stage3-checkpoint.overrideAttrs (old: {
  passthru = {
    inherit stage1-profiling stage2-cluster stage3-checkpoint;
    qemu = stage1-profiling.qemu;
    nemu = stage1-profiling.nemu;
    simpoint = stage2-cluster.simpoint;
  };
})
