let
  pkgs = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/tarball/release-23.11";
    sha256 = "sha256:1f5d2g1p6nfwycpmrnnmc2xmcszp804adp16knjvdkj8nz36y1fg";
  }) {};
  all-packages = import ./all-packages.nix {
    inherit pkgs;
  };
in all-packages.stage3-checkpoints
