{ runCommand
, lib

, dconfig
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
    "-plugin ${qemu}/lib/libprofiling.so,workload=${dconfig.workload},intervals=${toString dconfig.intervals},target=$out"
    "-icount shift=0,align=off,sleep=off"
  ];

  nemuCommand = [
    "${nemu}/bin/riscv64-nemu-interpreter"
    "${gcpt}"
    "-b"
    "-D $out"
    "-C ${name}"
    "-w ${dconfig.workload}"
    "--simpoint-profile"
    "--cpt-interval ${toString dconfig.intervals}"
  ];

in runCommand name {} ''
  mkdir -p $out

  ${if dconfig.simulator == "qemu" then ''
    echo ${builtins.toString qemuCommand}
    ${builtins.toString qemuCommand} | tee $out/${dconfig.profiling_log}
  '' else ''
    echo ${builtins.toString nemuCommand}
    ${builtins.toString nemuCommand} | tee $out/${dconfig.profiling_log}
    cp $out/${name}/${dconfig.workload}/simpoint_bbv.gz $out/
  ''}
''
