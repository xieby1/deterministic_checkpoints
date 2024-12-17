{ runCommand
, cpio

, benchmark
, base
, overlays
}@args: let
  cpioPatched = cpio.overrideAttrs (old: { patches = [./cpio_reset_timestamp.patch]; });
in runCommand "${benchmark.name}.cpio" {
  passthru = args // { inherit cpioPatched; };
} ''
  cp ${base}/init.cpio $out
  chmod +w $out
  cd ${benchmark}
  find . | sort -n | ${cpioPatched}/bin/cpio --reproducible -H newc -oAF $out
  cd ${overlays}
  find . | sort -n | ${cpioPatched}/bin/cpio --reproducible -H newc -oAF $out
''
