{ writeText
, runCommand
, callPackage

, riscv64-cc
, riscv64-libc-static
, busybox
, qemu_trap
, nemu_trap
}:
let
  name = "initramfs-overlays";
  before_workload = callPackage ./before_workload {inherit riscv64-cc riscv64-libc-static;};
  inittab = writeText "inittab" ''
    ::sysinit:/bin/busybox --install -s
    /dev/console::sysinit:-/bin/sh /bin/run.sh
  '';
  config = import ../../../../config.nix;
  trapCommand = if config.simulator == "nemu" then "nemu_trap" else "qemu_trap";
  run_sh = writeText "run.sh" ''
    before_workload
    echo start
    cd /run
    sh ./run-spec.sh
    echo exit
    ${trapCommand}
  '';
in runCommand name {} ''
  mkdir -p $out/bin
  cp ${busybox}/bin/busybox $out/bin/
  ln -s /bin/busybox $out/init

  mkdir -p $out/etc
  cp ${inittab} $out/etc/inittab

  mkdir -p $out/bin
  cp ${before_workload}/bin/before_workload $out/bin/
  cp ${qemu_trap}/bin/qemu_trap $out/bin/
  cp ${nemu_trap}/bin/nemu_trap $out/bin/
  cp ${run_sh} $out/bin/run.sh
''
