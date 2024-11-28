# Usage:
#   1. build service: `nix-build runner-service.nix --argstr spec2006src <SPEC2006SRC> --argstr github_token <GITHUB_TOKEN>`
#     * The GitHub token (valid for 366 days, limited by OpenXiangShan) is needed to
#       retrieve the runner token (only valid for one hour, limited by GitHub).
#       https://docs.github.com/en/rest/actions/self-hosted-runners?apiVersion=2022-11-28#create-a-registration-token-for-a-repository
#       > The fine-grained token must have the following permission set:
#       > "Administration" repository permissions (write)
#     * Generate the github token here:
#       https://github.com/settings/tokens?type=beta
#   2. Copy generate file `result` to ~/.config/systemd/user/${name}.service
#   3. Start this service: `systemctl --user start ${name}.service
#   *. Inspect the status of this service: `systemctl --user status ${name}.service`
#   *. Inspect the output of this service: `journalctl --user -f -u ${name}.service`
{ pkgs ? import <nixpkgs> {}
, spec2006src
, github_token
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
  run = pkgs.writeShellScript "run" ''
    resp=$(curl -L \
      -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer ${github_token}" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      Https://api.github.com/repos/OpenXiangShan/Deterload/actions/runners/registration-token)
    # https://unix.stackexchange.com/questions/13466/can-grep-output-only-specified-groupings-that-match
    runner_token=$(echo $resp | grep -oP '"token":\s*"\K[^"]*')
    ${runner}/bin/github-runner-nix \
      --labels 'self-hosted,Linux,X64,nix' \
      --ephemeral \
      --url https://github.com/OpenXiangShan/Deterload \
      --token $runner_token
  '';
in pkgs.writeTextFile {
  name = "${name}.service";
  text = ''
    [Install]
    WantedBy=default.target

    [Service]
    ExecStart=${run}
    Restart=always

    [Unit]
    After=network.target
    Description=Auto start ${name}
  '';
}
