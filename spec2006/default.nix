let
  # TODO: use latest nixpkgs
  # pkgs = import <nixpkgs> {};
  pkgs = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/tarball/release-23.11";
    sha256 = "sha256:1f5d2g1p6nfwycpmrnnmc2xmcszp804adp16knjvdkj8nz36y1fg";
  }) {};
  riscv64Pkgs = pkgs.pkgsCross.riscv64;
  customJemalloc = riscv64Pkgs.jemalloc.overrideAttrs (oldAttrs: {
    configureFlags = (oldAttrs.configureFlags or []) ++ [
      "--enable-static"
      "--disable-shared"
    ];
    preBuild = ''
      # Add weak attribute to C++ operators, 作用和jemalloc_cpp.patch效果一样
      sed -i 's/void \*operator new(size_t)/void *operator new(size_t) __attribute__((weak))/g' src/jemalloc_cpp.cpp
      sed -i 's/void operator delete(void \*)/void operator delete(void *) __attribute__((weak))/g' src/jemalloc_cpp.cpp
    '';
    # Ensure static libraries are installed
    postInstall = ''
      ${oldAttrs.postInstall or ""}
      cp -v lib/libjemalloc.a $out/lib/
    '';
  });
  riscv64Fortran = riscv64Pkgs.wrapCCWith {
    cc = riscv64Pkgs.stdenv.cc.cc.override {
      name = "gfortran";
      langFortran = true;
      langCC = false;
      langC = false;
      profiledCompiler = false;
    };
    # fixup wrapped prefix, which only appear if hostPlatform!=targetPlatform
    #   for more details see <nixpkgs>/pkgs/build-support/cc-wrapper/default.nix
    stdenvNoCC = riscv64Pkgs.stdenvNoCC.override {
      hostPlatform = pkgs.stdenv.hostPlatform;
    };
  };
  CPU2006LiteWrapper = pkgs.fetchFromGitHub {
    owner = "OpenXiangShan";
    repo = "CPU2006LiteWrapper";
    rev = "010ca8fe8bf229c68443a2dd1766e1be62fa7998";
    hash = "sha256-qNxmM9Dmobr6fvTZapacu8jngcBPRbybwayTi7CZGd0=";
  };
  size = "ref";
in pkgs.stdenv.mkDerivation {
  name = "spec2006exe";
  system = "x86_64-linux";

  srcs = [
    ../../../spec2006.tar.gz
    CPU2006LiteWrapper
  ];
  sourceRoot = ".";

  buildInputs = [
    riscv64Pkgs.buildPackages.gcc
    riscv64Pkgs.buildPackages.binutils
    riscv64Fortran
    riscv64Pkgs.glibc
    riscv64Pkgs.glibc.static
    customJemalloc
  ];

  configurePhase = let
    rpath = pkgs.lib.makeLibraryPath [
      pkgs.libxcrypt-legacy
    ];
  in ''
    echo patchelf: ./spec2006/bin/
    for file in $(find ./spec2006/bin -type f \( -perm /0111 -o -name \*.so\* \) ); do
      patchelf --set-interpreter "$(cat ${pkgs.stdenv.cc}/nix-support/dynamic-linker)" "$file" &> /dev/null || true
      patchelf --set-rpath ${rpath} $file &> /dev/null || true
    done
  '';

  buildPhase = ''
    export LiteWrapper=$(realpath ${CPU2006LiteWrapper.name})
    export SPEC=$(realpath ./spec2006)
    cd $LiteWrapper

    export SPEC_LITE=$PWD
    export ARCH=riscv64
    export CROSS_COMPILE=riscv64-unknown-linux-gnu-
    export OPTIMIZE="-O3 -flto"
    export SUBPROCESS_NUM=5

    export CC=${riscv64Pkgs.stdenv.cc}/bin/riscv64-unknown-linux-gnu-gcc
    export CXX=${riscv64Pkgs.stdenv.cc}/bin/riscv64-unknown-linux-gnu-g++
    export LD=${riscv64Pkgs.stdenv.cc}/bin/riscv64-unknown-linux-gnu-ld

    export CFLAGS="$CFLAGS -static -Wno-format-security -I${customJemalloc}/include "
    export CXXFLAGS="$CXXFLAGS -static -Wno-format-security -I${customJemalloc}/include"
    export LDFLAGS="$LDFLAGS -static -ljemalloc -L${customJemalloc}/lib"

    pushd $SPEC && source shrc && popd
    make copy-all-src
    make build-all -j $NIX_BUILD_CORES
    make copy-all-data
  '';

  dontFixup = true;

  # based on https://github.com/OpenXiangShan/CPU2006LiteWrapper/blob/main/scripts/run-template.sh
  installPhase = ''
    for WORK_DIR in [0-9][0-9][0-9].*; do
      echo "Prepare data: $WORK_DIR"
      pushd $WORK_DIR
      mkdir -p run
      if [ -d data/all/input ];        then cp -r data/all/input/*     run/; fi
      if [ -d data/${size}/input ];    then cp -r data/${size}/input/* run/; fi
      if [ -f extra-data/${size}.sh ]; then sh extra-data/${size}.sh       ; fi

      mkdir -p $out/$WORK_DIR/run/
      cp -r run/* $out/$WORK_DIR/run/
      cp build/$WORK_DIR $out/$WORK_DIR/run/
      # Replace $APP with executable in run-<size>.sh
      # E.g.: 481.wrf/run-ref.sh
      #   before replace: [run-ref.h]: $APP > rsl.out.0000
      #   after replace:     [run.sh]: ./481.wrf > rsl.out.0000
      sed 's,\$APP,./'$WORK_DIR',' run-${size}.sh > $out/$WORK_DIR/run/run-spec.sh
      popd
    done

    find $out -type d -exec chmod 555 {} +
  '';
}
