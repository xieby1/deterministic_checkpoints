{ runCommand

, testCase
, simpoint
, stage1-profiling
}:
let
  name = "2.cluster-${testCase}";
in runCommand name {} (''
  mkdir -p $out
'' + (builtins.toString [
  "${simpoint}/bin/simpoint"
  "-loadFVFile ${stage1-profiling}/simpoint_bbv.gz"
  "-saveSimpoints $out/simpoints0"
  "-saveSimpointWeights $out/weights0"
  "-inputVectorsGzipped"
  # TODO xalancbmk=100 else 30
  "-maxK 5"
  "-numInitSeeds 2"
  "-iters 1000"
  "-seedkm 610829"
  "-seedproj 829610"
]))
