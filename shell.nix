with builtins; let
    flake = if (builtins ? getFlake) then (getFlake github:syvlorg/titan) else (import fetchTarball (let
        lockExists = pathExists ./flake.lock;
        lock = if lockExists then (fromJSON (readFile ./flake.lock)) else { nodes.titan.locked.rev = "main"; };
    in {
        url = "https://github.com/syvlorg/titan/archive/${lock.nodes.titan.locked.rev}.tar.gz";
        ${if lockExists then "sha256" else null} = lock.nodes.titan.locked.narHash;
    }) { src = ./.; }).defaultNix;
    inherit (flake.${currentSystem}) pkgs;
in with pkgs; mkShell rec {
    buildInputs = [ titan ];
    nativeBuildInputs = buildInputs;
}
