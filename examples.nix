{
  spec2006-src
}:
let
  lib = import <nixpkgs/lib>;
  deterload = import ./. {inherit spec2006-src;};
in {
  spec2006-novec = deterload.spec2006;
  spec2006-vec = let
    bare = lib.filterAttrs (n: v: builtins.match "[0-9][0-9][0-9]_.*" n != null) deterload.spec2006;
    bare-overrided = builtins.mapAttrs (n: v: v.overrideScope ( self: super: {
      benchmark = super.benchmark.override { enableVector = true; };
    })) bare;
  in bare-overrided // (deterload.tools.weave bare-overrided);

  openblas-novec = deterload.openblas;
  openblas-vec = deterload.openblas.overrideScope ( self: super: {
    benchmark = super.benchmark.override { TARGET="RISCV64_ZVL128B"; };
  });
}
