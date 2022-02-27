let
    name = "14e3b35e-fb62-416d-95c8-36176656f06e";
    pkgs = import <nixpkgs> {};
    venv = "~/.local/nix-shells/${name}/venv";
    nvenv = "~/.local/nix-shells/${name}/nvenv";
in pkgs.mkShell rec {
    inherit name;
    buildInputs = with pkgs; [ python310 nodejs nodePackages.uglify-js sd ];
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
}
