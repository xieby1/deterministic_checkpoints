{ stdenv
, fetchFromGitHub
, pkg-config
, zstd
, readline
, ncurses
, bison
, flex
, git
, zlib
, which
, riscv64-cc
, SDL2
}:

let
  libCheckpointAlpha = fetchFromGitHub {
    owner = "OpenXiangShan";
    repo = "LibCheckpointAlpha";
    rev = "c5c2fef74133fb2b8ef8642633f60e0996493f29";
    sha256 = "sha256-Rxlv47QY273jbcSX/A1PuT7+2aCB2sVW32pL91G3BmI=";
  };

  softfloat = fetchFromGitHub {
    owner = "ucb-bar";
    repo = "berkeley-softfloat-3";
    rev = "3b70b5d";
    sha256 = "sha256-uBXfFgKuGixDIupetB/p421YmZM/AlBmJi4VgFOjbC0=";
  };
in
stdenv.mkDerivation {
  name = "xs-checkpoint-nemu";
  src = fetchFromGitHub {
    owner = "OpenXiangShan";
    repo = "NEMU";
    # latest checkpoint branch
    rev = "4332a525";
    hash = "sha256-nVnSVdZa5pskPE8wVVD43e/vrsukeb7KQjPu34HbYko=";
  };
  
  buildInputs = [
    git
    zlib
    which
    # ccache
    zstd
    readline
    ncurses
    pkg-config
    bison
    flex
    riscv64-cc
    SDL2
  ];

    buildPhase = ''
      # Setup LibCheckpointAlpha
      mkdir -p resource/gcpt_restore
      cp -r ${libCheckpointAlpha}/* resource/gcpt_restore/

      # Setup berkeley-softfloat-3
      mkdir -p resource/softfloat/repo
      cp -r ${softfloat}/* resource/softfloat/repo/

      # Build NEMU
      export NEMU_HOME=$PWD
      
      # Disable ccache
      export USE_CCACHE=
      export CCACHE_DISABLE=1

      # Ensure all necessary directories exist
      mkdir -p tools/kconfig/build
      mkdir -p tools/fixdep/build
      mkdir -p build/obj-riscv64-nemu-interpreter-so

      # Build necessary tools
      make -C tools/kconfig name=conf
      make -C tools/fixdep

      # Build gcpt_restore
      make -C resource/gcpt_restore

      make riscv64-xs-cpt_defconfig

      # Ensure softfloat build directory has write permissions
      mkdir -p resource/softfloat/repo/build/Linux-x86_64-GCC
      chmod -R u+w resource/softfloat/repo/build

      make -j 100

      echo "Build phase completed"
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp build/riscv64-nemu-interpreter $out/bin/
    '';
}