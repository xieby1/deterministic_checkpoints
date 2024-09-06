{ runCommand

, testCase
, qemu
, opensbi-bin
, stage2-cluster
}:
let
  name = "3.checkpoint-${testCase}";
in runCommand name {} (''
  mkdir -p $out
'' + (builtins.toString [
  "${qemu}/bin/qemu-system-riscv64"
  "-bios"
  "${opensbi-bin}/fw_payload.${testCase}.bin"
  "-M"
  "nemu,simpoint-path=${stage2-cluster},workload=.,cpt-interval=20000000,output-base-dir=$out,config-name=miao,checkpoint-mode=SimpointCheckpoint"
  "-nographic"
  "-m 8G"
  "-smp 1"
  "-cpu rv64,v=true,vlen=128,h=false,sv39=true,sv48=false,sv57=false,sv64=false"
  "-icount shift=0,align=off,sleep=off"
]))
