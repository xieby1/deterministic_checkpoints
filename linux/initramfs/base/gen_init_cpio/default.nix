{ runCommandCC }:
runCommandCC "gen_init_cpio" {
  src = builtins.fetchurl {
    url = "https://github.com/torvalds/linux/raw/f3b2306bea33b3a86ad2df4dcfab53b629e1bc84/usr/gen_init_cpio.c";
    sha256 = "0i938rf0k0wrvpdghpjm4cb6f6ycz6y5y5lgfnh36cdlsabap71h";
  };
} ''
  mkdir -p $out/bin
  cc $src -o $out/bin/gen_init_cpio
''
