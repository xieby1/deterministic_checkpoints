{ lib
, callPackage
}: lib.makeScope lib.callPackageWith (self: {
  spec2006 = callPackage ./spec2006 {};
  openblas = callPackage ./openblas {};
})
