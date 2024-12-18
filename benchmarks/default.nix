{ lib
, callPackage
, riscv64-pkgs
}: lib.makeScope lib.callPackageWith (self: {
  riscv64-jemalloc = riscv64-pkgs.jemalloc.overrideAttrs (oldAttrs: {
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
  spec2006 = callPackage ./spec2006 {
    inherit (self) riscv64-jemalloc;
  };

  openblas = callPackage ./openblas {};
})
