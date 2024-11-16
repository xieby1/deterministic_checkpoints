{ pkgs ? import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/tarball/release-24.05";
    sha256 = "sha256:08ksshv1z4y0dchqrd2j6ikdgna6zz9yqral0zkl3rfbfsiv3q81";
  }) {}
, ...
} @ args: let
  scope = pkgs.lib.makeScope pkgs.newScope (self: rec {
    riscv64-pkgs = pkgs.pkgsCross.riscv64;
    riscv64-cc = riscv64-pkgs.stdenv.cc;
    riscv64-libc-static = riscv64-pkgs.stdenv.cc.libc.static;
    riscv64-fortran = riscv64-pkgs.wrapCCWith {
      cc = riscv64-pkgs.stdenv.cc.cc.override {
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
    dconfig = import ./config.nix // args;
    traceDConfig = dconfig: name: builtins.trace
      "🧾 ${name}'s dconfig = ${pkgs.lib.generators.toPretty {} dconfig} 😺"
      name;
  });
in {
  spec2006 = let
    benchmarks = scope.callPackage ./benchmarks/spec2006 {};
    checkpointsAttrs = builtins.mapAttrs (name: benchmark:
      scope.callPackage ./builders { inherit benchmark; }
    ) (pkgs.lib.filterAttrs (n: v: (pkgs.lib.isDerivation v)) benchmarks);
  in (pkgs.linkFarm "checkpoints" (
    pkgs.lib.mapAttrsToList ( name: path: {inherit name path; } ) checkpointsAttrs
  )).overrideAttrs (old: { passthru = checkpointsAttrs; });

  openblas = let
    benchmark = scope.callPackage ./benchmarks/openblas {};
  in scope.callPackage ./builders { inherit benchmark; };
}
