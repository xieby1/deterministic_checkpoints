{ runCommand
, callPackage
, cpio

, benchmark
}: let
  cpioPatched = cpio.overrideAttrs (old: { patches = [./cpio_reset_timestamp.patch]; });
  base = callPackage ./base {};
  overlays = callPackage ./overlays {
    # TODO: check if `run` doest not exist, throw an error
    benchmark-run = benchmark.run;
  };
in runCommand "${benchmark.name}.cpio" {} ''
  cp ${base}/init.cpio $out
  chmod +w $out
  cd ${benchmark}
  find . | sort -n | ${cpioPatched}/bin/cpio --reproducible -H newc -oAF $out
  cd ${overlays}
  find . | sort -n | ${cpioPatched}/bin/cpio --reproducible -H newc -oAF $out
''
