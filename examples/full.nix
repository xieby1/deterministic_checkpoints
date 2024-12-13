{...}@args: import ../. ({
  enableVector = true;

  spec2006-size = "test";
  # "464_h264ref" and "465_tonto" will be excluded
  spec2006-optimize = "-O3";
  spec2006-march = "rv64gcbv";
  spec2006-testcase-filter = testcase: !(builtins.elem testcase [
    "464_h264ref"
    "465_tonto"
  ]);

  cpt-maxK = "10";
  cpt-maxK-bmk = {
    "403.gcc" = "20";
    "483.xalancbmk" = "30";
    "openblas" = "50";
  };
  cpt-intervals = "1000000";
  cpt-simulator = "nemu";
  cpt-format = "gz";
} // args)
