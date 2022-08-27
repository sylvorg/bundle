{ description = "Our tools and settings!";
    nixConfig = {
        # Adapted From: https://github.com/divnix/digga/blob/main/examples/devos/flake.nix#L4
        # extra-substituters = "https://cache.nixos.org/ https://nix-community.cachix.org/";
        trusted-substituters = "https://cache.nixos.org/";
        # extra-trusted-public-keys = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
        trusted-public-keys = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
        # keep-derivations = true;
        # keep-outputs = true;
        extra-experimental-features = "nix-command flakes";
        # accept-flake-config = true;
        # show-trace = true;
        # fallback = true;
        # auto-optimise-store = true;
        # builders-use-substitutes = true;
        # cores = 0;
        # flake-registry = https://raw.githubusercontent.com/sylvorg/settings/main/flake-registry.json;
        # allow-unsafe-native-code-during-evaluation = true;
        # min-free = 262144000;
        # max-free = 1073741824;
    };
    inputs = rec {
        emacs.url = github:nix-community/emacs-overlay;
        nix.url = github:nixos/nix;
        nur.url = github:nix-community/nur;
        node2nix = {
            url = github:svanderburg/node2nix;
            flake = false;
        };

        flake-utils.url = github:numtide/flake-utils;
        flake-compat = {
            url = github:edolstra/flake-compat;
            flake = false;
        };

        nixos-21-11-small.url = github:NixOS/nixpkgs/nixos-21.11-small;
        nixos-21-11.url = github:NixOS/nixpkgs/nixos-21.11;
        nixos-22-05-small.url = github:NixOS/nixpkgs/nixos-22.05-small;
        nixos-22-05.url = github:NixOS/nixpkgs/nixos-22.05;
        nixos-master.url = github:NixOS/nixpkgs/master;
        nixos-unstable-small.url = github:NixOS/nixpkgs/nixos-unstable-small;
        nixos-unstable.url = github:NixOS/nixpkgs/nixos-unstable;
        nixpkgs.url = github:NixOS/nixpkgs/nixos-22.05;
        hy = {
            url = github:hylang/hy/035383d11b44a1731aa6c70735fa4c709979ccdb;
            flake = false;
        };
        hyrule = {
            url = github:hylang/hyrule/0.2;
            flake = false;
        };
        sysget = {
            url = github:emilengler/sysget/v2.3;
            flake = false;
        };
        pacapt = {
            url = github:icy/pacapt/v3.0.7;
            flake = false;
        };
        autoslot = {
            url = github:cjrh/autoslot/v2021.10.1;
            flake = false;
        };
        magicattr = {
            url = github:frmdstryr/magicattr;
            flake = false;
        };
        backtrace = {
            url = github:nir0s/backtrace;
            flake = false;
        };
        mdsh = {
            url = github:bashup/mdsh/7e7af618a341eebd50e7825b062bc192079ad5fc;
            flake = false;
        };
        maid = {
            url = github:egoist/maid/v0.3.0;
            flake = false;
        };
        caddy = {
            url = github:caddyserver/caddy/v2.5.1;
            flake = false;
        };
        poetry2setup = {
            url = github:abersheeran/poetry2setup;
            flake = false;
        };
        pytest-reverse = {
            url = github:adamchainz/pytest-reverse/1.5.0;
            flake = false;
        };
        pytest-parametrized = {
            url = github:coady/pytest-parametrized/v1.3;
            flake = false;
        };
        pytest-custom_exit_code = {
            url = github:yashtodi94/pytest-custom_exit_code/0.3.0;
            flake = false;
        };
    };
    outputs = inputs@{ self, flake-utils, ... }: with builtins; with flake-utils.lib; let
        lockfile = fromJSON (readFile ./flake.lock);
        channel = "nixos-22-05";
        registry = fromJSON ''
{
  "flakes": [
    {
      "from": {
        "id": "shadowrylander",
        "type": "indirect"
      },
      "to": {
        "owner": "shadowrylander",
        "repo": "shadowrylander",
        "type": "github"
      }
    },
    {
      "from": {
        "id": "settings",
        "type": "indirect"
      },
      "to": {
        "owner": "sylvorg",
        "repo": "settings",
        "type": "github"
      }
    }
  ],
  "version": 2
}
        '';
        J = with inputs.nixpkgs.lib; {
            patch = {
                nixpkgs = let
                    patches' = with patches; [ bcachefs-module ];
                in {
                    default = src: config: (import src config).applyPatches {
                        name = "defaultPatches";
                        inherit src;
                        patches = patches';
                    };
                    extras = src: config: patches: (import src config).applyPatches { name = "extraPatches"; inherit src patches; };
                    both = src: config: patches: (import src config).applyPatches {
                        name = "bothPatches";
                        inherit src;
                        patches = patches' ++ patches;
                    };
                };
                pkgs = {
                    default = src: config: import (J.patch.nixpkgs.default src config) config;
                    extras = src: config: patches: import (J.patch.nixpkgs.extras src config patches) config;
                };
            };
            foldToSet = list: foldr (new: old: new // old) {} (flatten list);
            foldToSet' = list: foldr (new: old: recursiveUpdate new old) {} (flatten list);
            fpipe = pipe-list: flip pipe (flatten pipe-list);
            remove = let
                sortFunc = sort (a: b: (length a) > (length b));
            in rec {
                default = func: fixes: J.fpipe (map func (sortFunc fixes));
                prefix = default removePrefix;
                suffix = default removeSuffix;
                infix = fixes: replaceStrings (sortFunc fixes) (genList (i: "") (length fixes));
            };
            extendInputs = inputs': lockfile': (makeExtensible (_: inputs')).extend (final: prev: recursiveUpdate prev (mapAttrs (n: v: let
                vo = v.original or { ref = null; };
                vl = v.locked or { rev = null; };
            in J.foldToSet [
                vl
                vo
                { version = if (vo ? ref) then (J.remove.prefix [ "v" ] vo.ref) else vl.rev; }
            ]) lockfile'.nodes));
        };
        Inputs = J.extendInputs inputs lockfile;
        lib = inputs.nixpkgs.lib.extend (final: prev: { j = with final; makeExtensible (lself: J // (rec {
            genAttrNames = values: f: listToAttrs (map (v: nameValuePair (f v) v) values);
            mapAttrNames = f: mapAttrs' (n: v: nameValuePair (f n v) v);
            mif = {
                list = optionals;
                list' = optional;
                set = optionalAttrs;
                num = condition: value: if condition then value else 0;
                null = condition: value: if condition then value else null;
                str = optionalString;
                True = condition: value: if condition then value else true;
                False = condition: value: if condition then value else false;
            };
            mifNotNull = {
                list = a: optionals (a != null);
                list' = a: optional (a != null);
                set = a: optionalAttrs (a != null);
                num = a: b: if (a != null) then b else 0;
                null = a: b: if (a != null) then b else null;
                str = a: optionalString (a != null);
                True = a: b: if (a != null) then b else true;
                False = a: b: if (a != null) then b else false;
            };
            mapNullId = mapNullable id;
            readDirExists = dir: optionalAttrs (pathExists dir) (readDir dir);
            dirCon = let
                ord = func: dir: filterAttrs func (if (isAttrs dir) then dir else (readDirExists dir));
            in rec {
                attrs = {
                    dirs = ord (n: v: v == "directory");
                    others = ord (n: v: v != "directory");
                    files = ord (n: v: v == "regular");
                    sym = ord (n: v: v == "symlink");
                    unknown = ord (n: v: v == "unknown");
                };
                dirs = dir: attrNames (attrs.dirs dir);
                others = dir: attrNames (attrs.others dir);
                files = dir: attrNames (attrs.files dir);
                sym = dir: attrNames (attrs.sym dir);
                unknown = dir: attrNames (attrs.unknown dir);
            };
            has = {
                prefix = string: any (flip hasPrefix string);
                suffix = string: any (flip hasSuffix string);
                infix = string: any (flip hasInfix string);
            };
            filters = {
                has = {
                    attrs = list: attrs: let
                        l = unique (flatten list);
                    in lself.foldToSet [
                        (filterAttrs (n: v: elem n l) attrs)
                        (genAttrNames (filter isDerivation l) (drv: drv.pname or drv.name))
                    ];
                    list = list: attrs: attrValues (filters.has.attrs list attrs);

                    # Roger, roger!
                    attr-attr = attrs: filterAttrs (n: v: elem n (attrNames attrs));

                };

                keep = {
                    prefix = keeping: attrs: if ((keeping == []) || (keeping == "")) then attrs else (filterAttrs (n: v: has.prefix n (toList keeping)) attrs);
                    suffix = keeping: attrs: if ((keeping == []) || (keeping == "")) then attrs else (filterAttrs (n: v: has.suffix n (toList keeping)) attrs);
                    infix = keeping: attrs: if ((keeping == []) || (keeping == "")) then attrs else (filterAttrs (n: v: has.infix n (toList keeping)) attrs);
                    elem = keeping: attrs: if ((keeping == []) || (keeping == "")) then attrs else (filterAttrs (n: v: elem n (toList keeping)) attrs);
                    inherit (dirCon.attrs) dirs others files sym unknown;
                    readDir = {
                        dirs = {
                            prefix = keeping: attrs: if ((keeping == []) || (keeping == "")) then attrs else (filterAttrs (n: v: if (v == "directory") then (has.prefix n (toList keeping)) else true) attrs);
                            suffix = keeping: attrs: if ((keeping == []) || (keeping == "")) then attrs else (filterAttrs (n: v: if (v == "directory") then (has.suffix n (toList keeping)) else true) attrs);
                            infix = keeping: attrs: if ((keeping == []) || (keeping == "")) then attrs else (filterAttrs (n: v: if (v == "directory") then (has.infix n (toList keeping)) else true) attrs);
                            elem = keeping: attrs: if ((keeping == []) || (keeping == "")) then attrs else (filterAttrs (n: v: if (v == "directory") then (elem n (toList keeping)) else true) attrs);
                        };
                        others = {
                            prefix = keeping: attrs: if ((keeping == []) || (keeping == "")) then attrs else (filterAttrs (n: v: if (v != "directory") then (has.prefix n (toList keeping)) else true) attrs);
                            suffix = keeping: attrs: if ((keeping == []) || (keeping == "")) then attrs else (filterAttrs (n: v: if (v != "directory") then (has.suffix n (toList keeping)) else true) attrs);
                            infix = keeping: attrs: if ((keeping == []) || (keeping == "")) then attrs else (filterAttrs (n: v: if (v != "directory") then (has.infix n (toList keeping)) else true) attrs);
                            elem = keeping: attrs: if ((keeping == []) || (keeping == "")) then attrs else (filterAttrs (n: v: if (v != "directory") then (elem n (toList keeping)) else true) attrs);
                        };
                        files = {
                            prefix = keeping: attrs: if ((keeping == []) || (keeping == "")) then attrs else (filterAttrs (n: v: if (v == "regular") then (has.prefix n (toList keeping)) else true) attrs);
                            suffix = keeping: attrs: if ((keeping == []) || (keeping == "")) then attrs else (filterAttrs (n: v: if (v == "regular") then (has.suffix n (toList keeping)) else true) attrs);
                            infix = keeping: attrs: if ((keeping == []) || (keeping == "")) then attrs else (filterAttrs (n: v: if (v == "regular") then (has.infix n (toList keeping)) else true) attrs);
                            elem = keeping: attrs: if ((keeping == []) || (keeping == "")) then attrs else (filterAttrs (n: v: if (v == "regular") then (elem n (toList keeping)) else true) attrs);
                        };
                        sym = {
                            prefix = keeping: attrs: if ((keeping == []) || (keeping == "")) then attrs else (filterAttrs (n: v: if (v == "symlink") then (has.prefix n (toList keeping)) else true) attrs);
                            suffix = keeping: attrs: if ((keeping == []) || (keeping == "")) then attrs else (filterAttrs (n: v: if (v == "symlink") then (has.suffix n (toList keeping)) else true) attrs);
                            infix = keeping: attrs: if ((keeping == []) || (keeping == "")) then attrs else (filterAttrs (n: v: if (v == "symlink") then (has.infix n (toList keeping)) else true) attrs);
                            elem = keeping: attrs: if ((keeping == []) || (keeping == "")) then attrs else (filterAttrs (n: v: if (v == "symlink") then (elem n (toList keeping)) else true) attrs);
                        };
                        unknown = {
                            prefix = keeping: attrs: if ((keeping == []) || (keeping == "")) then attrs else (filterAttrs (n: v: if (v == "unknown") then (has.prefix n (toList keeping)) else true) attrs);
                            suffix = keeping: attrs: if ((keeping == []) || (keeping == "")) then attrs else (filterAttrs (n: v: if (v == "unknown") then (has.suffix n (toList keeping)) else true) attrs);
                            infix = keeping: attrs: if ((keeping == []) || (keeping == "")) then attrs else (filterAttrs (n: v: if (v == "unknown") then (has.infix n (toList keeping)) else true) attrs);
                            elem = keeping: attrs: if ((keeping == []) || (keeping == "")) then attrs else (filterAttrs (n: v: if (v == "unknown") then (elem n (toList keeping)) else true) attrs);
                        };
                        static = {
                            prefix = keeping: attrs: if ((keeping == []) || (keeping == "")) then attrs else (filterAttrs (n: v: if ((v == "regular") || (v == "unknown")) then (has.prefix n (toList keeping)) else true) attrs);
                            suffix = keeping: attrs: if ((keeping == []) || (keeping == "")) then attrs else (filterAttrs (n: v: if ((v == "regular") || (v == "unknown")) then (has.suffix n (toList keeping)) else true) attrs);
                            infix = keeping: attrs: if ((keeping == []) || (keeping == "")) then attrs else (filterAttrs (n: v: if ((v == "regular") || (v == "unknown")) then (has.infix n (toList keeping)) else true) attrs);
                            elem = keeping: attrs: if ((keeping == []) || (keeping == "")) then attrs else (filterAttrs (n: v: if ((v == "regular") || (v == "unknown")) then (elem n (toList keeping)) else true) attrs);
                        };
                    };
                };
                remove = {
                    prefix = ignores: filterAttrs (n: v: ! (has.prefix n (toList ignores)));
                    suffix = ignores: filterAttrs (n: v: ! (has.suffix n (toList ignores)));
                    infix = ignores: filterAttrs (n: v: ! (has.infix n (toList ignores)));
                    elem = ignores: filterAttrs (n: v: ! (elem n (toList ignores)));
                    dirs = dirCon.attrs.others;
                    files = filterAttrs (n: v: v != "regular");
                    others = dirCon.attrs.dirs;
                    sym = filterAttrs (n: v: v != "symlink");
                    unknown = filterAttrs (n: v: v != "unknown");
                    readDir = {
                        dirs = {
                            prefix = ignores: filterAttrs (n: v: (! (has.prefix n (toList ignores))) && (v == "directory"));
                            suffix = ignores: filterAttrs (n: v: (! (has.suffix n (toList ignores))) && (v == "directory"));
                            infix = ignores: filterAttrs (n: v: (! (has.infix n (toList ignores))) && (v == "directory"));
                            elem = ignores: filterAttrs (n: v: (! (elem n (toList ignores))) && (v == "directory"));
                        };
                        others = {
                            prefix = ignores: filterAttrs (n: v: if (v != "directory") then (! (has.prefix n (toList ignores))) else true);
                            suffix = ignores: filterAttrs (n: v: if (v != "directory") then (! (has.suffix n (toList ignores))) else true);
                            infix = ignores: filterAttrs (n: v: if (v != "directory") then (! (has.infix n (toList ignores))) else true);
                            elem = ignores: filterAttrs (n: v: if (v != "directory") then (! (elem n (toList ignores))) else true);
                        };
                        files = {
                            prefix = ignores: filterAttrs (n: v: if (v == "regular") then (! (has.prefix n (toList ignores))) else true);
                            suffix = ignores: filterAttrs (n: v: if (v == "regular") then (! (has.suffix n (toList ignores))) else true);
                            infix = ignores: filterAttrs (n: v: if (v == "regular") then (! (has.infix n (toList ignores))) else true);
                            elem = ignores: filterAttrs (n: v: if (v == "regular") then (! (elem n (toList ignores))) else true);
                        };
                        sym = {
                            prefix = ignores: filterAttrs (n: v: if (v == "symlink") then (! (has.prefix n (toList ignores))) else true);
                            suffix = ignores: filterAttrs (n: v: if (v == "symlink") then (! (has.suffix n (toList ignores))) else true);
                            infix = ignores: filterAttrs (n: v: if (v == "symlink") then (! (has.infix n (toList ignores))) else true);
                            elem = ignores: filterAttrs (n: v: if (v == "symlink") then (! (elem n (toList ignores))) else true);
                        };
                        unknown = {
                            prefix = ignores: filterAttrs (n: v: if (v == "unknown") then (! (has.prefix n (toList ignores))) else true);
                            suffix = ignores: filterAttrs (n: v: if (v == "unknown") then (! (has.suffix n (toList ignores))) else true);
                            infix = ignores: filterAttrs (n: v: if (v == "unknown") then (! (has.infix n (toList ignores))) else true);
                            elem = ignores: filterAttrs (n: v: if (v == "unknown") then (! (elem n (toList ignores))) else true);
                        };
                        static = {
                            prefix = keeping: filterAttrs (n: v: if ((v == "regular") || (v == "unknown")) then (! (has.prefix n (toList keeping))) else true);
                            suffix = keeping: filterAttrs (n: v: if ((v == "regular") || (v == "unknown")) then (! (has.suffix n (toList keeping))) else true);
                            infix = keeping: filterAttrs (n: v: if ((v == "regular") || (v == "unknown")) then (! (has.infix n (toList keeping))) else true);
                            elem = keeping: filterAttrs (n: v: if ((v == "regular") || (v == "unknown")) then (! (elem n (toList keeping))) else true);
                        };
                    };
                };
            };
            imports = rec {
                name = {
                    file,
                    suffix ? ".nix",
                }: let
                    base-file = baseNameOf (toString file);
                in if (isInt suffix) then (let
                    hidden = hasPrefix "." base-file;
                    split-file = remove "" (splitString "." base-file);
                in if (hidden && ((length split-file) == 1)) then base-file
                else concatStringsSep "." (take ((length split-file) - suffix) split-file)) else (removeSuffix suffix base-file);
                list = args@{
                    dir,
                    idir ? dir,
                    ignores ? {},
                    iter ? 0,
                    keep ? false,
                    keeping ? {},
                    local ? false,
                    file ? { prefix = { pre = ""; post = ""; }; suffix = ""; },
                    recursive ? false,
                    root ? false,
                    names ? false,
                    suffix ? ".nix",
                }: let
                    func = dir: let
                        stringDir = toString dir;
                        stringyDir = toString idir;
                        fk = filters.keep;
                        fr = filters.remove;
                        pre-orders = flatten [
                            (optional (keeping.files or false) fk.files)
                            (optional (keeping.unknown or false) fk.unknown)
                            (fk.prefix (keeping.prefix or []))
                            (fk.infix (keeping.infix or []))
                            (fk.readDir.files.suffix (keeping.suffix or []))
                            (fk.readDir.files.elem (keeping.elem or []))
                            (fk.readDir.unknown.suffix (keeping.suffix or []))
                            (fk.readDir.unknown.elem (keeping.elem or []))
                            (fk.readDir.static.suffix (keeping.suffix or []))
                            (fk.readDir.static.elem (keeping.elem or []))
                            (optional (ignores.files or false) fr.files)
                            (optional (ignores.unknown or false) fr.unknown)
                            (fr.prefix (ignores.prefix or []))
                            (fr.infix (ignores.infix or []))
                            (fr.readDir.files.suffix (ignores.suffix or []))
                            (fr.readDir.files.elem (ignores.elem or []))
                            (fr.readDir.unknown.suffix (ignores.suffix or []))
                            (fr.readDir.unknown.elem (ignores.elem or []))
                            (fr.readDir.static.suffix (ignores.suffix or []))
                            (fr.readDir.static.elem (ignores.elem or []))
                        ];
                        orders = flatten [
                            (optional (keeping.dirs or false) fk.dirs)
                            (optional (keeping.others or false) fk.others)
                            (optional (keeping.sym or false) fk.sym)
                            (fk.suffix (keeping.suffix or []))
                            (fk.elem (keeping.elem or []))
                            (optional (ignores.dirs or false) fr.dirs)
                            (optional (ignores.others or false) fr.others)
                            (optional (ignores.sym or false) fr.sym)
                            (fr.suffix (ignores.suffix or []))
                            (fr.elem (ignores.elem or []))
                        ];
                        pipe-list = flatten [
                            (mapAttrNames (n: v: pipe "${removePrefix stringyDir stringDir}/${n}" [
                                (splitString "/")
                                (remove "")
                                (concatStringsSep "/")
                            ]))
                            pre-orders
                        ];
                        items = let
                            filtered-others = lself.fpipe pipe-list (dirCon.attrs.others dir);
                            filtered-dirs = lself.fpipe [
                                pipe-list
                                (optionals recursive (mapAttrsToList (n: v: list (args // { dir = "${stringyDir}/${n}"; inherit idir; iter = iter + 1; }))))
                            ] (dirCon.attrs.dirs dir);
                        in lself.foldToSet [ filtered-others filtered-dirs ];
                        process = lself.fpipe [
                            pipe-list
                            orders
                            (if names then (mapAttrNames (file: v: name { inherit suffix file; })) else [
                                (mapAttrNames (n: v: (file.prefix.pre or "") + n))
                                (mapAttrNames (n: v: if keep then n
                                                    else if local then "./${n}"
                                                    else if root then "/${n}"
                                                    else "${stringDir}/${n}"))
                                (mapAttrNames (n: v: (file.prefix.post or "") + n + (file.suffix or "")))
                            ])
                            attrNames
                        ];
                    in if (iter == 0) then (process items) else items;
                in flatten (map func (toList dir));
                set = args@{
                    call ? null,
                    dir,
                    extrargs ? {},
                    suffix ? ".nix",
                    files ? false,
                    ...
                }: listToAttrs (map (file: nameValuePair
                    (name { inherit file suffix; })
                    (if files then file
                    else if (call != null) then (call.callPackage file extrargs)
                    else if (extrargs == {}) then (import file)
                    else (import file extrargs))
                ) (list (filterAttrs (n: v: ! (elem n [ "call" "extrargs" "files" ])) args)));
                overlaySet = args@{
                    call ? null,
                    dir,
                    extrargs ? {},
                    func ? null,
                    suffix ? ".nix",
                    ...
                }: listToAttrs (map (file: let
                    filename = name { inherit file suffix; };
                in nameValuePair
                    filename
                    (if (func != null) then (func file)
                    else if ((isInt call) && (call == 1)) then (final: prev: { "${filename}" = final.callPackage file extrargs; })
                    else if ((isInt call) && (call == 0)) then (final: prev: { "${filename}" = prev.callPackage file extrargs; })
                    else if (call != null) then (final: prev: { "${filename}" = call.callPackage file extrargs; })
                    else if (extrargs == {}) then (import file)
                    else (import file extrargs))
                ) (list (filterAttrs (n: v: ! (elem n [ "call" "extrargs" "func" ])) (recursiveUpdate args { ignores.dirs = true; }))));
            };
            update = {
                python = {
                    python = rec {
                        default = pv: pattrs: prev: { "${pv}" = prev.${pv}.override (super: {
                            packageOverrides = composeExtensions (super.packageOverrides or (_: _: {})) (new: old: pattrs);
                        }); };
                        python2 = default attrs.versions.python.python2;
                        python3 = default attrs.versions.python.python3;
                        python = python3;
                        hy = python3;
                        xonsh = python3;
                    };
                    callPython = rec {
                        default = pv: extrargs: name: pkg: final: update.python.python.default pv { "${name}" = final.${pv}.pkgs.callPackage pkg extrargs; };
                        python2 = default attrs.versions.python.python2;
                        python3 = default attrs.versions.python.python3;
                        python = python3;
                        hy = python3;
                        xonsh = python3;
                    };
                    callPython' = rec {
                        default = pv: extrargs: file: final: update.python.python.default pv { "${imports.name { inherit file; }}" = final.${pv}.pkgs.callPackage file extrargs; };
                        python2 = default attrs.versions.python.python2;
                        python3 = default attrs.versions.python.python3;
                        python = python3;
                        hy = python3;
                        xonsh = python3;
                    };
                    package = rec {
                        default = pv: pkg: func: prev: update.python.python.default pv { "${pkg}" = prev.${pv}.pkgs.${pkg}.overridePythonAttrs func; } prev;
                        python2 = default attrs.versions.python.python2;
                        python3 = default attrs.versions.python.python3;
                        python = python3;
                        hy = python3;
                        xonsh = python3;
                    };
                    packages = rec {
                        default = pv: dir: final: update.python.python.default pv (imports.set { call = final.${pv}.pkgs; inherit dir; ignores.elem = dirCon.dirs dir; });
                        python2 = default attrs.versions.python.python2;
                        python3 = default attrs.versions.python.python3;
                        python = python3;
                        hy = python3;
                        xonsh = python3;
                    };
                };
                node = {
                    default = pkg: final: prev: {
                        nodePackages = fix (extends (node-final: node-prev: recursiveUpdate node-prev (final.callPackage pkg {})) (new: prev.nodePackages));
                    };
                    yarn = name: pkg: final: prev: {
                        nodePackages = fix (extends (node-final: node-prev: recursiveUpdate node-prev {
                            "${name}" = final.callPackage pkg { inherit name; };
                        }) (new: prev.nodePackages));
                    };
                };
            };
            multiSplitString = splits: string: if splits == [] then string
                                               else (remove "" (flatten (map (multiSplitString (init splits)) (splitString (last splits) string))));
            pyVersion' = format: string: if (format == "pyproject") then (fromTOML string).tool.poetry.version
                                         else (pipe (splitString "\n" string) [
                                             (filter (line: has.infix line [ "'version':" ''"version":'' "version=" "version =" ]))
                                             head
                                             (multiSplitString [ "'" "\"" ])
                                             naturalSort
                                             head
                                         ]);
            pyVersion = format: src: pyVersion' format (readFile "${src}/${if (format == "pyproject") then "pyproject.toml" else "setup.py"}");
            pyVersionSrc = src: pyVersion (if (elem "pyproject.toml" (dirCon.others src)) then "pyproject" else "setuptools") src;
            foldToShell = pkgs: envs: foldr (new: old: pkgs.mkShell {
                buildInputs = filters.has.list [ new.buildInputs old.buildInputs ] pkgs;
                nativeBuildInputs = filters.has.list [ new.nativeBuildInputs old.nativeBuildInputs ] pkgs;
                propagatedBuildInputs = filters.has.list [ new.propagatedBuildInputs old.propagatedBuildInputs ] pkgs;
                propagatedNativeBuildInputs = filters.has.list [ new.propagatedNativeBuildInputs old.propagatedNativeBuildInputs ] pkgs;
                shellHook = new.shellHook + "\n" + old.shellHook;
            }) (pkgs.mkShell {}) (filter isDerivation (flatten envs));
            recursiveUpdateAll' = delim: a: b: let
                a-names = attrNames a;
            in (mapAttrs (n: v: if (isAttrs v) then (if (any (attr: (isAttrs attr) || (isList attr) || (isString attr)) (attrValues v))
                                                     then (recursiveUpdateAll' delim v (b.${n} or {}))
                                                     else (v // (b.${n} or {})))
                                else if (isList v) then (v ++ (b.${n} or []))
                                else if (isString v) then (v + delim + (b.${n} or ""))
                                else (b.${n} or v)) a) // (filterAttrs (n: v: ! (elem n a-names)) b);
            recursiveUpdateAll = recursiveUpdateAll' "\n";
            foldRecursively = attrs: foldr recursiveUpdateAll {} attrs;

            mkPythonPackage = ppkgs: pself: let
                inherit (pself) pname owner;
                toOverride = rec {
                    version = pyVersion format pself.src;
                    format = "pyproject";
                    disabled = pythonOlder "3.9";
                };
                overrideNames = attrNames toOverride;
                pselfOverride = filterAttrs (n: v: elem n overrideNames) pself;
                toRecurse = rec {
                    buildInputs = optional ((pself.format or toOverride.format) == "pyproject") ppkgs.poetry-core;
                    nativeBuildInputs = buildInputs;
                    propagatedNativeBuildInputs = pself.propagatedBuildInputs or [];
                    postCheck = ''
                        PYTHONPATH=${ppkgs.makePythonPath (flatten [ propagatedNativeBuildInputs (pself.propagatedNativeBuildInputs or []) ])}:$PYTHONPATH
                        python -c "import ${concatStringsSep "; import " (flatten [ pname (pself.pythonImportsCheck or []) ])}"
                    '';
                    checkInputs = with ppkgs; flatten [
                        pytestCheckHook
                        (optional (pname != "pytest-hy") pytest-hy)
                        pytest-randomly
                        pytest-parametrized
                        pytest-custom_exit_code
                        pytest-sugar
                    ];
                    pytestFlagsArray = toList "--suppress-no-test-exit-code";
                };
                recursiveNames = attrNames toOverride;
                pselfRecursed = filterAttrs (n: v: elem n recursiveNames) pself;
                toOverride' = rec {
                    meta.homepage = "https://github.com/${owner}/${pname}";
                };
                overrideNames' = attrNames toOverride';
                pselfOverride' = filterAttrs (n: v: elem n overrideNames') pself;
            in ppkgs.buildPythonPackage (lself.foldToSet [
                toOverride
                pselfOverride
                (lself.foldToSet' [
                    toOverride'
                    pselfOverride'
                ])
                (foldRecursively [
                    toRecurse
                    pselfRecursed
                ])
                (filterAttrs (n: v: ! (elem n (flatten [ overrideNames recursiveNames overrideNames' "owner" "pythonImportsCheck" ]))) pself)
            ]);
            toPythonApplication = final: prev: ppkgs: extras: pname: args@{ ... }: ppkgs.buildPythonApplication (lself.foldToSet [
                (filterAttrs (n: v: ! ((isDerivation v) || (elem n [
                    "drvAttrs"
                    "override"
                    "overrideAttrs"
                    "overrideDerivation"
                    "overridePythonAttrs"
                ]))) ppkgs.${pname})
                (foldRecursively [
                    (rec {
                        propagatedBuildInputs = toList ppkgs.${pname};
                        propagatedNativeBuildInputs = propagatedBuildInputs;
                        installPhase = ''
                            mkdir --parents $out/bin
                            cp $src/${pname}/${if (pathExists "${ppkgs.${pname}.src}/${pname}/__main__.py") then "__main__.py" else "__init__.py"} $out/bin/${pname}
                            chmod +x $out/bin/${pname}
                        '';
                        postFixup = "wrapProgram $out/bin/${pname} $makeWrapperArgs";
                        makeWrapperArgs = flatten [
                            "--prefix PYTHONPATH : ${ppkgs.makePythonPath propagatedBuildInputs}"
                            (optional (extras.appPathUseBuildInputs or false) "--prefix PATH ${with final; makeBinPath (ppkgs.${pname}.buildInputs or [])}")
                            (optional (extras.appPathUseNativeBuildInputs or false) "--prefix PATH ${with final; makeBinPath (ppkgs.${pname}.nativeBuildInputs or [])}")
                        ];
                    })
                    ((extras.appSettings or (final: prev: {})) final prev)
                ])
            ]);

            baseVersion = head (splitString "p" (concatStringsSep "." (take 2 (splitString "." version))));
            zipToSet = names: values: listToAttrs (
                map (nv: nameValuePair nv.fst nv.snd) (let hasAttrs = any isAttrs values; in zipLists (
                    if hasAttrs then names else (sort lessThan names)
                ) (
                    if hasAttrs then values else (sort lessThan values)
                ))
            );
            toCapital = string: concatImapStrings (
                i: v: if (i == 1) then (toUpper v) else v
            ) (stringToCharacters string);

            # foldr func end list
            sequence = foldr deepSeq;

            inputsToOverlays = {
                python = rec {
                    default = prefix: inputs': let
                        inputs'' = filterAttrs (n: v: hasPrefix prefix n) inputs';
                    in lself.foldToSet [
                        (mapAttrs' (n: v: nameValuePair (removePrefix prefix n) v.overlay) inputs'')
                        (map (v: v.overlays or {}) (attrValues inputs''))
                    ];
                    python2 = default "py2pkg-";
                    python3 = default "py3pkg-";
                    python = python3;
                    hy = python3;
                    xonsh = default "x3pkg";
                };
            };

            isSublist = a: b: all (flip elem b) a;
            allSets = func: set: all (name: func name set.${name}) (attrNames set);
            anySets = func: set: any (name: func name set.${name}) (attrNames set);

            attrs = rec {
                configs = {
                    nixpkgs = {
                        allowUnfree = true;
                        allowBroken = true;
                        allowUnsupportedSystem = true;
                        # preBuild = ''
                        #     makeFlagsArray+=(CFLAGS="-w")
                        #     buildFlagsArray+=(CC=cc)
                        # '';
                        permittedInsecurePackages = [
                            "python2.7-cryptography-2.9.2"
                        ];
                    };
                };
                platforms = {
                    arm = [ "aarch64-linux" "armv7l-linux" "armv6l-linux" ];
                    imd = [ "i686-linux" "x86_64-linux" ];
                };
                versions = {
                    python = rec {
                        python2 = "python27";
                        python3 = "python310";
                        python = python3;
                        hy = python3;
                        xonsh = python3;
                    };
                };
                versionNames = mapAttrs (n: v: let
                    names = attrNames v;
                    sets = [ "inputsToOverlays" ];
                    supersets = [ "update" ];
                    stringsets = concatStringsSep ''" "'' (sets ++ supersets);
                in if ((all (j: allSets (jn: jv: isSublist names (attrNames jv)) lself.${j}.${n}) supersets) &&
                       (all (j: isSublist names (attrNames lself.${j}.${n})) sets)) then names
                   else (throw ''To the developer of the settings module: you missed a "${n}" version somewhere in the following sets: [ "${stringsets}" ]'')) versions;
            };
        })); });
        defaultSystem = "x86_64-linux";
        workingSystems = with lib; subtractLists (flatten [
            (filter (system: hasPrefix "mips" system) allSystems)
            "x86_64-solaris"
        ]) allSystems;
        callPackages = with lib; {
            sysget = { stdenv, installShellFiles, pname }: stdenv.mkDerivation rec {
                inherit pname;
                inherit (Inputs.${pname}) version;
                src = inputs.${pname};
                buildInputs = [ installShellFiles ];
                nativeBuildInputs = buildInputs;
                installPhase = ''
                    mkdir -p $out/bin
                    cp ${pname} $out/bin/
                    installManPage contrib/man/${pname}.8
                    installShellCompletion --bash contrib/${pname}.bash-completion
                '';
                meta = {
                    description = "One package manager to rule them all";
                    homepage = "https://github.com/${Inputs.${pname}.owner}/${pname}";
                    license = licenses.gpl3;
                };
            };
            pacapt = { stdenv, pname }: stdenv.mkDerivation rec {
                inherit pname;
                inherit (Inputs.${pname}) version;
                src = inputs.${pname};
                installPhase = ''
                    mkdir --parents $out/bin
                    cp $src/${pname} $out/bin/
                    chmod 755 $out/bin/*
                '';
                meta = {
                    description = "An ArchLinux's pacman-like shell wrapper for many package managers. 56KB and run anywhere.";
                    homepage = "https://github.com/${Inputs.${pname}.owner}/${pname}";
                };
            };
            flk = { stdenv, fetchgit, pname }: let
                owner = "chr15m";
            in stdenv.mkDerivation rec {
                inherit pname;
                version = "1.0.0.0";
                src = fetchgit {
                    url = "https://github.com/${owner}/${pname}.git";
                    rev = "46a88bdb461dda336d5aca851c16d938e05304dc";
                    sha256 = "sha256-NAhWe0O1K3LOdIwYNOHfkBzkGm+h0wckpsCuY/lY/+8=";
                    deepClone = true;
                };
                installPhase = ''
                    mkdir --parents $out/bin
                    cp ./docs/${pname} $out/bin/
                '';
                meta = {
                    description = "A LISP that runs wherever Bash is";
                    homepage = "https://github.com/${owner}/${pname}";
                    license = licenses.mpl20;
                };
            };
            mdsh = { stdenv, pname }: let
                owner = "bashup";
            in stdenv.mkDerivation rec {
                inherit pname;
                version = "1.0.0.0";
                src = inputs.${pname};
                installPhase = ''
                    mkdir --parents $out/bin
                    cp $src/bin/${pname} $out/bin/
                '';
                meta = {
                    description = "Multi-lingual, Markdown-based Literate Programming... in run-anywhere bash";
                    homepage = "https://github.com/${Inputs.${pname}.owner}/${pname}";
                    license = licenses.mit;
                };
            };
            caddy = { buildGoModule, pname }: let
                imports = concatMapStrings (pkg: "\t\t\t_ \"${pkg}\"\n") [
                    "github.com/mholt/${pname}-l4"
                    "github.com/abiosoft/${pname}-yaml"
                    "github.com/${pname}-dns/cloudflare"
                ];
                main = ''
                    package main

                    import (
                        ${pname}cmd "github.com/caddyserver/${pname}/v2/cmd"
                        _ "github.com/caddyserver/${pname}/v2/modules/standard"
                        ${imports}
                    )

                    func main() {
                        ${pname}cmd.Main()
                    }
                '';
            in buildGoModule rec {
                inherit pname;
                inherit (Inputs.${pname}) version;
                subPackages = [ "cmd/${pname}" ];
                src = inputs.${pname};
                vendorSha256 = "sha256-/uBSdVkcyKMhO6KNaZkzN9eP2jCIKgetsookWaGLF5A=";
                overrideModAttrs = (_: {
                    preBuild    = postPatch;
                    postInstall = "cp go.sum go.mod $out/";
                });
                postPatch = "echo '${main}' > cmd/${pname}/main.go";
                postConfigure = ''
                    ls -la
                    cp vendor/go.sum ./
                    cp vendor/go.mod ./
                '';
                passthru.tests."${pname}" = nixosTests.${pname};
                meta = {
                    homepage = https://caddyserver.com;
                    description = "Fast, cross-platform HTTP/2 web server with automatic HTTPS";
                    license = licenses.asl20;
                    maintainers = with maintainers; [ Br1ght0ne ];
                };
            };
            guix = { stdenv, fetchurl, pname }: stdenv.mkDerivation rec {
                inherit pname;
                version = "1.0.0";
                src = fetchurl {
                    url = "https://ftp.gnu.org/gnu/guix/guix-binary-${version}.${stdenv.targetPlatform.system}.tar.xz";
                    sha256 = {
                        "x86_64-linux" = "11y9nnicd3ah8dhi51mfrjmi8ahxgvx1mhpjvsvdzaz07iq56333";
                        "i686-linux" = "14qkz12nsw0cm673jqx0q6ls4m2bsig022iqr0rblpfrgzx20f0i";
                        "aarch64-linux" = "0qzlpvdkiwz4w08xvwlqdhz35mjfmf1v3q8mv7fy09bk0y3cwzqs";
                        }."${stdenv.targetPlatform.system}";
                };
                sourceRoot = ".";
                outputs = [ "out" "store" "var" ];
                phases = [ "unpackPhase" "installPhase" ];
                installPhase = ''
                    # copy the /gnu/store content
                    mkdir -p $store
                    cp -r gnu $store

                    # copy /var content
                    mkdir -p $var
                    cp -r var $var

                    # link guix binaries
                    mkdir -p $out/bin
                    ln -s /var/guix/profiles/per-user/root/current-guix/bin/guix $out/bin/guix
                    ln -s /var/guix/profiles/per-user/root/current-guix/bin/guix-daemon $out/bin/guix-daemon
                '';
                meta = {
                    description = "The GNU Guix package manager";
                    homepage = https://www.gnu.org/software/guix/;
                    license = licenses.gpl3Plus;
                    maintainers = [ maintainers.johnazoidberg ];
                    platforms = [ "aarch64-linux" "i686-linux" "x86_64-linux" ];
                };
            };
            poetry2setup = { Python, gawk, pname }: Python.pkgs.buildPythonApplication rec {
                inherit pname;
                version = j.pyVersion format src;
                format = "pyproject";
                src = inputs.${pname};
                propagatedBuildInputs = with Python.pkgs; [ poetry-core ];
                buildInputs = with Python.pkgs; [ poetry-core ];
                installPhase = ''
                    mkdir --parents $out/bin
                    cp $src/${pname}.py $out/bin/${pname}
                    chmod +x $out/bin/${pname}
                    ${gawk}/bin/awk -i inplace 'BEGINFILE{print "#!/usr/bin/env python3"}{print}' $out/bin/${pname}
                '';

                postFixup = "wrapProgram $out/bin/${pname} $makeWrapperArgs";
                makeWrapperArgs = [ "--prefix PYTHONPATH : ${placeholder "out"}/lib/${Python.pkgs.python.libPrefix}/site-packages" ];
                meta = {
                    description = "Convert python-poetry(pyproject.toml) to setup.py.";
                    homepage = "https://github.com/${Inputs.${pname}.owner}/${pname}";
                    license = licenses.mit;
                };
            };
            nodejs = j.foldToSet [
                (j.imports.set { dir = ./callPackages/nodejs; ignores.dirs = true; })
                {
                    uglifycss =  {nodeEnv, fetchurl, fetchgit, nix-gitignore, stdenv, lib, globalBuildInputs ? []}: let
                        sources = {};
                    in {
                        uglifycss = nodeEnv.buildNodePackage {
                            name = "uglifycss";
                            packageName = "uglifycss";
                            version = "0.0.29";
                            src = fetchurl {
                                url = "https://registry.npmjs.org/uglifycss/-/uglifycss-0.0.29.tgz";
                                sha512 = "J2SQ2QLjiknNGbNdScaNZsXgmMGI0kYNrXaDlr4obnPW9ni1jljb1NeEVWAiTgZ8z+EBWP2ozfT9vpy03rjlMQ==";
                            };
                            buildInputs = globalBuildInputs;
                            meta = {
                                description = "Port of YUI CSS Compressor to NodeJS";
                                homepage = "https://github.com/fmarcia/uglifycss";
                                license = "MIT";
                            };
                            production = true;
                            bypassCache = true;
                            reconstructLock = true;
                        };
                    };
                }
            ];
            yarn = j.foldToSet [
                (j.imports.set { dir = ./callPackages/yarn; })
                {
                    maid = { mkYarnPackage, name }: mkYarnPackage rec {
                        inherit name;
                        src = inputs.${name};
                        packageJSON = "${src}/package.json";
                        yarnLock = "${src}/yarn.lock";
                        yarnNix = "${toString ./.}/callPackages/yarn/${name}/yarn.nix";
                    };
                }
            ];
            python = rec {
                python2 = {
                };
                python3 = {
                    autoslot = { buildPythonPackage, fetchFromGitHub, pytestCheckHook, flit, pname }: buildPythonPackage rec {
                        inherit pname;
                        inherit (Inputs.${pname}) version;
                        format = "pyproject";
                        src = inputs.${pname};
                        buildInputs = [ flit ];
                        nativeBuildInputs = buildInputs;
                        checkInputs = [ pytestCheckHook ];
                        pythonImportsCheck = [ pname ];
                        meta = {
                            description = "Automatic __slots__ for your Python classes";
                            homepage = "https://github.com/${Inputs.${pname}.owner}/${pname}";
                            license = lib.licenses.asl20;
                        };
                    };
                    magicattr = { buildPythonPackage, fetchFromGitHub, pytestCheckHook, pname }: buildPythonPackage rec {
                        inherit pname;
                        version = j.pyVersionSrc src;
                        src = inputs.${pname};
                        doCheck = false;
                        pythonImportsCheck = [ pname ];
                        meta = {
                            description = "A getattr and setattr that works on nested objects, lists, dicts, and any combination thereof without resorting to eval";
                            homepage = "https://github.com/${Inputs.${pname}.owner}/${pname}";
                            license = lib.licenses.mit;
                        };
                    };
                    backtrace = { buildPythonPackage, fetchFromGitHub, pytestCheckHook, colorama, pname }: buildPythonPackage rec {
                        inherit pname;
                        version = j.pyVersionSrc src;
                        src = inputs.${pname};
                        propagatedBuildInputs = [ colorama ];
                        checkInputs = [ pytestCheckHook ];
                        pythonImportsCheck = [ pname ];
                        meta = {
                            description = "Makes Python tracebacks human friendly";
                            homepage = "https://github.com/${Inputs.${pname}.owner}/${pname}";
                            license = lib.licenses.asl20;
                        };
                    };
                    pytest-reverse = { lib
                        , buildPythonPackage
                        , numpy
                        , pytestCheckHook
                        , pythonOlder
                        , pname
                    }: buildPythonPackage rec {
                        inherit pname;
                        version = "1.5.0";
                        disabled = pythonOlder "3.7";
                        src = inputs.${pname};
                        checkInputs = [ pytestCheckHook ];
                        pytestFlagsArray = [ "-p" "no:reverse" ];
                        pythonImportsCheck = [ "pytest_reverse" ];
                        meta = {
                            description = "Pytest plugin to reverse test order.";
                            homepage = "https://github.com/${Inputs.${pname}.owner}/${pname}";
                            license = licenses.mit;
                        };
                    };
                    pytest-parametrized = { buildPythonPackage, pythonOlder, pytestCheckHook, pytest-cov, pname }: buildPythonPackage rec {
                        inherit pname;
                        version = "1.3";
                        disabled = pythonOlder "3.7";
                        src = inputs.${pname};
                        pythonImportsCheck = [ "parametrized" ];
                        checkInputs = [ pytestCheckHook pytest-cov ];
                        meta = {
                            description = "Pytest decorator for parametrizing tests with default iterables.";
                            homepage = "https://github.com/${Inputs.${pname}.owner}/${pname}";
                            license = licenses.asl20;
                        };
                    };
                    pytest-custom_exit_code = { buildPythonPackage, pythonOlder, pytestCheckHook, pname }: buildPythonPackage rec {
                        inherit pname;
                        version = "0.3.0";
                        disabled = pythonOlder "3.7";
                        src = inputs.${pname};
                        pythonImportsCheck = [ "pytest_custom_exit_code" ];
                        checkInputs = [ pytestCheckHook ];
                        meta = {
                            description = "Exit pytest test session with custom exit code in different scenarios";
                            homepage = "https://github.com/${Inputs.${pname}.owner}/${pname}";
                            license = licenses.mit;
                        };
                    };
                };
                python = python3;
                hy = python3;
                xonsh = {
                    xontrib-readable-traceback = { buildPythonPackage, fetchPypi, colorama, backtrace, pname }: buildPythonPackage rec {
                        inherit pname;
                        version = "0.3.2";
                        src = fetchPypi {
                            inherit pname version;
                            sha256 = "sha256-1D/uyiA3A1dn9IPakjighckZT5Iy2WOMroBkLMp/FZM=";
                        };
                        propagatedBuildInputs = [ colorama backtrace ];
                        meta = {
                            description = "xonsh readable traceback";
                            homepage = "https://github.com/vaaaaanquish/${pname}";
                            license = lib.licenses.mit;
                        };
                    };
                    xonsh-autoxsh = { buildPythonPackage, fetchPypi, pname }: buildPythonPackage rec {
                        inherit pname;
                        version = "0.3";
                        src = fetchPypi {
                            inherit pname version;
                            sha256 = "sha256-qwXbNbQ5mAwkZ4N+htv0Juw2a3NF6pv0XpolLIQfIe4=";
                        };
                        meta = {
                            description = "Automatically execute scripts for directories in Xonsh Shell.";
                            homepage = "https://github.com/Granitosaurus/${pname}";
                            license = lib.licenses.mit;
                        };
                    };
                    xonsh-direnv = { buildPythonPackage, fetchPypi, pname }: buildPythonPackage rec {
                        inherit pname;
                        version = "1.5.0";
                        src = fetchPypi {
                            inherit pname version;
                            sha256 = "sha256-OLjtGD2lX4Yf3aHrxCWmAbSPZnf8OuVrBu0VFbsna1Y=";
                        };
                        meta = {
                            description = "xonsh extension for using direnv";
                            homepage = "https://github.com/Granitosaurus/${pname}";
                            license = lib.licenses.mit;
                        };
                    };
                    xontrib-pipeliner = { buildPythonPackage, fetchPypi, six, pname }: buildPythonPackage rec {
                        inherit pname;
                        version = "0.3.4";
                        src = fetchPypi {
                            inherit pname version;
                            sha256 = "sha256-f8tUjPEQYbycq1b3bhXwPU2YF9fkp1URqDDLH2CeNpo=";
                        };
                        propagatedBuildInputs = [ six ];
                        postPatch = ''
                            substituteInPlace setup.py --replace "'xonsh', " ""
                        '';
                        meta = {
                            description = "Let your pipe lines flow thru the Python code in xonsh.";
                            homepage = "https://github.com/anki-code/${pname}";
                            license = lib.licenses.mit;
                        };
                    };
                    xontrib-sh = { buildPythonPackage, fetchPypi, pname }: buildPythonPackage rec {
                        inherit pname;
                        version = "0.3.0";
                        src = fetchPypi {
                            inherit pname version;
                            sha256 = "sha256-eV++ZuopnAzNXRuafXXZM7tmcay1NLBIB/U+SVrQV+U=";
                        };
                        meta = {
                            description = "Paste and run commands from bash, zsh, fish, tcsh in xonsh shell.";
                            homepage = "https://github.com/anki-code/${pname}";
                            license = lib.licenses.mit;
                        };
                    };
                };
            };
        };
        patches = lib.j.imports.set {
            dir = ./patches;
            ignores.dirs = true;
            suffix = ".patch";
            files = true;
        };
        overlayset = with lib; let
            calledPackages = mapAttrs (pname: v: final: prev: { "${pname}" = final.callPackage v { inherit pname; }; }) (filterAttrs (n: v: isFunction v) callPackages);
        in rec {
            nodeOverlays = mapAttrs (n: j.update.node.default) callPackages.nodejs;
            yarnOverlays = mapAttrs j.update.node.yarn callPackages.yarn;
            pythonOverlays = rec {
                python2 = j.foldToSet [
                    (mapAttrs (pname: j.update.python.callPython.python2 { inherit pname; } pname) callPackages.python.python2)
                    (j.inputsToOverlays.python.python2 inputs)
                ];
                python3 = let
                    update = j.update.python.package.python3;
                in j.foldToSet [
                    {
                        hy = let
                            pname = "hy";
                        in final: update pname (old: let
                            python3Packages = final.Python3.pkgs;
                        in rec {
                            inherit (Inputs.${pname}) version;
                            HY_VERSION = version;
                            src = inputs.${pname};
                            postPatch = ''substituteInPlace setup.py --replace "\"funcparserlib ~= 1.0\"," ""'' + (old.postPatch or "");
                            disabledTestPaths = [ "tests/test_bin.py" ] ++ (old.disabledTestPaths or []);
                            disabledTests = [ "test_ellipsis" "test_ast_expression_basics" ] ++ (old.disabledTests or []);
                            pytestFlagsArray = [
                                "-p"
                                "no:randomly"
                            ];
                            passthru = old.passthru // {
                                tests.version = testers.testVersion {
                                    package = python3Packages.${pname};
                                    command = "${pname} -v";
                                };
                                withPackages = python-packages: (python3Packages.toPythonApplication python3Packages.${pname}).overrideAttrs (old: {
                                    propagatedBuildInputs = flatten [
                                        (python-packages python3Packages)
                                        (old.propagatedBuildInputs or [])
                                    ];
                                });
                                pkgs = python3Packages;
                            };
                        });
                        hyrule = let
                            pname = "hyrule";
                        in final: update pname (old: rec {
                            inherit (Inputs.${pname}) version;
                            src = inputs.${pname};
                            postPatch = ''substituteInPlace setup.py --replace "'hy == 0.24.0'," ""'' + (old.postPatch or "");
                        });
                    }
                    (mapAttrs (pname: j.update.python.callPython.python3 { inherit pname; } pname) callPackages.python.python3)
                    (j.inputsToOverlays.python.python3 inputs)
                ];
                python = python3;
                hy = python3;
                xonsh = j.foldToSet [
                    (mapAttrs (pname: j.update.python.callPython.python3 { inherit pname; } pname) callPackages.python.xonsh)
                    (j.inputsToOverlays.python.xonsh inputs)
                ];
            };
            overlays = let
                pyapps = [ "py2app-" "py3app-" ];
            in j.foldToSet [
                (attrValues pythonOverlays)
                (mapAttrs' (n: v: nameValuePair (j.remove.prefix pyapps) v.overlay) (filterAttrs (n: v: j.has.prefix n pyapps) inputs))
                nodeOverlays
                yarnOverlays
                calledPackages
                (let pkgsets = {
                    # nixos-unstable = [ "gnome-tour" ];
                    # nixos-unstable = "gnome-tour";
                    # nixos-unstable = { python3 = "python310"; };
                };
                in mapAttrsToList (
                    pkgchannel: pkglist': let
                        pkglist = if (isString pkglist') then [ pkglist' ] else pkglist';
                    in map (
                        pkg': let
                            pkgIsAttrs = isAttrs pkg';
                            pkg1 = if pkgIsAttrs then (last (attrNames pkg')) else pkg';
                            pkg2 = if pkgIsAttrs then (last (attrValues pkg')) else pkg';
                            pself = (pkgchannel == channel) || (pkgchannel == "self");
                        in final: prev: {
                            ${if (pself || (elem prev.stdenv.targetPlatform.system (attrNames inputs.${pkgchannel}.legacyPackages))) then pkg1 else null} = if pself then (if pkgIsAttrs then final.${pkg2} else prev.${pkg2}) else inputs.${pkgchannel}.legacyPackages.${final.stdenv.targetPlatform.system}.${pkg2};
                        }
                    ) pkglist
                ) pkgsets)
                (let pkgsets = {
                    # nixos-unstable = [ { python310Packages = "mypy"; } { python310Packages = [ "mypy" ]; } ];
                    # nixos-unstable = { python310Packages = "mypy"; };
                    # nixos-unstable = { python310Packages = [ "mypy" ]; };
                };
                in mapAttrsToList (
                    pkgchannel: pkglist': let
                        pkglist = if (isAttrs pkglist') then [ pkglist' ] else pkglist';
                        channelSystems = attrNames inputs.${pkgchannel}.legacyPackages;
                    in map (
                        pkg': let
                            pkg1 = last (attrNames pkg');
                            pkg2Pre = last (attrValues pkg');
                            pkg2IsString = isString pkg2Pre;
                            pself = (pkgchannel == channel) || (pkgchannel == "self");
                            pkgFunc = pkg: {
                                ${if (pself || (elem prev.stdenv.targetPlatform.system channelSystems)) then pkg else null} = if pself then (if pkgIsAttrs then final.${pkg} else prev.${pkg}) else inputs.${pkgchannel}.legacyPackages.${final.stdenv.targetPlatform.system}.${pkg1}.${pkg};
                            };
                            pkg2 = if pkg2IsString then (pkgFunc pkg2Pre) else (genAttrs pkg2Pre pkgFunc);
                        in final: prev: {
                            ${if (pself || (elem prev.stdenv.targetPlatform.system channelSystems)) then pkg1 else null} = pkg2;
                        }
                    ) pkglist
                ) pkgsets)
                {
                    xonsh = final: prev: {
                        xonsh = let
                            python3Packages = final.Python3.pkgs;
                            override = { inherit python3Packages; };
                        in (prev.xonsh.override override).overrideAttrs (old: {
                            disabledTestPaths = flatten [
                                "tests/test_xonfig.py"
                                (old.disabledTestPaths or [])
                            ];
                            passthru = old.passthru // {
                                withPackages = python-packages: (final.xonsh.override override).overrideAttrs (old: {
                                    propagatedBuildInputs = flatten [
                                        (python-packages python3Packages)
                                        (old.propagatedBuildInputs or [])
                                    ];
                                });
                                pkgs = python3Packages;
                            };
                    }); };
                    gum = final: prev: {
                        ${if ((elem prev.stdenv.targetPlatform.system (attrNames inputs.nixos-master.legacyPackages)) || (elem "gum" (attrNames prev))) then "gum" else null} = prev.gum or inputs.nixos-master.legacyPackages.${final.stdenv.targetPlatform.system}.gum;
                    };
                    nodeEnv = final: prev: { nodeEnv = final.callPackage "${inputs.node2nix}/nix/node-env.nix" {}; };
                    systemd = final: prev: { systemd = prev.systemd.overrideAttrs (old: { withHomed = true; }); };
                    emacs = inputs.emacs.overlay;
                    nur = final: prev: { nur = import inputs.nur { nurpkgs = inputs.nixpkgs; pkgs = final; }; };
                    # nix = inputs.nix.overlay;
                    nix-direnv = final: prev: { nix-direnv = prev.nix-direnv.override { enableFlakes = true; }; };
                    lib = final: prev: { inherit lib; };
                    Python = final: prev: rec {
                        Python2 = final.${j.attrs.versions.python.python2};
                        Python2Packages = Python2.pkgs;
                        Python3 = final.${j.attrs.versions.python.python3};
                        Python3Packages = Python3.pkgs;
                        Python = Python3;
                        PythonPackages = Python3Packages;
                        Pythons = rec {
                            python2 = final.Python2;
                            python3 = final.Python3;
                            python = python3;
                            hy = final.Python3.pkgs.hy;
                            xonsh = final.xonsh;
                        };
                    };
                }
            ];
        };
        profiles = {
            server = { config, pkgs, ... }: let
                relayNo = if config.variables.relay then "no" else "yes";
                relayYes = if config.variables.relay then "yes" else "no";
            in {
                imports = attrValues nixosModules;
                environment.systemPackages = with pkgs; [ inetutils mtr sysstat git ];
                variables.server = true;
            };
        };
        devices = {
            linode = { config, ... }: {
                imports = flatten [
                    profiles.server
                    "${inputs.nixpkgs}/nixos/modules/profiles/qemu-guest.nix"
                ];
                boot = {
                    kernelParams = [ "console=ttyS0,19200n8" ];
                    loader.grub.extraConfig = ''
                        serial --speed=19200 --unit=0 --word=8 --parity=no --stop=1;
                        terminal_input serial;
                        terminal_output serial;
                    '';
                    initrd.availableKernelModules = [ "virtio_pci" "ahci" "sd_mod" ];
                };
                networking = {
                    usePredictableInterfaceNames = false;
                    interfaces.eth0.useDHCP = true;
                };
            };
            rpi3 = { config, pkgs, ... }: {
                imports =  toList profiles.server;
                hardware.enableRedistributableFirmware = true;
                networking.wireless.enable = true;
                sound.enable = true;
                hardware.pulseaudio.enable = mkForce true;
                boot.kernelParams = toList "console=ttyS1,115200n8";
                boot.loader.raspberryPi = {
                    enable = true;
                    version = 3;
                    firmwareConfig = ''
                        dtparam=audio=on
                        core_freq=250
                        start_x=1
                        gpu_mem=256
                    '';
                    uboot.enable = true;
                };
                systemd.services.btattach = {
                    before = [ "bluetooth.service" ];
                    after = [ "dev-ttyAMA0.device" ];
                    wantedBy = [ "multi-user.target" ];
                    serviceConfig = {
                        ExecStart = "${pkgs.bluez}/bin/btattach -B /dev/ttyAMA0 -P bcm -S 3000000";
                    };
                };
                boot.kernelModules = [ "bcm2835-v4l2" ];
                boot.initrd.kernelModules = [ "vc4" "bcm2835_dma" "i2c_bcm2835" ];
            };
            rpi4 = { config, pkgs, ... }: {
                imports =  flatten [
                    profiles.server
                    inputs.hardware.raspberry-pi-4
                ];
                boot.kernelPackages = mkForce pkgs.linuxPackages_rpi4;
            };
        };
        nixosModules = with lib; rec {
            nixosModules = rec {
                openssh = { config, ... }: {
                    services.openssh = {
                        enable = true;
                        extraConfig = mkOrder 0 ''
                            TCPKeepAlive yes
                            ClientAliveCountMax 480
                            ClientAliveInterval 3m
                        '';
                        permitRootLogin = "yes";
                        openFirewall = config.variables.relay;
                    };
                };
                options = args@{ config, options, pkgs, ... }: {
                    options = {
                        variables = {
                            zfs = mkOption {
                                type = types.bool;
                                default = true;
                            };
                            relay = mkOption {
                                type = types.bool;
                                default = false;
                            };
                            server = mkOption {
                                type = types.bool;
                                default = config.variables.relay;
                            };
                            client = mkOption {
                                type = types.bool;
                                default = (! config.variables.server) && (! config.variables.relay);
                            };
                            minimal = mkOption {
                                type = types.bool;
                                default = false;
                            };
                            encrypted = mkOption {
                                type = types.bool;
                                default = false;
                            };
                        };
                        configs = {
                            config' = mkOption {
                                type = types.deferredModule;
                                default = import ./configuration.nix args;
                            };
                            config = mkOption {
                                type = types.submodule;
                                default = (import ./configuration.nix args).config;
                            };
                            hardware' = mkOption {
                                type = types.deferredModule;
                                default = import ./hardware-configuration.nix args;
                            };
                            hardware = mkOption {
                                type = types.submodule;
                                default = (import ./hardware-configuration.nix args).config;
                            };
                        };
                        services = {
                            guix = {
                                enable = mkEnableOption "GNU Guix package manager";
                                package = mkOption {
                                    type = types.package;
                                    default = pkgs.guix;
                                    defaultText = "pkgs.guix";
                                    description = "Package that contains the guix binary and initial store.";
                                };
                            };
                        };
                    };
                    imports = [ var ];
                    config = mkMerge [
                        { _module.args.variables = config.variables; }
                        (let cfg = config.programs.mosh; in mkIf cfg.enable {
                            networking.firewall.allowedUDPPortRanges = optional cfg.openFirewall { from = 60000; to = 61000; };
                        })
                        (let cfg = config.services.guix; in mkIf cfg.enable {
                            users = {
                                extraUsers = lib.fold (a: b: a // b) {} (builtins.map buildGuixUser (lib.range 1 10));
                                extraGroups.guixbuild = {name = "guixbuild";};
                            };
                            systemd.services.guix-daemon = {
                                enable = true;
                                description = "Build daemon for GNU Guix";
                                serviceConfig = {
                                    ExecStart="/var/guix/profiles/per-user/root/current-guix/bin/guix-daemon --build-users-group=guixbuild";
                                    Environment="GUIX_LOCPATH=/var/guix/profiles/per-user/root/guix-profile/lib/locale";
                                    RemainAfterExit="yes";

                                    # See <https://lists.gnu.org/archive/html/guix-devel/2016-04/msg00608.html>.
                                    # Some package builds (for example, go@1.8.1) may require even more than
                                    # 1024 tasks.
                                    TasksMax="8192";
                                };
                                wantedBy = [ "multi-user.target" ];
                            };
                            system.activationScripts.guix = ''
                                # copy initial /gnu/store
                                if [ ! -d /gnu/store ]
                                then
                                    mkdir -p /gnu
                                    cp -ra ${cfg.package.store}/gnu/store /gnu/
                                fi

                                # copy initial /var/guix content
                                if [ ! -d /var/guix ]
                                then
                                    mkdir -p /var
                                    cp -ra ${cfg.package.var}/var/guix /var/
                                fi

                                # root profile
                                if [ ! -d ~root/.config/guix ]
                                then
                                    mkdir -p ~root/.config/guix
                                    ln -sf /var/guix/profiles/per-user/root/current-guix \
                                    ~root/.config/guix/current
                                fi

                                # authorize substitutes
                                GUIX_PROFILE="`echo ~root`/.config/guix/current"; source $GUIX_PROFILE/etc/profile
                                guix archive --authorize < ~root/.config/guix/current/share/guix/ci.guix.info.pub
                            '';

                            environment.shellInit = ''
                                # Make the Guix command available to users
                                export PATH="/var/guix/profiles/per-user/root/current-guix/bin:$PATH"

                                export GUIX_LOCPATH="$HOME/.guix-profile/lib/locale"
                                export PATH="$HOME/.guix-profile/bin:$PATH"
                                export INFOPATH="$HOME/.guix-profile/share/info:$INFOPATH"
                            '';
                        })
                    ];
                };
                default = options;
                var = { config, pkgs, ... }: let
                    var' = filter (f: f.enable) (attrValues config.environment.vars);
                    var = pkgs.runCommandLocal "var" {
                        # This is needed for the systemd module
                        passthru.targets = map (x: x.target) var';
                    } /* sh */ ''
                        set -euo pipefail

                        makevarEntry() {
                            src="$1"
                            target="$2"
                            mode="$3"
                            user="$4"
                            group="$5"

                            if [[ "$src" = *'*'* ]]; then
                                # If the source name contains '*', perform globbing.
                                mkdir -p "$out/var/$target"
                                for fn in $src; do
                                    ln -s "$fn" "$out/var/$target/"
                                done
                            else
                                mkdir -p "$out/var/$(dirname "$target")"
                                if ! [ -e "$out/var/$target" ]; then
                                    ln -s "$src" "$out/var/$target"
                                else
                                    echo "duplicate entry $target -> $src"
                                    if [ "$(readlink "$out/var/$target")" != "$src" ]; then
                                        echo "mismatched duplicate entry $(readlink "$out/var/$target") <-> $src"
                                        ret=1
                                        continue
                                    fi
                                fi
                                if [ "$mode" != symlink ]; then
                                    echo "$mode" > "$out/var/$target.mode"
                                    echo "$user" > "$out/var/$target.uid"
                                    echo "$group" > "$out/var/$target.gid"
                                fi
                            fi
                        }

                        mkdir -p "$out/var"
                        ${concatMapStringsSep "\n" (varEntry: escapeShellArgs [
                            "makevarEntry"
                            # Force local source paths to be added to the store
                            "${varEntry.source}"
                            varEntry.target
                            varEntry.mode
                            varEntry.user
                            varEntry.group
                        ]) var'}
                    '';
                in {
                    options = {
                        environment.vars = mkOption {
                            default = {};
                            example = literalExpression ''
                                { example-configuration-file =
                                    { source = "/nix/store/.../var/dir/file.conf.example";
                                    mode = "0440";
                                    };
                                "default/useradd".text = "GROUP=100 ...";
                                }
                            '';
                            description = ''
                                Set of files that have to be linked in <filename>/var</filename>.
                            '';
                            type = with types; attrsOf (submodule (
                                { name, config, options, ... }:
                                { options = {
                                    enable = mkOption {
                                        type = types.bool;
                                        default = true;
                                        description = ''
                                            Whether this /var file should be generated.  This
                                            option allows specific /var files to be disabled.
                                        '';
                                    };
                                    target = mkOption {
                                        type = types.str;
                                        description = ''
                                            Name of symlink (relative to
                                            <filename>/var</filename>).  Defaults to the attribute
                                            name.
                                        '';
                                    };
                                    text = mkOption {
                                        default = null;
                                        type = types.nullOr types.lines;
                                        description = "Text of the file.";
                                    };
                                    source = mkOption {
                                        type = types.path;
                                        description = "Path of the source file.";
                                    };
                                    mode = mkOption {
                                        type = types.str;
                                        default = "symlink";
                                        example = "0600";
                                        description = ''
                                            If set to something else than <literal>symlink</literal>,
                                            the file is copied instead of symlinked, with the given
                                            file mode.
                                        '';
                                    };
                                    uid = mkOption {
                                        default = 0;
                                        type = types.int;
                                        description = ''
                                            UID of created file. Only takes effect when the file is
                                            copied (that is, the mode is not 'symlink').
                                        '';
                                    };
                                    gid = mkOption {
                                        default = 0;
                                        type = types.int;
                                        description = ''
                                            GID of created file. Only takes effect when the file is
                                            copied (that is, the mode is not 'symlink').
                                        '';
                                    };
                                    user = mkOption {
                                        default = "+${toString config.uid}";
                                        type = types.str;
                                        description = ''
                                            User name of created file.
                                            Only takes effect when the file is copied (that is, the mode is not 'symlink').
                                            Changing this option takes precedence over <literal>uid</literal>.
                                        '';
                                    };
                                    group = mkOption {
                                        default = "+${toString config.gid}";
                                        type = types.str;
                                        description = ''
                                            Group name of created file.
                                            Only takes effect when the file is copied (that is, the mode is not 'symlink').
                                            Changing this option takes precedence over <literal>gid</literal>.
                                        '';
                                    };
                                };
                                config = {
                                    target = mkDefault name;
                                    source = mkIf (config.text != null) (
                                        let name' = "var-" + baseNameOf name;
                                        in mkDerivedConfig options.text (pkgs.writeText name')
                                    );
                                };
                            }));
                        };
                    };
                    config = {
                        system = {
                            activationScripts.vars = lib.stringAfter [ "users" "groups" ] config.system.build.varActivationCommands;
                            build = {
                                var = var;
                                varActivationCommands = ''
                                    # Set up the statically computed bits of /var.
                                    echo "setting up /var..."
                                    ${pkgs.perl.withPackages (p: [ p.FileSlurp ])}/bin/perl ${./setup-var.pl} ${var}/var
                                '';
                            };
                        };
                    };
                };
            };
            nixosModule = nixosModules.default;
            defaultNixosModule = nixosModule;
        };
        templates = with lib; rec {
            templates = let
                allTemplates = mapAttrs (n: path: { description = "The ${n} template!"; inherit path; }) (j.imports.set {
                    dir = ./templates;
                    ignores.files = true;
                    files = true;
                });
            in j.foldToSet [
                allTemplates
                { default = allTemplates.python-package; }
            ];
            template = templates.default;
            defaultTemplate = template;
        };
        individual-outputs = with lib; j.foldToSet [
            nixosModules
            templates
            { inherit make lib lockfile channel registry profiles devices mkOutputs Inputs defaultSystem workingSystems; }
        ];
        mkOutputs = with lib; {
            pname,
            inputs,
            callPackage ? null,
            overlay ? null,
            overlays ? {},
            type ? "general",
            isApp ? false,
            extraSystemOutputs ? (oo: system: {}),
            extraOutputs ? {},
            extras ? {},
            settings ? false,
            make ? self.make,
            ...
        }: let
            type' = if isApp then "general" else type;
            isPythonApp = isApp && (elem type j.attrs.versionNames.python);
            overlayset = let
                inheritance = { inherit pname; };
                overlays' = j.foldToSet [
                    { general = final: prev: { ${pname} = final.callPackage (if isPythonApp then (j.toPythonApplication final prev final.Pythons.${type}.pkgs extras pname)
                                                                             else callPackage) inheritance; }; }
                    (genAttrs j.attrs.versionNames.python (python: j.update.python.callPython.${python} inheritance pname callPackage))
                ];
                default = if ((callPackage == null) && (overlay == null) && (((overlays == {}) || (! (overlays ? default))) && (! settings)))
                               then (abort "Sorry; one of `callPackage', `overlay', or an `overlays' set with a `default' overlay must be set!")
                          else if (callPackage != null) then overlays'.${type'}
                          else if (overlay != null) then overlay
                          else overlays.default;
                overlay' = { ${pname} = default; };
            in {
                overlays = j.foldToSet [
                    (mapAttrsToList (n: map (version: j.inputsToOverlays.${n}.${version} inputs)) j.attrs.versionNames)
                    (optionalAttrs (! settings) self.overlays)
                    overlay'
                    (optionalAttrs (! (overlays ? default)) { inherit default; })
                    (optionalAttrs isApp { "${pname}-lib" = overlays'.${type}; })
                    overlays
                ];
                overlay = default;
                defaultOverlay = default;
            };
            official-outputs = let
                oo = eachSystem workingSystems (system: let
                    made = make system overlayset.overlays;
                in rec {
                    inherit (made) nixpkgs pkgs legacyPackages;
                    inherit made;
                    packages = let
                        packages' = j.foldToSet [
                            {
                                general = {
                                    default = pkgs.${pname};
                                    ${pname} = pkgs.${pname};
                                };
                            }
                            (let
                                pythons = mapAttrs (n: v: made.mkPython v [] pname) pkgs.Pythons;
                            in mapAttrs (n: v: j.foldToSet [
                                pythons
                                (j.mapAttrNames (n: v: "${n}-${pname}") pythons)
                                { default = pythons.${type}; "${pname}" = pythons.${type}; }
                            ]) pythons)
                        ];
                    in flattenTree (j.foldToSet [
                        packages'.${type'}
                        (optionalAttrs isApp packages'.${type})
                    ]);
                    package = packages.default;
                    defaultPackage = package;
                    apps = mapAttrs (n: made.app) packages;
                    app = apps.default;
                    defaultApp = app;
                    devShells = let
                        default = pkgs.mkShell { buildInputs = attrValues packages; };
                    in j.foldToSet [
                        (mapAttrs (n: v: pkgs.mkShell { buildInputs = toList v; }) packages)
                        (mapAttrs (n: v: pkgs.mkShell { buildInputs = toList v; }) made.buildInputSet)
                        (made.mkfile isApp type extras pname (packages.${pname}.nativeBuildInputs or []) (packages.${type}.pkgs.${pname}.nativeBuildInputs or []))
                        { inherit default; "${pname}" = default; }
                    ];
                    devShell = devShells.default;
                    defaultdevShell = devShell;
                });
            in j.foldToSet [
                oo
                overlayset
                {
                    inherit pname callPackage type' type;
                    oo = listToAttrs (map (system: nameValuePair system (mapAttrs (n: v: v.${system}) oo)) workingSystems);
                }
            ];
        in j.foldToSet' [
            official-outputs
            (eachSystem workingSystems (extraSystemOutputs official-outputs.oo))
            extraOutputs
        ];
        make = system: overlays: with lib; rec {
            config' = rec {
                base = { inherit system; };
                default = base // { config = lib.j.attrs.configs.nixpkgs; };
                overlayed = default // { overlays = attrValues overlays; };
            };
            nixpkgs' = {
                package = inputs.nixpkgs;
                base = j.patch.nixpkgs.default inputs.nixpkgs config'.base;
                default = j.patch.nixpkgs.default inputs.nixpkgs config'.default;
                overlayed = j.patch.nixpkgs.default inputs.nixpkgs config'.overlayed;
            };
            pkgs' = {
                package = import nixpkgs'.package config'.overlayed;
                base = j.patch.pkgs.default inputs.nixpkgs config'.base;
                default = j.patch.pkgs.default inputs.nixpkgs config'.default;
                overlayed = j.patch.pkgs.default inputs.nixpkgs config'.overlayed;
            };
            pkgs = pkgs'.package;
            legacyPackages = pkgs;
            nixpkgs = config'.overlayed;
            specialArgs = j.foldToSet [
                individual-outputs
                (rec {
                    inherit inputs;
                    made = make system overlays;
                    nixpkgs = made.config'.overlayed;
                    pkgs = made.pkgs'.overlayed;
                    legacyPackages = pkgs;
                })
            ];
            app = drv: { type = "app"; program = "${drv}${drv.passthru.exePath or "/bin/${drv.meta.mainprogram or drv.executable or drv.pname or drv.name}"}"; };
            mkPython = python: pkglist: pname: python.withPackages (j.filters.has.list [
                pkglist
                pname
            ]);
            buildInputSet = with pkgs; { envrc = [ git settings ]; };
            mkbuildinputs = with pkgs; let
                general = [ "yq" ];
            in lib.j.foldToSet [
                {
                    default = flatten [ buildInputSet.envrc ];
                    inherit general;
                }
                (mapAttrs (n: v: func: extras: pname: ppkglist: flatten [
                    (extras."makefile-${n}".buildInputs or [])
                    pkgs.poetry2setup
                    (mkPython v (flatten [
                        general
                        ppkglist
                        (extras."makefile-${n}".pythonPackages or [])
                    ]) ((v.pkgs or pkgs.Pythons.python.pkgs).${pname}.overridePythonAttrs func))
                ]) pkgs.Pythons)
            ];
            mkfilefunk = let
                func = old: { doCheck = false; };
            in mapAttrs (n: v: isApp: type: extras: pname: pkglist: ppkglist: j.foldToShell pkgs [
                (pkgs.mkShell (j.recursiveUpdateAll { buildInputs = [
                    mkbuildinputs.default
                    (optionals (isApp || (type == "general")) (if (pname == null) then pname else (pkgs.${pname}.overrideAttrs func)))
                ]; } (extras.global or {})))
                (v isApp type extras pname pkglist ppkglist)
            ]) (j.foldToSet [
                { general = isApp: type: extras: pname: pkglist: ppkglist: pkgs.mkShell (j.recursiveUpdateAll {
                    buildInputs = j.filters.has.list [
                        (mkPython pkgs.Python3 [
                            mkbuildinputs.general
                            ppkglist
                            (extras.general.pythonPackages or [])
                        ] null)
                        pkglist
                    ] pkgs;
                } (extras.general or {})); }
                (genAttrs j.attrs.versionNames.python (python: isApp: type: extras: pname: pkglist: ppkglist: pkgs.mkShell (j.recursiveUpdateAll {
                    buildInputs = j.filters.has.list [
                        (mkbuildinputs.${python} func extras pname ppkglist)
                        pkglist
                    ] pkgs;
                } (extras."makefile-${python}" or {}))))
            ]);
            mkfile = isApp: type: extras: pname: pkglist: ppkglist: let
                default = mkfilefunk.${type} isApp type extras pname pkglist ppkglist;
                isAppGeneral = isApp || (type == "general");
            in rec {
                makefile-general = mkfilefunk.general isApp type extras (if isAppGeneral then pname else null) pkglist ppkglist;
                makefile = if isAppGeneral then makefile-general else default;
                ${if (isApp || (type != "general")) then "makefile-${type}" else null} = default;
            };
            withPackages = {
                python = let
                    hyOverlays = filter (pkg: pkg != "hy") (attrNames overlayset.pythonOverlays.python3);
                in j.foldToSet [
                    (map (python: (listToAttrs (map (pkg: nameValuePair "${python}-${pkg}" (pkglist: mkPython pkgs.Pythons.${python} [
                        pkg
                        pkglist
                    ])) (attrNames overlayset.pythonOverlays.${python})))) [ "python" "python2" "python3" ])
                    (map (os: (listToAttrs (map (pkg: nameValuePair "xonsh-${pkg}" (pkglist: mkPython pkgs.Pythons.xonsh [ pkg pkglist ])) (attrNames overlayset.pythonOverlays.${os})))) [ "python3" "xonsh" ])
                    (listToAttrs (map (pkg: nameValuePair "xonsh-${pkg}" (pkglist: mkPython pkgs.Pythons.xonsh [ pkg pkglist ])) (attrNames overlayset.pythonOverlays.xonsh)))
                    (listToAttrs (map (python: nameValuePair python (pkglist: mkPython pkgs.Pythons.${python} [
                        (attrNames overlayset.pythonOverlays.${python})
                        pkglist
                    ])) [ "python" "python2" "python3" ]))
                    (listToAttrs (map (pkg: nameValuePair "hy-${pkg}" (pkglist: mkPython pkgs.Pythons.hy [ pkg pkglist ])) hyOverlays))
                    {
                        xonsh = pkglist: mkPython pkgs.Pythons.xonsh [ (attrNames overlayset.pythonOverlays.xonsh) pkglist ];
                        hy = pkglist: mkPython pkgs.Pythons.hy [ hyOverlays pkglist ];
                    }
                ];
            };
            mkPackages = {
                default = nixpkgs: j.filters.has.attrs [
                    (subtractLists (attrNames (nixpkgs.legacyPackages.${system} or nixpkgs.legacyPackages.${defaultSystem})) (attrNames pkgs))
                    (attrNames overlays)
                ] pkgs;
                node = nodeOverlays: j.mapAttrNames (n: v: "nodejs-${n}") (j.filters.has.attrs (map attrNames nodeOverlays) pkgs.nodePackages);
                python = mapAttrs (n: v: v [] null) withPackages.python;
            };
        };
    in with lib; mkOutputs {
        inherit inputs make;
        pname = "settings";
        callPackage = { stdenv, emacs-nox, pname }: stdenv.mkDerivation rec {
            inherit pname;
            version = "1.0.0.0";
            src = ./.;
            phases = [ "installPhase" ];
            installPhase = ''
                mkdir --parents $out
                cp -r $src/bin $out/bin
                chmod +x $out/bin/*
            '';
            meta.mainprogram = "org-tangle";
            postInstall = "wrapProgram $out/bin/${pname} $makeWrapperArgs";
            makeWrapperArgs = toList "--set PATH ${makeBinPath [
                (if (elem stdenv.targetPlatform.system (attrNames inputs.nixpkgs.legacyPackages)) then inputs.nixpkgs.legacyPackages.${stdenv.targetPlatform.system}.emacs-nox else emacs-nox)
            ]}";
        };
        inherit (overlayset) overlays;
        settings = true;
        extraSystemOutputs = oo: system: let
            inherit (oo.${system}) pkgs made;
        in rec {
            packages = flattenTree (j.foldToSet [
                (made.mkPackages.default inputs.nixpkgs)
                (made.mkPackages.node [ overlayset.nodeOverlays overlayset.yarnOverlays ])
                made.mkPackages.python
            ]);
            devShells = with pkgs; {
                all = mkShell { buildInputs = flatten [
                    (attrValues packages)
                    (attrValues oo.${system}.packages)
                ]; };
                site = mkShell { buildInputs = with nodePackages; [ uglifycss uglify-js sd ]; };
            };
        };
        extraOutputs = individual-outputs;
    };
}
