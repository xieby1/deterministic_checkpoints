let
  name = "initramfs-overlays";
  pkgs = import <nixpkgs> {};
  busybox = import ./busybox;
  inittab = pkgs.writeText "inittab" ''
    ::sysinit:/bin/busybox --install -s
    /dev/console::sysinit:-/bin/sh /bin/run.sh
  '';
  before_workload = import ./before_workload;
  qemu_trap = import ./qemu_trap;
  run_sh = pkgs.writeText "run.sh" ''
    before_workload
    echo start
    cd /run
    sh ./run-spec.sh
    echo exit
    qemu_trap
  '';
in pkgs.runCommand name {} ''
  mkdir -p $out/bin
  cp ${busybox}/bin/busybox $out/bin/
  ln -s /bin/busybox $out/init

  mkdir -p $out/etc
  cp ${inittab} $out/etc/inittab

  mkdir -p $out/bin
  cp ${before_workload}/bin/before_workload $out/bin/
  cp ${qemu_trap}/bin/qemu_trap $out/bin/
  cp ${run_sh} $out/bin/run.sh
''
