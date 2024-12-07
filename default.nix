{ pkgs ? import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/e8c38b73aeb218e27163376a2d617e61a2ad9b59.tar.gz";
    sha256 = "1n6gdjny8k5rwkxh6sp1iwg1y3ni1pm7lvh9sisifgjb18jdvzbm";
  }) {}
  , ...
} @ args:
let
  riscv64-pkgs = pkgs.pkgsCross.riscv64;
  # TODO: gcc14 have a bug to compile spec2006 & spec2017's xalan
  #   * https://github.com/llvm/llvm-project/issues/109966
  #   * https://gcc.gnu.org/bugzilla/show_bug.cgi?id=116064
  riscv64-stdenv = riscv64-pkgs.gcc13Stdenv;
  riscv64-cc = riscv64-stdenv.cc;
  riscv64-libc-static = riscv64-stdenv.cc.libc.static;
  riscv64-fortran = riscv64-pkgs.wrapCCWith {
    cc = riscv64-stdenv.cc.cc.override {
      name = "gfortran";
      langFortran = true;
      langCC = false;
      langC = false;
      profiledCompiler = false;
    };
    # fixup wrapped prefix, which only appear if hostPlatform!=targetPlatform
    #   for more details see <nixpkgs>/pkgs/build-support/cc-wrapper/default.nix
    stdenvNoCC = riscv64-pkgs.stdenvNoCC.override {
      hostPlatform = pkgs.stdenv.hostPlatform;
    };
    # Beginning from 24.05, wrapCCWith receive `runtimeShell`.
    # If leave it empty, the default uses riscv64-pkgs.runtimeShell,
    # thus executing the sheBang will throw error:
    #   `cannot execute: required file not found`.
    runtimeShell = pkgs.runtimeShell;
  };
  riscv64-scope = pkgs.lib.makeScope pkgs.newScope (self: {
    inherit riscv64-pkgs riscv64-stdenv riscv64-cc riscv64-libc-static riscv64-fortran;
  });
  build = import ./builders { inherit riscv64-scope; };
in {
  # TODO: 483_xalancbmk maxK="100"
  spec2006 = let
    benchmarks = riscv64-scope.callPackage ./benchmarks/spec2006 {
      src = if args ? spec2006-src
        then args.spec2006-src
        else throw ''
          Please specify the path of spec2006, for example:
            nix-build ... --arg spec2006-src /path/of/spec2006.tar.gz ...
        '';
    };
    attrs = builtins.mapAttrs (name: benchmark:
      build { inherit benchmark; }
    ) (pkgs.lib.filterAttrs (n: v: (pkgs.lib.isDerivation v)) benchmarks);
  in (pkgs.linkFarm "checkpoints" (
    pkgs.lib.mapAttrsToList ( name: path: {inherit name path; } ) attrs
  )).overrideAttrs (old: { passthru = attrs; });

  openblas = let
    benchmark = riscv64-scope.callPackage ./benchmarks/openblas {};
  in build { inherit benchmark; };
}
