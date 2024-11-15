let
  name = "deterministic_checkpoints";
  pkgs = import <nixpkgs> {};
  my-python3 = pkgs.python3.withPackages (python-pkgs: [
    # for docs
    python-pkgs.pydot
  ]);
  h_content = builtins.toFile "h_content" ''
    # ${pkgs.lib.toUpper "${name} usage tips"}

    ## Configuration

    * Set SPEC CPU 2006 source code: edit `config.nix`: `spec2006_path = [...]`
    * Set input size: edit `config.nix`: `size = xxx` (default input is ref)
    * Change other configs in `config.nix`

    ## Generation

    * Generate the checkpoints for a given <benchmark> into `result/`:
      * `nom-build -A <benchmark>`
      * `nom-build -A spec2006`         # all spec2006 testcases
      * `nom-build -A spec2006.403_gcc` # only 403_gcc
      * `nom-build -A openblas`
    * Generate the checkpoints for a given <benchmark> into a dedicated <folder>:
      * `nom-build -A <benchmark> -o <folder>`

    ## Documentation

    * Generate html doc into `book/`
      * `make doc`
  '';
  _h_ = pkgs.writeShellScriptBin "h" ''
    ${pkgs.glow}/bin/glow ${h_content}
  '';
in
pkgs.mkShell {
  inherit name;
  packages = [
    _h_
    pkgs.nix-output-monitor
    pkgs.mdbook
    pkgs.graphviz
    my-python3
  ];
  shellHook = ''
    h
  '';
}
