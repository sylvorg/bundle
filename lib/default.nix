linputs: lfinal: lpname:
with builtins;
with lfinal; {
  attrs = rec {
    buildInputs.default = [ lpname ];
    inputPrefixes = {
      emacs = "e";
      node = "node";
    };
    platforms = {
      arm = [ "aarch64-linux" "armv7l-linux" "armv6l-linux" ];
      imd = [ "i686-linux" "x86_64-linux" ];
    };
    versions = {
      emacs = "emacs-nox";
      node = "node";
      yarn = "yarn";
    };
  };
  mapNullId = mapNullable id;
  imports = let inherit (iron) fpipe filters mapAttrNames dirCon fold;
  in rec {
    name = { file, suffix ? ".nix", }:
      let base-file = baseNameOf (toString file);
      in if (isInt suffix) then
        (let
          hidden = hasPrefix "." base-file;
          split-file = remove "" (splitString "." base-file);
        in if (hidden && ((length split-file) == 1)) then
          base-file
        else
          concatStringsSep "." (take ((length split-file) - suffix) split-file))
      else
        (removeSuffix suffix base-file);
    list = args@{ dir, idir ? dir, ignores ? { }, iter ? 0, keep ? false
      , keeping ? { }, local ? false, file ? {
        prefix = {
          pre = "";
          post = "";
        };
        suffix = "";
      }, recursive ? false, root ? false, names ? false, suffix ? ".nix", }:
      let
        func = dir:
          let
            stringDir = toString dir;
            stringyDir = toString idir;
            fk = filters.keep;
            fr = filters.remove;
            pre-orders = flatten [
              (optional (keeping.files or false) fk.files)
              (optional (keeping.unknown or false) fk.unknown)
              (fk.prefix (keeping.prefix or [ ]))
              (fk.infix (keeping.infix or [ ]))
              (fk.readDir.files.suffix (keeping.suffix or [ ]))
              (fk.readDir.files.elem (keeping.elem or [ ]))
              (fk.readDir.unknown.suffix (keeping.suffix or [ ]))
              (fk.readDir.unknown.elem (keeping.elem or [ ]))
              (fk.readDir.static.suffix (keeping.suffix or [ ]))
              (fk.readDir.static.elem (keeping.elem or [ ]))
              (optional (ignores.files or false) fr.files)
              (optional (ignores.unknown or false) fr.unknown)
              (fr.prefix (ignores.prefix or [ ]))
              (fr.infix (ignores.infix or [ ]))
              (fr.readDir.files.suffix (ignores.suffix or [ ]))
              (fr.readDir.files.elem (ignores.elem or [ ]))
              (fr.readDir.unknown.suffix (ignores.suffix or [ ]))
              (fr.readDir.unknown.elem (ignores.elem or [ ]))
              (fr.readDir.static.suffix (ignores.suffix or [ ]))
              (fr.readDir.static.elem (ignores.elem or [ ]))
            ];
            orders = flatten [
              (optional (keeping.dirs or false) fk.dirs)
              (optional (keeping.others or false) fk.others)
              (optional (keeping.sym or false) fk.sym)
              (fk.suffix (keeping.suffix or [ ]))
              (fk.elem (keeping.elem or [ ]))
              (optional (ignores.dirs or false) fr.dirs)
              (optional (ignores.others or false) fr.others)
              (optional (ignores.sym or false) fr.sym)
              (fr.suffix (ignores.suffix or [ ]))
              (fr.elem (ignores.elem or [ ]))
            ];
            pipe-list = flatten [
              (mapAttrNames (n: v:
                pipe "${removePrefix stringyDir stringDir}/${n}" [
                  (splitString "/")
                  (remove "")
                  (concatStringsSep "/")
                ]))
              pre-orders
            ];
            items = let
              filtered-others = fpipe pipe-list (dirCon.attrs.others dir);
              filtered-dirs = fpipe [
                pipe-list
                (optionals recursive (mapAttrsToList (n: v:
                  list (args // {
                    dir = "${stringyDir}/${n}";
                    inherit idir;
                    iter = iter + 1;
                  }))))
              ] (dirCon.attrs.dirs dir);
            in fold.set [ filtered-others filtered-dirs ];
            process = fpipe [
              pipe-list
              orders
              (if names then
                (mapAttrNames (file: v: name { inherit suffix file; }))
              else [
                (mapAttrNames (n: v: (file.prefix.pre or "") + n))
                (mapAttrNames (n: v:
                  if keep then
                    n
                  else if local then
                    "./${n}"
                  else if root then
                    "/${n}"
                  else
                    "${stringDir}/${n}"))
                (mapAttrNames
                  (n: v: (file.prefix.post or "") + n + (file.suffix or "")))
              ])
              attrNames
            ];
          in if (iter == 0) then (process items) else items;
      in flatten (map func (toList dir));
    set = args@{ call ? null, dir, extrargs ? { }, suffix ? ".nix"
      , files ? false, ... }:
      listToAttrs (map (file:
        nameValuePair (name { inherit file suffix; }) (if files then
          file
        else if (call != null) then
          (call.callPackage file extrargs)
        else if (extrargs == { }) then
          (import file)
        else
          (import file extrargs)))
        (list (removeAttrs args [ "call" "extrargs" "files" ])));
    overlaySet = args@{ call ? null, dir, extrargs ? { }, func ? null
      , suffix ? ".nix", ... }:
      listToAttrs (map (file:
        let filename = name { inherit file suffix; };
        in nameValuePair filename (if (func != null) then
          (func file)
        else if ((isInt call) && (call == 1)) then
          (final: prev: { "${filename}" = final.callPackage file extrargs; })
        else if ((isInt call) && (call == 0)) then
          (final: prev: { "${filename}" = prev.callPackage file extrargs; })
        else if (call != null) then
          (final: prev: { "${filename}" = call.callPackage file extrargs; })
        else if (extrargs == { }) then
          (import file)
        else
          (import file extrargs))) (list
            (removeAttrs (recursiveUpdate args { ignores.dirs = true; }) [
              "call"
              "extrargs"
              "func"
            ])));
  };

  getPkg = let inherit (iron) attrs;
  in {
    node = channel: flip getAttr channel."${attrs.versions.node}Packages";
    emacs = channel: flip getAttr channel.${attrs.versions.emacs}.pkgs;
  };

  update = let inherit (iron) callPackageFilter emacsenGen imports fold;
  in {

    # Adapted From: https://github.com/svanderburg/node2nix/issues/252#issuecomment-891888835
    node = {
      node' = pkgs: final: prev: {
        nodePackages = fix
          (extends (node-final: node-prev: recursiveUpdate node-prev pkgs)
            (new: prev.nodePackages));
      };
      node = name: pkg:
        iron.update.node.node'
        (callPackageFilter final.callPackage pkg { inherit name; });
      replace = let
        inherit (iron) getPkg fold mif channel;
        replacements = {
          package = value:
            iron.update.node.node'
            (new: old: if (isFunction value) then (value new old) else value);
          input = name: channel:
            replacements.package (getPkg.node channel name);
          inputList = {
            attrs = channel:
              flip genAttrs (pkg: final: prev:
                replacements.input pkg
                (if (isFunction channel) then (channel final prev) else channel)
                final prev);
            list = channel: list:
              attrValues (replacements.inputList.attrs channel list);
            super = channel: list: final: prev:
              iron.update.node.node' (genAttrs list (getPkg.node
                (if (isFunction channel) then
                  (channel final prev)
                else
                  channel))) final prev;
          };
          override = name: channel: inputs: func: final: prev:
            replacements.package name
            ((getPkg.node channel name).overrideAttrs func) final prev;
        };
      in fold.set [
        replacements
        {
          channel = let
            channelReplacements = {
              ote = mapAttrs
                (n: v: c1: c2: name: v (mif.null (channel.ote c1 c2) name))
                replacements;
              nte = mapAttrs
                (n: v: c1: c2: name: v (mif.null (channel.nte c1 c2) name))
                replacements;
            };
          in fold.set [
            channelReplacements
            (mapAttrs' (N: V:
              nameValuePair ("c" + N)
              (mapAttrs (n: v: v iron.attrs.channel.value) V))
              channelReplacements)
          ];
        }
      ];
    };

    # Adapted From: https://github.com/svanderburg/node2nix/issues/252#issuecomment-891888835
    yarn = {
      inherit (iron.update.node) replace;
      yarn = name: pkg:
        iron.update.node.node' {
          "${name}" = callPackageFilter final.callPackage pkg { inherit name; };
        };
    };

    emacs = {
      # Adapted From: https://discourse.nixos.org/t/how-to-add-custom-python-package/536/4
      #               https://discourse.nixos.org/t/use-multiple-instances-of-prev-python-override/20066/2
      #               https://discourse.nixos.org/t/override-a-transitive-emacs-dependency/6700/3
      # TODO: Simplify this
      emacs = name: value: pkg: final: prev:
        let
          emacs-overlays = linputs.emacs.overlay prev prev;
          emacsen' = emacsenGen prev emacs-overlays;
          emacsen = genAttrs (flatten [ emacsen' ]) (emacs: final.${emacs});
          first = !(prev ? emacsen);
        in {
          emacsen = prev.emacsen or emacsen;
        } // (genAttrs emacsen' (emacs:
          let
            emacs' = emacs-overlays.${emacs} or (if first then
              linputs.nixpkgs.legacyPackages.${prev.stdenv.targetPlatform.system}
            else
              prev).${emacs};
            pkgs = fix (extends (emacs-final: emacs-prev:
              recursiveUpdate emacs-prev (if (name == null) then
                value
              else {
                ${name} = if (pkg == null) then
                  (if (isFunction value) then (value emacs-prev) else value)
                else
                  (callPackageFilter final.callPackage pkg
                    (value // { emacs = final.${emacs}; }));
              })) (emacs-final: emacs'.pkgs));
            passthru = let
              emacsWith = rec {
                emacsWithPackages = f1:
                  fold.set [
                    (pkgs.emacsWithPackages (f2: f1 pkgs))
                    passthru
                    { inherit passthru; }
                  ];
                withPackages = emacsWithPackages;
              };
            in fold.set [
              emacs'.passthru
              emacsWith
              {
                pkgs = pkgs // emacsWith;
                executable = emacs'.executable or "emacs";
              }
            ];
          in fold.set [ emacs' passthru { inherit passthru; } ]));
      replace = let
        inherit (iron) getPkg fold mif channel;
        inputListFunction = channel: pkg: final: prev:
          replacements.input pkg
          (if (isFunction channel) then (channel final prev) else channel) final
          prev;
        replacements = {
          package = name: value:
            iron.update.emacs.emacs null (new: old: {
              ${name} = if (isFunction value) then (value new old) else value;
            }) null;
          input = name: channel:
            replacements.package name (getPkg.emacs channel name);
          inputList = {
            attrs = channel:
              flip genAttrs (pkg: final: prev:
                replacements.input pkg
                (if (isFunction channel) then (channel final prev) else channel)
                final prev);
            list = channel: list:
              attrValues (replacements.inputList.attrs channel list);
            super = channel: list: final: prev:
              iron.update.emacs.emacs null (genAttrs list (getPkg.emacs
                (if (isFunction channel) then
                  (channel final prev)
                else
                  channel))) null final prev;
          };
          override = name: channel: inputs: func: final: prev:
            replacements.package name
            ((getPkg.emacs channel name).overrideAttrs func) final prev;
        };
      in fold.set [
        replacements
        {
          channel = let
            channelReplacements = {
              ote = mapAttrs
                (n: v: c1: c2: name: v (mif.null (channel.ote c1 c2) name))
                replacements;
              nte = mapAttrs
                (n: v: c1: c2: name: v (mif.null (channel.nte c1 c2) name))
                replacements;
            };
          in fold.set [
            channelReplacements
            (mapAttrs' (N: V:
              nameValuePair ("c" + N)
              (mapAttrs (n: v: v iron.attrs.channel.value) V))
              channelReplacements)
          ];
        }
      ];
      callEmacs = extrargs: name: pkg: final:
        iron.update.emacs.emacs name extrargs pkg final;
      callEmacs' = extrargs: file: final:
        iron.update.emacs.emacs (imports.name { inherit file; }) extrargs file
        final;
      package = pkg: func: final: prev:
        iron.update.emacs.emacs pkg
        (emacs-prev: emacs-prev.emacs.pkgs.${pkg}.overrideAttrs func) null final
        prev;

      # TODO: The `call' value here doesn't work; `final.emacs.pkgs.callPackage' does not exist
      packages = dir: final:
        iron.update.emacs.emacs null (imports.set {
          call = final.emacs.pkgs;
          inherit dir;
          ignores.elem = dirCon.dirs dir;
        }) null final;

    };
  };

  emacsenGen = prev: emacs-overlays:
    filter (emacs:
      (hasPrefix "emacs" emacs) && (!(hasInfix "Packages" emacs))
      && (!(elem emacs [
        "emacs-all-the-icons-fonts"
        "emacsMacport"
        "emacsen"
      ]))) (flatten [ (attrNames prev) (attrNames emacs-overlays) ]);

  callPackages = cpgks:
    mapAttrs (pname: cpkg: final: prev: {
      ${pname} =
        iron.callPackageFilter final.callPackage cpkg { inherit pname; };
    }) cpgks;

  aAttrs = a: func: attrs: a id (attrValues (mapAttrs func attrs));
  anyAttrs = iron.aAttrs any;
  allAttrs = iron.aAttrs all;

  butlast = list: sublist 0 ((length list) - 1) list;
  attrTree = rec {
    list = attrs:
      mapAttrsToList (n: v:
        if (isAttrs v) then (flatten [ n (attrTreeList v) ]) else (toList n))
      attrs;
    listRemoveNull = attrs:
      map (n: if ((last n) == "null") then (butlast n) else n) (list attrs);
    str'' = func: sep: attrs: map (concatStringsSep sep) (func attrs);
    str' = str'' list;
    str = str' ".";
    strRemoveNull' = str'' listRemoveNull;
    strRemoveNull = strRemoveNull' ".";
    attrs'' = func: sep: attrs:
      listToAttrs
      (map (n: nameValuePair (concatStringsSep sep n) (getAttrFromPath n attrs))
        (func attrs));
    attrs' = attrs'' list;
    attrs = attrs' ".";
    attrsRemoveNull' = attrs'' listRemoveNull;
    attrsRemoveNull = attrsRemoveNull' ".";
  };

  baseVersion = head
    (splitString "p" (concatStringsSep "." (take 2 (splitString "." version))));
  zipToSet = names: values:
    listToAttrs (map (nv: nameValuePair nv.fst nv.snd)
      (let hasAttrs = any isAttrs values;
      in zipLists (if hasAttrs then names else (sort lessThan names))
      (if hasAttrs then values else (sort lessThan values))));
  toCapital = string:
    concatImapStrings (i: v: if (i == 1) then (toUpper v) else v)
    (stringToCharacters string);

  # foldr func end list
  sequence = foldr deepSeq;

  enableGuix = flip elem [ "x86_64-linux" "i686-linux" "aarch64-linux" ];

  isSublist = a: b: all (flip elem b) a;
  allSets = func: set: all (name: func name set.${name}) (attrNames set);
  anySets = func: set: any (name: func name set.${name}) (attrNames set);

  systemd.wants = list:
    unique ([ "network.target" "network-online.target" ] ++ list);

  # Adapted From: https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/emacs/trivial.nix#L18
  # And: https://github.com/nix-community/nix-doom-emacs/blob/master/overrides.nix#L56
  mkEmacsInstallPhase = files: ''
    runHook preInstall
    LISPDIR=$out/share/emacs/site-lisp
    install -d $LISPDIR
    install ${files} $LISPDIR
    runHook postInstall
  '';

  # Adapted From: https://github.com/NixOS/nixpkgs/blob/master/lib/lists.nix#L99
  # And: https://github.com/NixOS/nixpkgs/blob/master/lib/lists.nix#L109
  # Map with index ending at 0 and 1 respectively
  imap0r = f: list:
    genList (n: f ((length list) - (n + 1)) (elemAt list n)) (length list);
  imap1r = f: list:
    genList (n: f ((length list) - n) (elemAt list n)) (length list);

  mkEmacsPackage =
    { self, emacs, inputs ? { }, package, recursiveOverrides ? [ ] }:
    let
      inherit (iron) functors filters fold pyVersion;
      pname = package.pname or self.pname;
      owner = package.owner or "syvlorg";
      doCheck = if (package ? doCheck) then package.doCheck else true;

      inherit (emacs) pkgs;
      toOverride = { inherit pname doCheck; };
      overrideNames = attrNames toOverride;
      pselfOverride = iron.getAttrs overrideNames package;
      absolute = removeAttrs (let
        a = functors.xelf (alf:
          mapAttrs (n: v: unique (flatten [ v (package.${n} or [ ]) ])) {
            buildInputs = [ emacs (alf.propagatedUserEnvPkgs or [ ]) ];
            nativeBuildInputs = alf.buildInputs;
            propagatedUserEnvPkgs = optionals (inputs != { }) (map (pkg':
              let pkg = pkgs.${pkg'};
              in [ pkg pkg.propagatedUserEnvPkgs ])
              (iron.inputPkgsToPackages.emacs inputs));
            propagatedNativeUserEnvPkgs = alf.propagatedUserEnvPkgs;
          });
      in fold.set [ a ]) recursiveOverrides;
      absoluteNames = attrNames absolute;
      toRecurse = removeAttrs (rec {

        postInstall = ''
          HOME=$(mktemp -d)
          mkdir -p $HOME/.emacs.d
          emacs \
            --batch \
            --eval "(progn (add-to-list 'load-path \"$LISPDIR\") (require '${
              concatStringsSep ") (require '" (self.testFiles or [ pname ])
            }))"
        '';

        meta = {
          inherit (emacs.meta) platforms;
          homepage = "https://github.com/${owner}/${pname}";

          # Adapted From: https://github.com/NixOS/nixpkgs/blob/master/pkgs/stdenv/generic/make-derivation.nix#L134-L139
          position = let pos = unsafeGetAttrPos "pname" package;
          in "${pos.file}:${toString pos.line}";

        };
      }) recursiveOverrides;
      recursiveNames = attrNames toOverride;
      packageRecursed = iron.getAttrs recursiveNames package;
    in pkgs.trivialBuild (fold.set [
      absolute
      toOverride
      pselfOverride
      (fold.stringMerge [ toRecurse packageRecursed ])
      (removeAttrs package
        (flatten [ overrideNames recursiveNames absoluteNames "owner" ]))
    ]);
}
