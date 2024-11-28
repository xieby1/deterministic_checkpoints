{ callPackage

, benchmark
, ...
}@args: let
  imgBuilder = callPackage ./imgBuilder { inherit benchmark; };
  cptBuilder = callPackage ./cptBuilder ({ inherit imgBuilder; } // args);
in cptBuilder.overrideAttrs (old: {
  passthru = { inherit benchmark imgBuilder cptBuilder; };
})
