{
  # TODO: gcc14 have a bug to compile spec2006 & spec2017's xalan
  #   * https://github.com/llvm/llvm-project/issues/109966
  #   * https://gcc.gnu.org/bugzilla/show_bug.cgi?id=116064
  cc = "gcc13";
  simulator = "nemu";       # nemu or qemu
  intervals = 20000000;
  workload = "miao";
  # TODO: remove *_log
  profiling_log = "profiling.log";
  checkpoint_log = "checkpoint.log";
  checkpoint_format = "zstd";   # gz or zstd, qemu only support zstd compressed
}
