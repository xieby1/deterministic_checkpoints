{ runCommand
, lib

, config
, qemu
, nemu
, gcpt
}:
let
  name = "${lib.removeSuffix ".gcpt" gcpt.name}.1_profiling";

  qemuCommand = [
    "${qemu}/bin/qemu-system-riscv64"
    "-bios ${gcpt}"
    "-M nemu"
    "-nographic"
    "-m 8G"
    "-smp 1"
    "-cpu rv64,v=true,vlen=128,h=false,sv39=true,sv48=false,sv57=false,sv64=false"
    "-plugin ${qemu}/lib/libprofiling.so,workload=${config.workload},intervals=${toString config.intervals},target=$out"
    "-icount shift=0,align=off,sleep=off"
  ];

  nemuCommand = [
    "${nemu}/bin/riscv64-nemu-interpreter"
    "${gcpt}"
    "-b"
    "-D $out"
    "-C ${name}"
    "-w ${config.workload}"
    "--simpoint-profile"
    "--cpt-interval ${toString config.intervals}"
  ];

in runCommand name {} ''
  mkdir -p $out

  ${if config.simulator == "qemu" then ''
    echo ${builtins.toString qemuCommand}
    ${builtins.toString qemuCommand} | tee $out/${config.profiling_log}
  '' else ''
    echo ${builtins.toString nemuCommand}
    ${builtins.toString nemuCommand} | tee $out/${config.profiling_log}
    cp $out/${name}/${config.workload}/simpoint_bbv.gz $out/
  ''}
''
