{ runCommand

, testCase
, qemu
, gcpt-bin
}:
let
  name = "1.profiling-${testCase}";
in runCommand name {} (''
  mkdir -p $out
'' + (builtins.toString [
  "${qemu}/bin/qemu-system-riscv64"
  "-bios ${gcpt-bin}/gcpt.${testCase}.bin"
  "-M nemu"
  "-nographic"
  "-m 8G"
  "-smp 1"
  "-cpu rv64,v=true,vlen=128,h=false,sv39=true,sv48=false,sv57=false,sv64=false"
  "-plugin ${qemu}/lib/libprofiling.so,workload=miao,intervals=20000000,target=$out"
  "-icount shift=0,align=off,sleep=off"
]))
