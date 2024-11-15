{ callPackage

, benchmark
}: let
  imgBuilder = callPackage ./imgBuilder { inherit benchmark; };
  cptBuilder = callPackage ./cptBuilder { inherit imgBuilder; };
in cptBuilder.overrideAttrs (old: {
  passthru = { inherit imgBuilder cptBuilder; };
})
