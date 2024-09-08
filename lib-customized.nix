{ lib
, runCommand
}:
{
  # Based on linkFarm in <nixpkgs>/pkgs/build-support/trivial-builders/default.nix
  linkFarmNoEntries = name: entries:
    let
      entries' =
        if (lib.isAttrs entries) then entries
        # We do this foldl to have last-wins semantics in case of repeated entries
        else if (lib.isList entries) then lib.foldl (a: b: a // { "${b.name}" = b.path; }) { } entries
        else throw "linkFarm entries must be either attrs or a list!";

      linkCommands = lib.mapAttrsToList
        (name: path: ''
          mkdir -p "$(dirname ${lib.escapeShellArg "${name}"})"
          ln -s ${lib.escapeShellArg "${path}"} ${lib.escapeShellArg "${name}"}
        '')
        entries';
    in
    runCommand name
      {
        preferLocalBuild = true;
        allowSubstitutes = false;
        passthru = entries';
      } ''
      mkdir -p $out
      cd $out
      ${lib.concatStrings linkCommands}
    '';
}
