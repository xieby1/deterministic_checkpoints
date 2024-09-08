{ runCommand

, cpio
, initramfs_base
, initramfs_overlays
, spec2006
}:
let
  name = "spec2006.cpio";
in runCommand name {} ''
  mkdir -p $out

  for WORK_DIR in ${spec2006}/[0-9][0-9][0-9].*; do
    TESTCASE_NAME=''${WORK_DIR##*/}
    cp ${initramfs_base}/init.cpio $out/$TESTCASE_NAME.cpio
    chmod +w $out/$TESTCASE_NAME.cpio

    cd $WORK_DIR
    find . | sort -n | ${cpio}/bin/cpio --reproducible -H newc -oAF $out/$TESTCASE_NAME.cpio
    cd ${initramfs_overlays}
    find . | sort -n | ${cpio}/bin/cpio --reproducible -H newc -oAF $out/$TESTCASE_NAME.cpio
  done
''
