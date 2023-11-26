linputs: lib: currentLanguage:
with builtins;
with lib;
plus@{ self, inputs, pname

# These have to be explicitly inherited in the output,
# as they may not be provided by the end user
, type ? iron.attrs.versions.emacs, doCheck ? true, callPackageset ? { }

, ... }:
args@{ emacsOverlays ? { }, ... }:
let
  inherit (iron) fold;
  gottenCallPackage = iron.getCallPackage plus args;
  inherit (gottenCallPackage) callPackage;
  inheritance = iron.filterInheritance callPackage
    (gottenCallPackage.inheritance // (args.inheritance or { }));
  default = iron.mifNotNull.default (iron.getOverlay plus args) (final: prev:
    iron.update.emacs.callEmacs inheritance pname callPackage final prev);
  systemOutputs = pkgs: {
    packages =
      linputs.flake-utils.lib.filterPackages pkgs.stdenv.targetPlatform.system
      (iron.mkPackages self.overlayset.emacs pkgs.emacsen pname false type
        currentLanguage);
  };
in {
  plus = fold.merge [
    (if (args.mkFlake or false) then {
      outputsBuilder = channels:
        systemOutputs channels.${plus.channel or "nixpkgs"};
    } else
      (linputs.flake-utils.lib.eachSystem
        (args.supportedSystems or linputs.flake-utils-plus.lib.defaultSystems)
        (system: systemOutputs self.pkgs.${system})))
    (optionalAttrs currentLanguage { inherit type doCheck callPackageset; })
    {
      ${iron.mif.null currentLanguage "overlay"} = default;
      overlayset.emacs = fold.set [
        (optionalAttrs currentLanguage { "${pname}-lib" = default; })
        (iron.genLibs (n: v: final: prev:
          let cpkg = v.package or v;
          in iron.update.emacs.callEmacs (fold.set [
            { pname = n; }
            (args.inheritance or { })
            (v.inheritance or { })
          ]) n cpkg final prev) (callPackageset.emacs or { }))
        emacsOverlays
      ];
    }
    plus
  ];
  inherit args;
}
