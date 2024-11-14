{ pkgs,
benchmark
}: let
  # TODO: rename gcpt-bin => gcpt
  gcpt-bin = import ./imgBuilder { inherit pkgs benchmark; };
  checkpoints = import ./cptBuilder { inherit pkgs gcpt-bin; };
in checkpoints
