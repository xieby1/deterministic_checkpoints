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

  # 修改生成文件的权限444改为644, nemu fstream读取默认需要写权限
  chmod +w $out/simpoints0 $out/weights0
'')
