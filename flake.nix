{
  description = "Our tools and settings!";
  nixConfig = {
    # Adapted From: https://github.com/divnix/digga/blob/main/examples/devos/flake.nix#L4
    accept-flake-config = true;
    auto-optimise-store = true;
    builders-use-substitutes = true;
    cores = 0;
    extra-experimental-features = "nix-command flakes";
    extra-substituters =
      "https://cache.nixos.org/ https://nix-community.cachix.org";
    extra-trusted-public-keys =
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
    fallback = true;
    flake-registry =
      "https://raw.githubusercontent.com/sylvorg/bundle/main/flake-registry.json";
    keep-derivations = true;
    keep-outputs = true;
    max-free = 1073741824;
    min-free = 262144000;
    public-keys =
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
    show-trace = true;
    substituters = "https://cache.nixos.org/ https://nix-community.cachix.org";
    trusted-public-keys =
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
    trusted-substituters =
      "https://cache.nixos.org/ https://nix-community.cachix.org";
    warn-dirty = false;
  };
  inputs = rec {

    # Deprecated; circular imports are much too confusing...
    # pyPkg-rich = {
    #   url =
    #     github:syvlorg/rich;
    #   inputs.bundle.follows = "";
    # };
    # pyPkg-oreo = {
    #   url =
    #     git+file:///home/shadowrylander/shadowrylander/sylveon/syvlorg/oreo;
    #   inputs.bundle.follows = "";
    # };
    # pyPkg-pytest-hy = {
    #   url =
    #     git+file:///home/shadowrylander/shadowrylander/sylveon/syvlorg/pytest-hy;
    #   inputs.bundle.follows = "";
    # };

    valiant = {
      url =
        "https://github.com/syvlorg/valiant.git";
      type = "git";
      submodules = true;
    };
    flake-registry.url =
      "git+https://github.com/syvlorg/flake-registry.git";

    emacs.url = "github:nix-community/emacs-overlay";
    nix.url = "github:nixos/nix";
    nur.url = "github:nix-community/nur";
    node2nix = {
      url = "github:svanderburg/node2nix";
      flake = false;
    };

    flake-utils.url = "github:numtide/flake-utils";
    flake-utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    nixos-21-11-small.url = "github:NixOS/nixpkgs/nixos-21.11-small";
    nixos-21-11.url = "github:NixOS/nixpkgs/nixos-21.11";
    nixos-22-05-small.url = "github:NixOS/nixpkgs/nixos-22.05-small";
    nixos-22-05.url = "github:NixOS/nixpkgs/nixos-22.05";
    nixos-22-11-small.url = "github:NixOS/nixpkgs/nixos-22.11-small";
    nixos-22-11.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixos-23-05-small.url = "github:NixOS/nixpkgs/nixos-23.05-small";
    nixos-23-05.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixos-master.url = "github:nixos/nixpkgs";
    nixos-unstable-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    nixos-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.follows = "valiant/nixpkgs";

    a = {
      url = "github:plexus/a.el";
      flake = false;
    };
    dash = {
      url = "github:magnars/dash.el";
      flake = false;
    };
    f = {
      url = "github:syvlorg/f.el/f-presence";
      flake = false;
    };
    s = {
      url = "github:magnars/s.el";
      flake = false;
    };
    uuidgen = {
      url = "github:syvlorg/uuidgen-el";
      flake = false;
    };
    htmlize = {
      url = "github:hniksic/emacs-htmlize";
      flake = false;
    };

    # ... this one's okay though; it's not being used as a package here.
    riot = {
      url = "github:syvlorg/riot";
      inputs.bundle.follows = "";
      inputs.valiant.follows = "valiant";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-mode.url = "github:syvlorg/nix-mode";
    ob-hy = {
      url = "github:allison-casey/ob-hy";
      flake = false;
    };
    sysget = {
      url = "github:emilengler/sysget/v2.3";
      flake = false;
    };
    pacapt = {
      url = "github:icy/pacapt/v3.0.7";
      flake = false;
    };
    backtrace = {
      url = "github:nir0s/backtrace";
      flake = false;
    };
    mdsh = {
      url = "github:bashup/mdsh/7e7af618a341eebd50e7825b062bc192079ad5fc";
      flake = false;
    };
    maid = {
      url = "github:egoist/maid/v0.3.0";
      flake = false;
    };
    gomod2nix.url = "github:nix-community/gomod2nix";
    saku = {
      url = "github:kt3k/saku/v1.2.4";
      flake = false;
    };
    uglifycss = {
      url = "https://registry.npmjs.org/uglifycss/-/uglifycss-0.0.29.tgz";
      flake = false;
    };
    caddy = {
      url = "github:caddyserver/caddy/v2.5.1";
      flake = false;
    };
    org = {
      url = "github:bzg/org-mode";
      flake = false;
    };
    org-contrib = {
      url = "github:emacsmirror/org-contrib";
      flake = false;
    };
    emacswiki = {
      url = "github:emacsmirror/emacswiki.org/master";
      flake = false;
    };
    vlfi = {
      url = "github:m00natic/vlfi";
      flake = false;
    };
    oreo-cursors = {
      url = "github:varlesh/oreo-cursors";
      flake = false;
    };
    xero-figlet-fonts = {
      url = "github:xero/figlet-fonts";
      flake = false;
    };

    # Adapted From: https://github.com/NixOS/nix/issues/4423#issuecomment-1262247071
    flk = {
      url = "https://github.com/chr15m/flk";
      flake = false;
      type = "git";
      submodules = true;
    };
  };
  outputs = inputs@{ self, ... }:
    with builtins;
    let
      pname = "bundle";
      lib = inputs.valiant.lib.iron.extendIron inputs.valiant.lib
        (lfinal: lprev: lself: lsuper:
          lprev.iron.fold.merge [
            {
              mkPkg = mapAttrs (pname: v:
                args@{ ... }:
                final:
                lself.callPackageFilter final.callPackage v
                (args // { inherit pname; }))
                (with lfinal; filterAttrs (n: isFunction) self.callPackages);
              mkPkgOverlay = mapAttrs (pname: v: name:
                args@{ ... }:
                final: prev: {
                  ${name} = v args final;
                }) lfinal.iron.mkPkg;
              functors = {
                xelf = { __functor = self: x: let xelf = x self; in x xelf; };
                xelfDefault = {
                  __functor = self: x:
                    let
                      xelf = x self;
                      default = { c = 3; };
                    in x (xelf // default);
                };
                xelfDefaultOutput = {
                  __functor = self: x:
                    let
                      xelf = x self;
                      default = { c = 3; };
                    in (x (xelf // default)) // default;
                };
                xelfDefaultFunctionOutput = {
                  __functor = self: x:
                    let
                      xelf = x self;
                      default = { c = 3; };
                      xefault = {
                        xa = xelf.a;
                        xb = xelf.b;
                      };
                    in (x (xelf // default)) // default // xefault;
                };
                xelfDefaultUserFunctionOutput = {
                  __functor = self: x:
                    let
                      xelf = x self;
                      default = { c = 3; };
                      xefault = {
                        xa = xelf.a;
                        xb = xelf.b;
                      };
                    in (x (xelf // default // xefault)) // default // xefault;
                };
              };
            }
            (import ./lib inputs lfinal pname)
          ]);
    in import ./outputs self inputs lib pname;
}
