{ callPackage

, benchmark
}: let
  gcpt = callPackage ./imgBuilder { inherit benchmark; };
  checkpoints = callPackage ./cptBuilder { inherit gcpt; };
in checkpoints
