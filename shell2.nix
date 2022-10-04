with (import ./.).pkgs.${builtins.currentSystem}; Pythons.hy.withPackages (ppkgs: [ ppkgs.addict ])
