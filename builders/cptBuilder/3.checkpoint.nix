{ runCommand
, lib

, dconfig
, qemu
, nemu
, gcpt
, stage2-cluster
}:
let
  qemuCommand = [
    "${qemu}/bin/qemu-system-riscv64"
    "-bios ${gcpt}"
    "-M nemu,simpoint-path=${stage2-cluster},workload=.,cpt-interval=${toString dconfig.intervals},output-base-dir=$out,config-name=${dconfig.workload},checkpoint-mode=SimpointCheckpoint"
    "-nographic"
    "-m 8G"
    "-smp 1"
    "-cpu rv64,v=true,vlen=128,h=false,sv39=true,sv48=false,sv57=false,sv64=false"
    "-icount shift=0,align=off,sleep=off"
  ];

  nemuCommand = [
    "${nemu}/bin/riscv64-nemu-interpreter"
    "${gcpt}"
    "-b"
    "-D $out"
    "-C checkpoint"
    "-w ."
    "-S ${stage2-cluster}"
    "--cpt-interval ${toString dconfig.intervals}"
    "--checkpoint-format ${toString dconfig.checkpoint_format}"
  ];

in runCommand "${lib.removeSuffix ".2_cluster" stage2-cluster.name}.3_checkpoint" {} ''
  mkdir -p $out

 ${if dconfig.simulator == "qemu" then ''
    echo "Executing QEMU command: ${builtins.toString qemuCommand}"
    ${builtins.toString qemuCommand} | tee $out/${dconfig.checkpoint_log}
  '' else ''
    echo "Executing NEMU command: ${builtins.toString nemuCommand}"
    ${builtins.toString nemuCommand} | tee $out/${dconfig.checkpoint_log}
  ''}
''
