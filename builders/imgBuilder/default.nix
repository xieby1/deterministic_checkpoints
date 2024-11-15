{ callPackage

, benchmark
}: let
  gcpt = callPackage ./gcpt { inherit benchmark; };
in gcpt.overrideAttrs (old: {
  passthru = { inherit gcpt; };
})
