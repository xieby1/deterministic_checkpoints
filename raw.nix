{ pkgs ? import (fetchTarball { # TODO: remove, as it move into examples.nix
    url = "https://github.com/NixOS/nixpkgs/archive/e8c38b73aeb218e27163376a2d617e61a2ad9b59.tar.gz";
    sha256 = "1n6gdjny8k5rwkxh6sp1iwg1y3ni1pm7lvh9sisifgjb18jdvzbm";
  }) {}
}: let
  /*set -> set: filter derivations in a set*/
  filterDrvs = set: pkgs.lib.filterAttrs (n: v: (pkgs.lib.isDerivation v)) set;
in
pkgs.lib.makeScope pkgs.lib.callPackageWith (ds/*deterload-scope itself*/: {
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

  build = ds.riscv64-scope.callPackage ./builders {};
  tools = {
    /*weave {a={x=drv0;y=drv1;z=drv2;}; b={x=drv3;y=drv4;z=drv5;}; c={x=drv6;y=drv7;z=drv8;};}
      returns {x=linkFarm [drv0 drv3 drv6]; y=linkFarm [drv1 drv4 drv7]; z=linkFarm [drv2 drv5 drv8];}*/
    weave = attrs-drvs: let
      /*mapToAttrs (name: {inherit name; value=...}) ["a", "b", "c", ...]
        returns {x=value0; b=value1; c=value2; ...} */
      mapToAttrs = func: list: builtins.listToAttrs (builtins.map func list);
      /*attrDrvNames {a={x=drv0;y=drv1;z=drv2;w=0;}; b={x=drv3;y=drv4;z=drv5;w=1;}; c={x=drv6;y=drv7;z=drv8;w=2;};}
        returns ["x" "y" "z"] */
      attrDrvNames = set: builtins.attrNames (filterDrvs (builtins.head (builtins.attrValues set)));
    in mapToAttrs (name/*represents the name in builders/default.nix, like img, cpt, ...*/: {
      inherit name;
      value = pkgs.linkFarm name (
        pkgs.lib.mapAttrsToList (testCase: buildResult: {
          name = testCase;
          path = buildResult."${name}";
        }) attrs-drvs);
    }) (attrDrvNames attrs-drvs);
  };

  spec2006 = let
    benchmarks = ds.riscv64-scope.callPackage ./benchmarks/spec2006 {};
    bare = builtins.mapAttrs (name: benchmark: (ds.build benchmark)) (filterDrvs benchmarks);
  in bare // (ds.tools.weave bare);

  openblas = let
    benchmark = ds.riscv64-scope.callPackage ./benchmarks/openblas {};
  in ds.build benchmark;
})
