{ pkgs ? import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/tarball/release-23.11";
    sha256 = "sha256:1f5d2g1p6nfwycpmrnnmc2xmcszp804adp16knjvdkj8nz36y1fg";
  }) {}
}: let
  lib-customized = pkgs.callPackage ./lib-customized.nix {};
in rec {
  riscv64-cc = pkgs.pkgsCross.riscv64.stdenv.cc;
  riscv64-libc-static = pkgs.pkgsCross.riscv64.stdenv.cc.libc.static;
  riscv64-fortran = let
    pkgs2311 = import (fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/tarball/release-23.11";
      sha256 = "sha256:1f5d2g1p6nfwycpmrnnmc2xmcszp804adp16knjvdkj8nz36y1fg";
    }) {};
  # TODO: Why pkgs 24.05 gfortran does not work, but 23.11 works?
  in pkgs2311.pkgsCross.riscv64.wrapCCWith {
    cc = pkgs.pkgsCross.riscv64.stdenv.cc.cc.override {
      name = "gfortran";
      langFortran = true;
      langCC = false;
      langC = false;
      profiledCompiler = false;
    };
    # fixup wrapped prefix, which only appear if hostPlatform!=targetPlatform
    #   for more details see <nixpkgs>/pkgs/build-support/cc-wrapper/default.nix
    stdenvNoCC = pkgs.pkgsCross.riscv64.stdenvNoCC.override {
      hostPlatform = pkgs.stdenv.hostPlatform;
    };
  };
  riscv64-jemalloc = pkgs.pkgsCross.riscv64.jemalloc;

  # TODO: move to benchmarks/ folder
  spec2006 = pkgs.callPackage ./spec2006 {
    inherit riscv64-cc riscv64-fortran riscv64-libc-static;
    inherit riscv64-jemalloc;
  };

  gcpt-bin = import ./imgBuilder {inherit pkgs; benchmark=spec2006."403.gcc";};
  cpt = import ./cptBuilder/default.nix {inherit pkgs gcpt-bin;};

  checkpointsAttrs = builtins.mapAttrs (name: benchmark: import ./cptBuilder {
    inherit pkgs;
    gcpt-bin = import ./imgBuilder { inherit pkgs benchmark; };
  }) (pkgs.lib.filterAttrs (n: v: (pkgs.lib.isDerivation v)) spec2006);
  # TODO: use native linkFarm
  checkpoints = lib-customized.linkFarmNoEntries "checkpoints" (
    pkgs.lib.mapAttrsToList ( name: path: {inherit name path; } ) checkpointsAttrs
  );

  openblas = pkgs.callPackage ./benchmarks/openblas {
    inherit riscv64-cc riscv64-fortran riscv64-libc-static;
    riscv64-libfortran = pkgs.pkgsCross.riscv64.gfortran.cc;
  };
  # TODO: rename
  checkpoints-openblas = import ./cptBuilder {
    inherit pkgs;
    gcpt-bin = import ./imgBuilder {
      inherit pkgs;
      benchmark = openblas;
    };
  };
}
