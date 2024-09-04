{
  testCase ? "403.gcc"
}:
let
  name = "2.cluster.nix-${testCase}";
  pkgs = import <nixpkgs> {};
  simpoint = import ../simpoint;
  stage1_profiling = import ./1.profiling.nix {inherit testCase;};
in pkgs.runCommand name {} (''
  mkdir -p $out
'' + (builtins.toString [
  "${simpoint}/bin/simpoint"
  "-loadFVFile ${stage1_profiling}/simpoint_bbv.gz"
  "-saveSimpoints $out/simpoints0"
  "-saveSimpointWeights $out/weights0"
  "-inputVectorsGzipped"
  "-maxK 5"
  "-numInitSeeds 2"
  "-iters 1000"
  "-seedkm 610829"
  "-seedproj 829610"
]))
