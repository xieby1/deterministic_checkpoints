let
  name = "deterministic_checkpoints";
  pkgs = import <nixpkgs> {};
  h_content = builtins.toFile "h_content" ''
    # ${pkgs.lib.toUpper "${name} usage tips"}

    * Set SPEC CPU 2006 source code: edit `spec2006/default.nix`: `srcs = [...]`
    * Set input size: edit `spec2006/default.nix`: `size = xxx` (default input is ref)
    * Generate the checkpoints of all testCases into `result/`: `nom-build -A checkpoints`
    * Generate the checkpoints of a specific <testCase> into `result/`: `nom-build -A 'checkpoints."<testCase>"'`
      * E.g.: `nom-build -A 'checkpoints."403.gcc"'`
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
  ];
  shellHook = ''
    h
  '';
}
