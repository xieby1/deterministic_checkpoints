let
  name = "init.cpio";
  pkgs = import <nixpkgs> {};
  gen_init_cpio = import ./gen_init_cpio;
  cpio_list = pkgs.writeText "cpio_list" ''
    dir /bin          755 0 0
    dir /etc          755 0 0
    dir /dev          755 0 0
    dir /lib          755 0 0
    dir /proc         755 0 0
    dir /sbin         755 0 0
    dir /sys          755 0 0
    dir /tmp          755 0 0
    dir /usr          755 0 0
    dir /mnt          755 0 0
    dir /usr/bin      755 0 0
    dir /usr/lib      755 0 0
    dir /usr/sbin     755 0 0
    dir /var          755 0 0
    dir /var/tmp      755 0 0
    dir /root         755 0 0
    dir /var/log      755 0 0

    nod /dev/console  644 0 0 c 5 1
    nod /dev/null     644 0 0 c 1 3
  '';
in pkgs.runCommand name {} ''
  mkdir -p $out
  ${gen_init_cpio}/bin/gen_init_cpio ${cpio_list} > $out/${name}
''
