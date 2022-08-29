with builtins; with import ./.; with pkgs.${currentSystem}; with lib; let
    shellPackages.saku = { buildGoApplication, pname }: buildGoApplication rec {
        inherit pname;
        inherit (Inputs.${pname}) version;
        src = inputs.${pname};
        modules = "${toString ./.}/callPackages/go/${pname}/gomod2nix.toml";
    };
    sakuNames = attrNames saku;
    pSakuNames = attrNames pkgs.saku;
    intersection = intersectLists sakuNames pSakuNames;
    subtraction = { saku = subtractLists intersection sakuNames; pkgs.saku = subtractLists intersection pSakuNames; };
# in mkShell { buildInputs = mapAttrsToList (pname: v: callPackage v { inherit pname; }) shellPackages; }
in mkShell { buildInputs = toList pkgs.saku; }
