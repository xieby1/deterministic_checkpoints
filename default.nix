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
in rec {
  tools = {
    /*weave {a={x=drv0;y=drv1;z=drv2;}; b={x=drv3;y=drv4;z=drv5;}; c={x=drv6;y=drv7;z=drv8;};}
      returns {x=linkFarm [drv0 drv3 drv6]; y=linkFarm [drv1 drv4 drv7]; z=linkFarm [drv2 drv5 drv8];}*/
    weave = attrs-drvs: let
      /*mapToAttrs (name: {inherit name; value=...}) ["a", "b", "c", ...]
        returns {x=value0; b=value1; c=value2; ...} */
      mapToAttrs = func: list: builtins.listToAttrs (builtins.map func list);
      /*attrValueNames {a={x=1;y=2;z=3;}; b={x=11;y=22;z=33;}; c={x=0;y=0;z=0;};}
        returns ["x" "y" "z"] */
      attrValueNames = attr: builtins.attrNames (builtins.head (builtins.attrValues attr));
    in mapToAttrs (name/*represents the name in builders/default.nix, like img, cpt, ...*/: {
      inherit name;
      value = pkgs.linkFarm name (
        pkgs.lib.mapAttrsToList (testCase: buildResult: {
          name = testCase;
          path = buildResult."${name}";
        }) attrs-drvs);
    }) (attrValueNames attrs-drvs);
  };

  spec2006 = let
    benchmarks = callPackage ./benchmarks/spec2006 {
      src = if args ? spec2006-src
        then args.spec2006-src
        else throw ''
          Please specify the path of spec2006, for example:
            nix-build ... --arg spec2006-src /path/of/spec2006.tar.gz ...
        '';
    };
    bare = builtins.mapAttrs (name: benchmark:
      (build { inherit benchmark; }).overrideScope (
        if name=="483_xalancbmk" then (self: super: {
        stage2-cluster = super.stage2-cluster.override {maxK="100";};
      }) else (self: super: {}))
    ) (pkgs.lib.filterAttrs (n: v: (pkgs.lib.isDerivation v)) benchmarks);
  in bare // (tools.weave bare);

  openblas = let
    benchmark = callPackage ./benchmarks/openblas {};
  in build { inherit benchmark; };
}
