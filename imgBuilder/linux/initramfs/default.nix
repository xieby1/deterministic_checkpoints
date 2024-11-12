{ runCommand
, callPackage
, cpio

, initramfs_overlays
, benchmark
}: let
  cpioPatched = cpio.overrideAttrs (old: { patches = [./cpio_reset_timestamp.patch]; });
  base = callPackage ./base {};
in runCommand "${benchmark.name}.cpio" {} ''
  cp ${base}/init.cpio $out
  chmod +w $out
  cd ${benchmark}
  find . | sort -n | ${cpioPatched}/bin/cpio --reproducible -H newc -oAF $out
  cd ${initramfs_overlays}
  find . | sort -n | ${cpioPatched}/bin/cpio --reproducible -H newc -oAF $out
''