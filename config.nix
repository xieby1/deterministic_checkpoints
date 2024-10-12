{
  simulator = "nemu";       # nemu or qemu
  intervals = 20000000;
  workload = "miao";
  size = "ref";            # test or ref
  profiling_log = "profiling.log";
  checkpoint_log = "checkpoint.log";
  spec2006_path = /nfs/home/yanyue/tools/spec2006;
  checkpoint_format = "zstd";   # gz or zstd, qemu only support zstd compressed
}