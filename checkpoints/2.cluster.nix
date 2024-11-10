{ runCommand
, lib

# TODO:
# maxK = if testCase == "483.xalancbmk" then "100" else "30";
, maxK ? "30"
, simpoint
, stage1-profiling
}: runCommand "${lib.removeSuffix ".1_profiling" stage1-profiling.name}.2_cluster" {} (''
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
