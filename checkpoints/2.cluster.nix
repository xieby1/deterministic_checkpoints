{ runCommand

, testCase
, simpoint
, stage1-profiling
}:
let
  name = "2.cluster-${testCase}";
  maxK = if testCase == "483.xalancbmk" then "100" else "30";
in runCommand name {} (''
  mkdir -p $out
'' + (builtins.toString [
  "${simpoint}/bin/simpoint"
  "-loadFVFile ${stage1-profiling}/simpoint_bbv.gz"
  "-saveSimpoints $out/simpoints0"
  "-saveSimpointWeights $out/weights0"
  "-inputVectorsGzipped"
  "-maxK ${maxK}"
  "-numInitSeeds 2"
  "-iters 1000"
  "-seedkm 610829"
  "-seedproj 829610"
]) + ''

  # chmod from 444 to 644, nemu fstream need write permission
  chmod +w $out/simpoints0 $out/weights0
'')
