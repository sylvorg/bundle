let
    name = "20220208045252543083715";
    pkgs = import <nixpkgs> {};
    venv = "~/.local/nix-shells/${name}/venv";
    nvenv = "~/.local/nix-shells/${name}/nvenv";
in (pkgs.mkShell rec {
    inherit name;
    buildInputs = with pkgs; [ python310 nodejs nodePackages.uglify-js python310 sd ];
    nativeBuildInputs = buildInputs;
    shellHook = ''
        python3 -m venv ${venv}
        source ${venv}/bin/activate
        pip install --upgrade pip || :
        pip install nodeenv xonsh || :
        nodeenv ${nvenv}
        source ${nvenv}/bin/activate
        npm audit fix --force
        npm install command uglifycss
        exec xonsh
    '';
})
