let
  pkgs = import <nixpkgs> {};
  name = "spec2006.cpio";
  base = import ./base;
  spec2006 = import ../../spec2006;
in pkgs.runCommand name {} ''
  mkdir -p $out

  for WORK_DIR in ${spec2006}/[0-9][0-9][0-9].*; do
    TESTCASE_NAME=''${WORK_DIR##*/}
    cp ${base}/init.cpio $out/$TESTCASE_NAME.cpio
    chmod +w $out/$TESTCASE_NAME.cpio

    cd $WORK_DIR
    find . | ${pkgs.cpio}/bin/cpio --reproducible -H newc -oAF $out/$TESTCASE_NAME.cpio
  done
''
