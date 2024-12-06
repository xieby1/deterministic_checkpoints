{ stdenv
, lib
, fetchFromGitHub
, libxcrypt-legacy

, riscv64-pkgs
, riscv64-cc
, riscv64-fortran
, riscv64-libc-static
, src
, size ? "ref" # "ref" or "test"
}:
let
  customJemalloc = riscv64-pkgs.jemalloc.overrideAttrs (oldAttrs: {
    configureFlags = (oldAttrs.configureFlags or []) ++ [
      "--enable-static"
      "--disable-shared"
    ];
    preBuild = ''
      # Add weak attribute to C++ operators, same as jemalloc_cpp.patch
      sed -i 's/void \*operator new(size_t)/void *operator new(size_t) __attribute__((weak))/g' src/jemalloc_cpp.cpp
      sed -i 's/void operator delete(void \*)/void operator delete(void *) __attribute__((weak))/g' src/jemalloc_cpp.cpp
    '';
    # Ensure static libraries are installed
    postInstall = ''
      ${oldAttrs.postInstall or ""}
      cp -v lib/libjemalloc.a $out/lib/
    '';
  });
  CPU2006LiteWrapper = fetchFromGitHub {
    owner = "OpenXiangShan";
    repo = "CPU2006LiteWrapper";
    rev = "010ca8fe8bf229c68443a2dd1766e1be62fa7998";
    hash = "sha256-qNxmM9Dmobr6fvTZapacu8jngcBPRbybwayTi7CZGd0=";
  };
in stdenv.mkDerivation {
  name = "spec2006exe";
  system = "x86_64-linux";

  srcs = [
    src
    CPU2006LiteWrapper
  ];
  sourceRoot = ".";

  buildInputs = [
    riscv64-cc
    riscv64-fortran
    riscv64-libc-static
    customJemalloc
  ];

  patchPhase = ''
    # Delete the test.t subtestcase in spec2006 400.perlbench using test input.
    # Details:
    #   Due to the timer interrupt is disabled,
    #   the testcase `sleep.t` in 400.perlbench's test input results in endless loop.
    #   Related source code see:
    #   * [profiling QEMU plugin](https://github.com/OpenXiangShan/qemu/blob/8758c375de12f09073614cad48f9956fe53b5aa7/contrib/plugins/profiling.c#L249)
    #   * [before_workload](https://github.com/OpenXiangShan/riscv-rootfs/blob/03bdc9553ed9db132844b1e314485d465667eabd/apps/before_workload/before_workload.c#L15)
    sed -i '/sleep.t/d' ./spec2006/benchspec/CPU2006/400.perlbench/data/test/input/test.pl
  '';

  configurePhase = let
    rpath = lib.makeLibraryPath [
      libxcrypt-legacy
    ];
  in ''
    echo patchelf: ./spec2006/bin/
    for file in $(find ./spec2006/bin -type f \( -perm /0111 -o -name \*.so\* \) ); do
      patchelf --set-interpreter "$(cat ${stdenv.cc}/nix-support/dynamic-linker)" "$file" &> /dev/null || true
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
    export OPTIMIZE="-O3 -flto -march=rv64gc_zba_zbb_zbc_zbs"
    export SUBPROCESS_NUM=5

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
