{ pkgs ? import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/e8c38b73aeb218e27163376a2d617e61a2ad9b59.tar.gz";
    sha256 = "1n6gdjny8k5rwkxh6sp1iwg1y3ni1pm7lvh9sisifgjb18jdvzbm";
  }) {}
  , ...
} @ args:
let
  riscv64-scope = pkgs.lib.makeScope pkgs.newScope (self: {
    riscv64-pkgs = pkgs.pkgsCross.riscv64;
    riscv64-stdenv = self.riscv64-pkgs.gcc14Stdenv;
    riscv64-cc = self.riscv64-stdenv.cc;
    riscv64-libc-static = self.riscv64-stdenv.cc.libc.static;
    riscv64-fortran = self.riscv64-pkgs.wrapCCWith {
      cc = self.riscv64-stdenv.cc.cc.override {
        name = "gfortran";
        langFortran = true;
        langCC = false;
        langC = false;
        profiledCompiler = false;
      };
      # fixup wrapped prefix, which only appear if hostPlatform!=targetPlatform
      #   for more details see <nixpkgs>/pkgs/build-support/cc-wrapper/default.nix
      stdenvNoCC = self.riscv64-pkgs.stdenvNoCC.override {
        hostPlatform = pkgs.stdenv.hostPlatform;
      };
      # Beginning from 24.05, wrapCCWith receive `runtimeShell`.
      # If leave it empty, the default uses riscv64-pkgs.runtimeShell,
      # thus executing the sheBang will throw error:
      #   `cannot execute: required file not found`.
      runtimeShell = pkgs.runtimeShell;
    };
    rmExt = name: builtins.concatStringsSep "."
      (pkgs.lib.init
        (pkgs.lib.splitString "." name));
  });
  callPackage = riscv64-scope.callPackage;
  build = callPackage ./builders {};
in {
  spec2006 = let
    benchmarks = callPackage ./benchmarks/spec2006 {
      src = if args ? spec2006-src
        then args.spec2006-src
        else throw ''
          Please specify the path of spec2006, for example:
            nix-build ... --arg spec2006-src /path/of/spec2006.tar.gz ...
        '';
    };
    spec2006-bare = builtins.mapAttrs (name: benchmark: build {
      inherit benchmark;
      overlay = if name=="483_xalancbmk" then (self: super: {
        stage2-cluster = super.stage2-cluster.override {maxK="100";};
      }) else (self: super: {});
    }) (pkgs.lib.filterAttrs (n: v: (pkgs.lib.isDerivation v)) benchmarks);
  in spec2006-bare // {
    # TODO: add other attrs into spec2006-bare
    cpt = pkgs.linkFarm "checkpoints" (
      pkgs.lib.mapAttrsToList (testCase: buildResult: {
        name = testCase;
        path = buildResult.cpt;
    }) spec2006-bare);
  };

  openblas = let
    benchmark = callPackage ./benchmarks/openblas {};
  in build { inherit benchmark; };
}
