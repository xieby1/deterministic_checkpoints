{ writeText
, runCommand
, callPackage

, riscv64-pkgs
, benchmark-run
}:
let
  name = "initramfs-overlays";
  before_workload = callPackage ./before_workload {};
  qemu_trap = callPackage ./qemu_trap {};
  nemu_trap = callPackage ./nemu_trap {};
  riscv64-busybox = riscv64-pkgs.busybox.override {
    enableStatic = true;
    useMusl = true;
  };
  inittab = writeText "inittab" ''
    ::sysinit:/bin/busybox --install -s
    /dev/console::sysinit:-/bin/sh /bin/run.sh
  '';
  # TODO: pass config through parameters
  config = import ../../../../../config.nix;
  trapCommand = if config.simulator == "nemu" then "nemu_trap" else "qemu_trap";
  run_sh = writeText "run.sh" ''
    before_workload
    echo start
    ${benchmark-run}
    echo exit
    ${trapCommand}
  '';
in runCommand name {} ''
  mkdir -p $out/bin
  cp ${riscv64-busybox}/bin/busybox $out/bin/
  ln -s /bin/busybox $out/init

  mkdir -p $out/etc
  cp ${inittab} $out/etc/inittab

  mkdir -p $out/bin
  cp ${before_workload}/bin/before_workload $out/bin/
  cp ${qemu_trap}/bin/qemu_trap $out/bin/
  cp ${nemu_trap}/bin/nemu_trap $out/bin/
  cp ${run_sh} $out/bin/run.sh
''
