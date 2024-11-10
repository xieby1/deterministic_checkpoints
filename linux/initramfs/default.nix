{ runCommand

, cpio
, initramfs_base
, initramfs_overlays
, benchmark
}: runCommand "${benchmark.name}.cpio" {} ''
  cp ${initramfs_base}/init.cpio $out
  chmod +w $out
  cd ${benchmark}
  find . | sort -n | ${cpio}/bin/cpio --reproducible -H newc -oAF $out
  cd ${initramfs_overlays}
  find . | sort -n | ${cpio}/bin/cpio --reproducible -H newc -oAF $out
''
