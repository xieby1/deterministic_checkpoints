{ pkgs ? import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/tarball/release-23.11";
    sha256 = "sha256:1f5d2g1p6nfwycpmrnnmc2xmcszp804adp16knjvdkj8nz36y1fg";
  }) {}
}: rec {
  scope = pkgs.lib.makeScope pkgs.newScope (self: rec {
    riscv64-pkgs = pkgs.pkgsCross.riscv64;
    riscv64-cc = riscv64-pkgs.stdenv.cc;
    riscv64-libc-static = riscv64-pkgs.stdenv.cc.libc.static;
    riscv64-fortran = let
      pkgs2311 = import (fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/tarball/release-23.11";
        sha256 = "sha256:1f5d2g1p6nfwycpmrnnmc2xmcszp804adp16knjvdkj8nz36y1fg";
      }) {};
    # TODO: Why pkgs 24.05 gfortran does not work, but 23.11 works?
    in pkgs2311.pkgsCross.riscv64.wrapCCWith {
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
    };
  });
  spec2006 = scope.callPackage ./benchmarks/spec2006 {};

  checkpointsAttrs = builtins.mapAttrs (name: benchmark:
    scope.callPackage ./builders { inherit benchmark; }
  ) (pkgs.lib.filterAttrs (n: v: (pkgs.lib.isDerivation v)) spec2006);
  # TODO: rename
  checkpoints = (pkgs.linkFarm "checkpoints" (
    pkgs.lib.mapAttrsToList ( name: path: {inherit name path; } ) checkpointsAttrs
  )).overrideAttrs (old: { passthru = checkpointsAttrs; });

  openblas = scope.callPackage ./benchmarks/openblas {};
  # TODO: rename
  checkpoints-openblas = scope.callPackage ./builders { benchmark=openblas; };
}
