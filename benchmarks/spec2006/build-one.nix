{ runCommand

, callPackage
, src
, size
, enableVector
, optimize
, march
, testCase
}: let
  build-all = callPackage ./build-all.nix {
    inherit src size enableVector optimize march;
  };
in runCommand "${testCase}" {
  # sh script to run a testcase
  run = ''
    cd /run
    sh ./run-spec.sh
  '';
} ''
  mkdir -p $out
  cp -r ${build-all}/${testCase}/* $out/
''
