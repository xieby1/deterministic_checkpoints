# build example: `nix-build runner-service.nix --argstr spec2006src /nfs/share/home/spec2006.tar.gz`
{ pkgs ? import <nixpkgs> {}
, spec2006src
}: let
  name = "runner-deterload";
  runner = import (pkgs.fetchFromGitHub {
    owner = "xieby1";
    repo = "nix_config";
    rev = "402ff6218615ca8ee61dc9a5e9147d1504fd8919";
    hash = "sha256-AEUkkkcj6has+1RD7eFvRsH6gZB5PzYjU8Dn/30LDqA=";
  } + "/scripts/pkgs/github-runner.nix") {
    inherit pkgs;
    podmanExtraOpts = ["-v ${spec2006src}:${spec2006src}:ro"];
  };
in pkgs.writeTextFile {
  name = "${name}.service";
  text = ''
    # Usage:
    #   1. Copy this file to ~/.config/systemd/user/${name}.service
    #   2. Replace [token](https://github.com/OpenXiangShan/Deterload/settings/actions/runners/new) below
    #   3. Start this service: `systemctl --user start ${name}.service
    #   *. Inspect the status of this service: `systemctl --user status ${name}.service`
    #   *. Inspect the output of this service: `journalctl --user -f -u ${name}.service`

    [Install]
    WantedBy=default.target

    [Service]
    ExecStart=${runner}/bin/github-runner-nix --labels 'self-hosted,Linux,X64,nix' --ephemeral --url https://github.com/OpenXiangShan/Deterload --token <REPLACE_YOUR_TOKEN_HERE>
    Restart=always

    [Unit]
    After=network.target
    Description=Auto start ${name}
  '';
}
