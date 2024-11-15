{
  simulator = "nemu";       # nemu or qemu
  intervals = 20000000;
  workload = "miao";
  # TODO: remove *_log
  profiling_log = "profiling.log";
  checkpoint_log = "checkpoint.log";
  checkpoint_format = "zstd";   # gz or zstd, qemu only support zstd compressed
}
