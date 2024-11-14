{ pkgs,
benchmark
}: let
  gcpt = import ./imgBuilder { inherit pkgs benchmark; };
  checkpoints = import ./cptBuilder { inherit pkgs gcpt; };
in checkpoints
