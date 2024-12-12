{ pkgs ? import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/e8c38b73aeb218e27163376a2d617e61a2ad9b59.tar.gz";
    sha256 = "1n6gdjny8k5rwkxh6sp1iwg1y3ni1pm7lvh9sisifgjb18jdvzbm";
  }) {}
, spec2006-src ? throw "Please specify <spec2006-src> the path of spec2006, for example: /path/of/spec2006.tar.gz"
, enableVector ? false
# TODO: figure out how to elegantly set 483_xalancbmk maxK=100
#, maxK ? 30
# TODO: check args
, cpt-intervals ? "20000000"
, cpt-simulator ? "qemu"
, cpt-format ? "zstd"
}:
let
  raw = import ./raw.nix {
    inherit pkgs spec2006-src;
  };
in raw.overrideScope (r-self: r-super: {
  build = benchmark: (r-super.build benchmark).overrideScope (b-self: b-super: {
    stage1-profiling = b-super.stage1-profiling.override {
      intervals = cpt-intervals;
      simulator = cpt-simulator;
    };
    stage3-checkpoint = b-super.stage3-checkpoint.override {
      intervals = cpt-intervals;
      simulator = cpt-simulator;
      checkpoint_format = cpt-format;
    };
  });

  spec2006 = let
    bare = pkgs.lib.filterAttrs (n: v: builtins.match "[0-9][0-9][0-9]_.*" n != null) r-super.spec2006;
    bare-overrided = builtins.mapAttrs (n: v: v.overrideScope ( self: super: {
      benchmark = super.benchmark.override { inherit enableVector; };
    })) bare;
  in bare-overrided // (r-super.tools.weave bare-overrided);

  openblas = r-super.openblas.overrideScope ( self: super: {
    benchmark = super.benchmark.override { inherit enableVector; };
  });
})
