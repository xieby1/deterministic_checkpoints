{ pkgs ? import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/e8c38b73aeb218e27163376a2d617e61a2ad9b59.tar.gz";
    sha256 = "1n6gdjny8k5rwkxh6sp1iwg1y3ni1pm7lvh9sisifgjb18jdvzbm";
  }) {}
, spec2006-src ? throw "Please specify <spec2006-src> the path of spec2006, for example: /path/of/spec2006.tar.gz"
, enableVector ? false
}:
let
  # TODO: remove, use pkgs.lib
  lib = import <nixpkgs/lib>;
  deterload = import ./. {
    inherit pkgs spec2006-src;
  };
in deterload.overrideScope (d-self: d-super: {
  spec2006 = let
    bare = lib.filterAttrs (n: v: builtins.match "[0-9][0-9][0-9]_.*" n != null) d-super.spec2006;
    bare-overrided = builtins.mapAttrs (n: v: v.overrideScope ( self: super: {
      benchmark = super.benchmark.override { inherit enableVector; };
    })) bare;
  in bare-overrided // (d-super.tools.weave bare-overrided);

  openblas = d-super.openblas.overrideScope ( self: super: {
    benchmark = super.benchmark.override { inherit enableVector; };
  });
})
