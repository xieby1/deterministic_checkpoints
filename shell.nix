let
  name = "deterministic_checkpoints";
  pkgs = import <nixpkgs> {};
  h_content = builtins.toFile "h_content" ''
    # ${pkgs.lib.toUpper "${name} usage tips"}

    * Set SPEC CPU 2006 source code: edit `spec2006/default.nix`: `srcs = [...]`
    * Set input size: edit `spec2006/default.nix`: `size = xxx` (default input is ref)
    * Generate SPEC CPU 2006 checkpoint into `result/`: `nom-build`
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
