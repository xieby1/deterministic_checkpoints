let
  pname = "simpoint";
  version = "3.2";
  pkgs = import <nixpkgs> {};
in pkgs.stdenv.mkDerivation {
  inherit pname version;
  src = pkgs.fetchurl {
    url = "http://cseweb.ucsd.edu/~calder/${pname}/releases/SimPoint.${version}.tar.gz";
    sha256 = "0cp11461ygyskkbzxbl187i3m12b2mzgm4cj7panx5jqpiz491pc";
  };
  patches = [(pkgs.fetchurl {
    url = "https://github.com/intel/pinplay-tools/raw/60e034fe4bc23ec551870fa382d0a64f21b8aeb7/pinplay-scripts/PinPointsHome/Linux/bin/simpoint_modern_gcc.patch";
    sha256 = "1wh7nvv34yacbk8zmydg4x9kxzd7fcw0k8w1c7i13ynj1dwy743b";
  })];
  installPhase = ''
    mkdir -p $out/bin
    cp bin/simpoint $out/bin/
  '';
}
