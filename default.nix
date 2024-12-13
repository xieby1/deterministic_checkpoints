{ pkgs ? import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/e8c38b73aeb218e27163376a2d617e61a2ad9b59.tar.gz";
    sha256 = "1n6gdjny8k5rwkxh6sp1iwg1y3ni1pm7lvh9sisifgjb18jdvzbm";
  }) {}

# TODO: replace pkgs.lib with lib
#######################################################################################
# Benchmarks Configuration
#######################################################################################
, spec2006-src ? throw "Please specify <spec2006-src> the path of spec2006, for example: /path/of/spec2006.tar.gz"
, spec2006-size ? "ref"
, spec2006-optimize ? "-O3 -flto"
, spec2006-march ? "rv64gc${pkgs.lib.optionalString enableVector "v"}_zba_zbb_zbc_zbs"
# spec2006-testcase-filter is a function of type `string -> bool`
# It takes a testcase name from spec2006 as input and returns:
# * true: include this testcase
# * false: exclude this testcase
# For example:
# * Include all testcases: `testcase: true;`
# * Only include 403_gcc: `testcase: testcase=="403_gcc";`
# * Exlcude "464_h264ref" and "465_tonto": `testcase: !(builtins.elem testcase ["464_h264ref" "465_tonto"]);`
, spec2006-testcase-filter ? testcase: true
, enableVector ? false

#######################################################################################
# Builders Configuration
#######################################################################################
, cpt-maxK ? "30"
# cpt-maxK for each benchmark
# How to get the benchmark name:
# Use command: `nix-instantiate --eval -A <benchmark>.benchmark.pname/name`
# Try `pname` first, if not available then use `name`. Examples:
# * Using pname: `nix-instantiate --eval -A openblas.benchmark.pname`
# * Using name: `nix-instantiate --eval -A spec2006.483_xalancbmk.benchmark.name`
, cpt-maxK-bmk ? {
    # TODO: rename xxx.yyyyyyy to xxx_yyyyyy ?
    "483.xalancbmk" = "100";
  }
, cpt-intervals ? "20000000"
, cpt-simulator ? "qemu"
, cpt-format ? "zstd"
}:
assert pkgs.lib.assertOneOf "spec2006-size" spec2006-size ["ref" "test"];
assert pkgs.lib.assertOneOf "cpt-simulator" cpt-simulator ["qemu" "nemu"];
assert pkgs.lib.assertOneOf "cpt-format" cpt-format ["gz" "zstd"];
assert pkgs.lib.assertMsg (cpt-simulator=="qemu" -> cpt-format=="zstd") "qemu only support cpt-format: zstd";
let
  raw = import ./raw.nix { inherit pkgs; };
  getName = p: if (p?pname) then p.pname else p.name;
  escapeName = pkgs.lib.converge (name:
    builtins.replaceStrings
      [" " "." "-" "__"]
      [""  ""  "_" "_" ]
  name);
in raw.overrideScope (r-self: r-super: {
  build = benchmark: (r-super.build benchmark).overrideScope (b-self: b-super: {
    stage1-profiling = b-super.stage1-profiling.override {
      intervals = cpt-intervals;
      simulator = cpt-simulator;
    };
    stage2-cluster = b-super.stage2-cluster.override {
      maxK = if (cpt-maxK-bmk ? "${getName benchmark}")
        then cpt-maxK-bmk."${getName benchmark}"
        else cpt-maxK;
    };
    stage3-checkpoint = b-super.stage3-checkpoint.override {
      intervals = cpt-intervals;
      simulator = cpt-simulator;
      checkpoint_format = cpt-format;
    };
  });

  spec2006 = let
    bare = pkgs.lib.filterAttrs (testcase: v:
      (builtins.match "[0-9][0-9][0-9]_.*" testcase != null) &&
      (spec2006-testcase-filter testcase)
    ) r-super.spec2006;
    bare-overrided = builtins.mapAttrs (n: v: v.overrideScope ( self: super: {
      benchmark = super.benchmark.override {
        inherit enableVector;
        src = spec2006-src;
        size = spec2006-size;
        optimize = spec2006-optimize;
        march = spec2006-march;
      };
    })) bare;
  in bare-overrided // (r-super.tools.wrap-l2 (escapeName (builtins.concatStringsSep "_" [
    "spec2006"
    spec2006-size
    "gcc_1410"
    spec2006-optimize
    spec2006-march
    cpt-simulator
    "1core"
  ])) bare-overrided);

  openblas = r-super.openblas.overrideScope ( self: super: {
    benchmark = super.benchmark.override { inherit enableVector; };
  });
})
