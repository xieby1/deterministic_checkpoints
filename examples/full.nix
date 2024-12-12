{...}@args: import ../. ({
  spec2006-size = "test";
  enableVector = true;

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
