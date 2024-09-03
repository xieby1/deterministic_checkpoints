let
  name = "1.profiling";
  pkgs = import <nixpkgs> {};
  qemu = import ../qemu;
  opensbi = import ../opensbi;
  linux = import ../linux;
in pkgs.runCommand name {} (''
  mkdir -p $out
'' + (builtins.toString [
  "${qemu}/bin/qemu-system-riscv64"
  "-bios ${opensbi}/fw_payload.bin"
  "-M nemu"
  "-nographic"
  "-m 8G"
  "-smp 1"
  "-cpu rv64,v=true,vlen=128,h=false,sv39=true,sv48=false,sv57=false,sv64=false"
  "-plugin ${qemu}/lib/libprofiling.so,workload=miao,intervals=20000000,target=$out"
  "-kernel ${linux}/arch/riscv/boot/Image"
  ''-append "norandmaps"''
  "-icount shift=0,align=off,sleep=off"
]))
