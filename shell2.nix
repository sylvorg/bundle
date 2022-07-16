with builtins; with import <nixos> {}; with lib; let
    flake = (builtins.getFlake or import) (toString ./.);
    lockfile = fromJSON (readFile ./flake.lock);
    inputs = (makeExtensible (_: flake.inputs)).extend (final: prev: recursiveUpdate prev (mapAttrs (n: v: v.locked // v.original) lockfile.nodes));
in mkShell {
    shellHook = ''
        ${trace inputs.hy ":"}
        exit
    '';
}
