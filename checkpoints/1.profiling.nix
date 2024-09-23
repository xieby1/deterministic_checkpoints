{ runCommand
, testCase
, qemu
, nemu
, gcpt-bin
}:
let
  name = "1.profiling-${testCase}";
  config = import ../config.nix;

  qemuCommand = [
    "${qemu}/bin/qemu-system-riscv64"
    "-bios ${gcpt-bin}/gcpt.${testCase}.bin"
    "-M nemu"
    "-nographic"
    "-m 8G"
    "-smp 1"
    "-cpu rv64,v=true,vlen=128,h=false,sv39=true,sv48=false,sv57=false,sv64=false"
    "-plugin ${qemu}/lib/libprofiling.so,workload=${config.workload},intervals=${toString config.intervals},target=$out"
    "-icount shift=0,align=off,sleep=off"
  ];

  nemuCommand = [
    "${nemu}/bin/nemu"
    "${gcpt-bin}/gcpt.${testCase}.bin"
    "-b"
    "-D $out"
    "-C ${testCase}"
    "-w ${config.workload}"
    "--simpoint-profile"
    "--cpt-interval ${toString config.intervals}"
  ];

in runCommand name {} ''
  mkdir -p $out

  ${if config.simulator == "qemu" then ''
    ${builtins.toString qemuCommand} | tee $out/${config.log_file}
  '' else ''
    ${builtins.toString nemuCommand} | tee $out/${config.log_file}
  ''}
''