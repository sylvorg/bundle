with builtins; with import <nixos> {}; with lib; let
    flake = import ./.;
in mkShell {
    shellHook = ''
        ${trace flake ":"}
        exit
    '';
}
