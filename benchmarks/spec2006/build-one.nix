{ runCommand

, callPackage
, src
, size
, enableVector
, testCase
}: let
  build-all = callPackage ./build-all.nix { inherit src size enableVector; };
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
