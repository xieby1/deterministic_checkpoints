{
  testCase ? "403.gcc"
}:
let
  name = "3.checkpoint.nix-${testCase}";
  pkgs = import <nixpkgs> {};
  qemu = import ../qemu;
  opensbi = import ../opensbi;
  linux = import ../linux;
  stage2_cluster = import ./2.cluster.nix {inherit testCase;};
in pkgs.runCommand name {} (''
  mkdir -p $out
'' + (builtins.toString [
  "${qemu}/bin/qemu-system-riscv64"
  "-bios"
  "${opensbi}/fw_payload.${testCase}.bin"
  "-M"
  "nemu,simpoint-path=${stage2_cluster},workload=.,cpt-interval=20000000,output-base-dir=$out,config-name=miao,checkpoint-mode=SimpointCheckpoint"
  "-nographic"
  "-m 8G"
  "-smp 1"
  "-cpu rv64,v=true,vlen=128,h=false,sv39=true,sv48=false,sv57=false,sv64=false"
  "-kernel ${linux}/arch/riscv/boot/Image.${testCase}"
  ''-append "norandmaps"''
  "-icount shift=0,align=off,sleep=off"
]))
