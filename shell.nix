with builtins; let
    flake = if (builtins ? getFlake) then (getFlake github:syvlorg/thanos) else (import fetchTarball (let
        lockExists = pathExists ./flake.lock;
        lock = if lockExists then (fromJSON (readFile ./flake.lock)) else { nodes.thanos.locked.rev = "main"; };
    in {
        url = "https://github.com/syvlorg/thanos/archive/${lock.nodes.thanos.locked.rev}.tar.gz";
        ${if lockExists then "sha256" else null} = lock.nodes.thanos.locked.narHash;
    }) { src = ./.; }).defaultNix;
    inherit (flake.${currentSystem}) pkgs;
in with pkgs; mkShell rec {
    buildInputs = [ thanos ];
    nativeBuildInputs = buildInputs;
}
