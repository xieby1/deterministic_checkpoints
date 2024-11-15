{ callPackage
, riscv64-cc
, riscv64-libc-static

, benchmark
}: let
  gcpt = callPackage ./gcpt { inherit benchmark; };
# TODO: not passthru here, in gcpt
in gcpt.overrideAttrs (old: {
  passthru = {
    inherit riscv64-cc riscv64-libc-static benchmark;
  };
})
