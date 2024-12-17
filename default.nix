{ pkgs ? import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/e8c38b73aeb218e27163376a2d617e61a2ad9b59.tar.gz";
    sha256 = "1n6gdjny8k5rwkxh6sp1iwg1y3ni1pm7lvh9sisifgjb18jdvzbm";
  }) {}
, lib ? pkgs.lib

#######################################################################################
# Common Configuration
#######################################################################################
, cc ? "gcc14"

#######################################################################################
# Benchmarks Configuration
#######################################################################################
# Benchmarks Common Configuration ###############################
, enableVector ? false

# SPEC CPU 2006 Configuration ###################################
, spec2006-extra-tag ? ""
, spec2006-src ? throw "Please specify <spec2006-src> the path of spec2006, for example: /path/of/spec2006.tar.gz"
, spec2006-size ? "ref"
, spec2006-optimize ? "-O3 -flto"
, spec2006-march ? "rv64gc${lib.optionalString enableVector "v"}_zba_zbb_zbc_zbs"
# spec2006-testcase-filter is a function of type `string -> bool`
# It takes a testcase name from spec2006 as input and returns:
# * true: include this testcase
# * false: exclude this testcase
# For example:
# * Include all testcases: `testcase: true;`
# * Only include 403_gcc: `testcase: testcase=="403_gcc";`
# * Exlcude "464_h264ref" and "465_tonto": `testcase: !(builtins.elem testcase ["464_h264ref" "465_tonto"]);`
, spec2006-testcase-filter ? testcase: true

# OpenBLAS Configuration ########################################
, openblas-extra-tag ? ""
, openblas-target ? if enableVector then "RISCV64_ZVL128B" else "RISCV64_GENERIC"

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
assert pkgs.pkgsCross.riscv64 ? "${cc}Stdenv";
assert lib.assertOneOf "spec2006-size" spec2006-size ["ref" "test"];
assert lib.assertOneOf "openblas-target" openblas-target ["RISCV64_GENERIC" "RISCV64_ZVL128B" "RISCV64_ZVL256B"];
assert lib.assertOneOf "cpt-simulator" cpt-simulator ["qemu" "nemu"];
assert lib.assertOneOf "cpt-format" cpt-format ["gz" "zstd"];
assert lib.assertMsg (cpt-simulator=="qemu" -> cpt-format=="zstd") "qemu only support cpt-format: zstd";
let
  raw = import ./raw.nix { inherit pkgs; };
  getName = p: if (p?pname) then p.pname else p.name;
  escapeName = lib.converge (name:
    builtins.replaceStrings
      [" " "." "-" "__"]
      [""  ""  "_" "_" ]
  name);
  /*set -> set: filter derivations in a set*/
  filterDrvs = set: lib.filterAttrs (n: v: (lib.isDerivation v)) set;
  /*string -> set -> set:
    wrap-l2 prefix {
      a={x=drv0; y=drv1; z=drv2; w=0;};
      b={x=drv3; y=drv4; z=drv5; w=1;};
      c={x=drv6; y=drv7; z=drv8; w=2;};
    }
    returns {
      x=linkFarm "${prefix}_x" [drv0 drv3 drv6];
      y=linkFarm "${prefix}_y" [drv1 drv4 drv7];
      z=linkFarm "${prefix}_z" [drv2 drv5 drv8];
    }*/
  wrap-l2 = prefix: attrBuildResults: let
    /*mapToAttrs (name: {inherit name; value=...}) ["a", "b", "c", ...]
      returns {x=value0; b=value1; c=value2; ...} */
    mapToAttrs = func: list: builtins.listToAttrs (builtins.map func list);
    /*attrDrvNames {
        a={x=drv0; y=drv1; z=drv2; w=0;};
        b={x=drv3; y=drv4; z=drv5; w=1;};
        c={x=drv6; y=drv7; z=drv8; w=2;};
      }
      returns ["x" "y" "z"] */
    attrDrvNames = set: builtins.attrNames (filterDrvs (builtins.head (builtins.attrValues set)));
  in mapToAttrs (name/*represents the name in builders/default.nix, like img, cpt, ...*/: {
    inherit name;
    value = pkgs.linkFarm (escapeName "${prefix}_${name}") (
      lib.mapAttrsToList (testCase: buildResult: {
        name = testCase;
        path = buildResult."${name}";
      }) attrBuildResults);
  }) (attrDrvNames attrBuildResults);

  wrap-l1 = prefix: buildResult: builtins.mapAttrs (name: value:
    if lib.isDerivation value then pkgs.symlinkJoin {
      name = escapeName "${prefix}_${name}";
      paths = [value];
      passthru = lib.optionalAttrs (value?passthru) value.passthru;
    } else value
  ) buildResult;

  metricPrefix = input: let
    num =  if builtins.isInt input then input
      else if builtins.isString input then lib.toInt input
      else throw "metricPrefix: unspported type of ${input}";
    K = 1000;
    M = 1000 * K;
    G = 1000 * M;
    T = 1000 * G;
    P = 1000 * T;
    E = 1000 * P;
  in     if num < K then "${toString  num     }"
    else if num < M then "${toString (num / K)}K"
    else if num < G then "${toString (num / M)}M"
    else if num < T then "${toString (num / G)}G"
    else if num < P then "${toString (num / T)}T"
    else if num < E then "${toString (num / P)}P"
    else                 "${toString (num / E)}E"
  ;
in raw.overrideScope (r-self: r-super: {
  riscv64-scope = r-super.riscv64-scope.overrideScope (self: super: {
    riscv64-stdenv = super.riscv64-pkgs."${cc}Stdenv";
  });

  build = benchmark: (r-super.build benchmark).overrideScope (b-self: b-super: {
    initramfs_overlays = b-super.initramfs_overlays.override {
      trapCommand = "${cpt-simulator}_trap";
    };

    stage1-profiling = b-super.stage1-profiling.override {
      workload_name = "miao";
      intervals = cpt-intervals;
      simulator = cpt-simulator;
      profiling_log = "profiling.log";
    };
    stage2-cluster = b-super.stage2-cluster.override {
      maxK = if (cpt-maxK-bmk ? "${getName benchmark}")
        then cpt-maxK-bmk."${getName benchmark}"
        else cpt-maxK;
    };
    stage3-checkpoint = b-super.stage3-checkpoint.override {
      workload_name = "miao";
      intervals = cpt-intervals;
      simulator = cpt-simulator;
      checkpoint_format = cpt-format;
      checkpoint_log = "checkpoint.log";
    };
  });

  spec2006 = let
    overrided = builtins.mapAttrs (n: v: v.overrideScope ( self: super: {
      benchmark = super.benchmark.override {
        inherit enableVector;
        src = spec2006-src;
        size = spec2006-size;
        optimize = spec2006-optimize;
        march = spec2006-march;
      };
    })) (lib.filterAttrs
      (testcase: v: spec2006-testcase-filter testcase)
    r-super.spec2006);
  in overrided // (wrap-l2 (builtins.concatStringsSep "_" [
    "spec2006"
    spec2006-size
    (lib.removePrefix "${r-self.riscv64-scope.riscv64-stdenv.targetPlatform.config}-" r-self.riscv64-scope.riscv64-stdenv.cc.cc.name)
    spec2006-optimize
    spec2006-march
    cpt-simulator
    (metricPrefix cpt-intervals)
    (let suffix = lib.optionalString (builtins.any
      (x: x.stage2-cluster.maxK!=cpt-maxK)
      (builtins.attrValues overrided)
    ) "x"; in"maxK${cpt-maxK}${suffix}")
    "1core"
    spec2006-extra-tag
  ]) overrided);

  openblas = let
    unwrapped = r-super.openblas.overrideScope ( self: super: {
      benchmark = super.benchmark.override {
        TARGET = openblas-target;
      };
    });
  in wrap-l1 (builtins.concatStringsSep "_" [
    "openblas"
    (lib.removePrefix "${r-self.riscv64-scope.riscv64-stdenv.targetPlatform.config}-" r-self.riscv64-scope.riscv64-stdenv.cc.cc.name)
    openblas-target
    cpt-simulator
    (metricPrefix cpt-intervals)
    "maxK${unwrapped.stage2-cluster.maxK}"
    "1core"
    openblas-extra-tag
  ]) unwrapped;
})
