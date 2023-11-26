flake: inputs: lib:
with lib;
self: {
  node = iron.fold.set [
    (map (pkg: mapAttrs iron.update.${pkg}.${pkg} flake.callPackageset.${pkg}) [
      "node"
      "yarn"
    ])
  ];
  emacs = let update = iron.update.emacs.package;
  in iron.fold.set [
    (mapAttrs (pname: pkg: final: prev:
      iron.update.emacs.callEmacs { } pname pkg final prev)
      flake.callPackageset.emacs)
    (genAttrs [ "nix-mode" "ob-hy" ] (pname: final: prev:
      update pname (old: { src = inputs.${pname}; }) final prev))
  ];
  overlays = {
    oreo-custom-cursors = iron.mkPkgOverlay.oreo-cursors "oreo-custom-cursors" {
      colors.dracula_orange.color = "#ffb86c";
    };
    gum = final: prev: {
      ${
        if ((elem prev.stdenv.targetPlatform.system
          (attrNames inputs.nixos-master.legacyPackages))
          || (elem "gum" (attrNames prev))) then
          "gum"
        else
          null
      } =
        prev.gum or inputs.nixos-master.legacyPackages.${final.stdenv.targetPlatform.system}.gum;
    };
    nodeEnv = final: prev: {
      nodeEnv = final.callPackage "${inputs.node2nix}/nix/node-env.nix" { };
    };

    # When the `sandbox' is disabled, other `go' builds will fail if this is enabled:
    # https://discourse.nixos.org/t/your-go-build/20689
    systemd = final: prev: {
      systemd = prev.systemd.overrideAttrs (old: { withHomed = true; });
    };

    emacs-overlays = inputs.emacs.overlay;
    gomod2nix = inputs.gomod2nix.overlays.default;
    nur = final: prev: {
      nur = import inputs.nur {
        nurpkgs = inputs.nixpkgs;
        pkgs = final;
      };
    };
    # nix = inputs.nix.overlay;
    nix-direnv = final: prev: {
      nix-direnv = prev.nix-direnv.override { enableFlakes = true; };
    };
  };
}
