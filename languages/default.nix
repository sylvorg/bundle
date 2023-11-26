inputs: lib:
with builtins;
with lib;
mapAttrs'
(n: v: nameValuePair (removeSuffix ".nix" n) (import "${./.}/${n}" inputs lib))
(filterAttrs (n: v: !(elem n [ "default.nix" ])) (readDir ./.))
