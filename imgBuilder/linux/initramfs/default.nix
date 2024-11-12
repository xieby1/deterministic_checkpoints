{ runCommand
, callPackage
, cpio

, riscv64-cc
, riscv64-libc-static
, riscv64-busybox
, benchmark
}: let
  cpioPatched = cpio.overrideAttrs (old: { patches = [./cpio_reset_timestamp.patch]; });
  base = callPackage ./base {};
  initramfs_overlays = callPackage ./overlays {
    inherit riscv64-cc riscv64-libc-static riscv64-busybox;
    # TODO: check if `run` doest not exist, throw an error
    benchmark-run = benchmark.run;
  };
in runCommand "${benchmark.name}.cpio" {} ''
  cp ${base}/init.cpio $out
  chmod +w $out
  cd ${benchmark}
  find . | sort -n | ${cpioPatched}/bin/cpio --reproducible -H newc -oAF $out
  cd ${initramfs_overlays}
  find . | sort -n | ${cpioPatched}/bin/cpio --reproducible -H newc -oAF $out
''
