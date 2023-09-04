inputs: lib:
with builtins;
with lib;
let
  lockfile = fromJSON (readFile ../flake.lock);
  Inputs = iron.extendInputs inputs lockfile;
in {
  callPackages = iron.mapPassName {

    # Adapted From: https://github.com/NixOS/nixpkgs/blob/master/pkgs/data/icons/capitaine-cursors/default.nix
    oreo-cursors = pname:
      { stdenvNoCC, makeFontsConf, inkscape, xcursorgen, ruby, colors ? {
        black_colors = {
          color = "#424242";
          labelColor = "#FFF";
          shadowColor = "#222";
          shadowOpacity = "0.4";
        };
      }, colours ? {
        black_colours = {
          colour = "#424242";
          labelColour = "#FFF";
          shadowColour = "#222";
          shadowOpacity = "0.4";
        };
      } }:
      stdenvNoCC.mkDerivation rec {
        inherit pname;
        version = "20220821";
        src = inputs.${pname};
        buildInputs = [ inkscape xcursorgen ruby ];
        FONTCONFIG_FILE = makeFontsConf { fontDirectories = [ ]; };
        postPatch = ''
          cat >> generator/colours.conf <<EOF
          ${concatStringsSep "\n" (mapAttrsToList (n: v:
            let
              color = v.color or v.colour;
              labelColor = v.labelColor or v.labelColour or "#FFF";
              shadowColor = v.shadowColor or v.shadowColour or "#000";
              shadowOpacity = v.shadowOpacity or "0.3";
            in "${n} = ${color} ${labelColor} ${shadowColor} ${shadowOpacity}")
            (colors // colours))}
          EOF
        '';
        buildPhase = ''
          HOME=$(mktemp -d)
          ${ruby}/bin/ruby generator/convert.rb
          make build
        '';
        installPhase = ''
          install -dm 0755 $out/share/icons
          cp -pr dist/* $out/share/icons/
        '';
        meta = with lib; {
          description = "oreo-cursors";
          homepage = "https://github.com/${Inputs.${pname}.owner}/${pname}";
          license = licenses.gpl2;
        };
      };

    # Adapted From: https://github.com/NixOS/nixpkgs/blob/nixos-22.05/pkgs/data/fonts/nerdfonts/default.nix#L54
    xero-figlet-fonts = pname:
      { stdenvNoCC, ... }:
      stdenvNoCC.mkDerivation {
        inherit pname;
        version = "20221017";
        src = inputs.${pname};
        installPhase = ''
          mkdir -p $out/share/figlet/fonts
          find -name \*.flc -exec mv {} $out/share/figlet/fonts \;
          find -name \*.flf -exec mv {} $out/share/figlet/fonts \;
        '';
      };

    sysget = pname:
      { stdenvNoCC, installShellFiles }:
      stdenvNoCC.mkDerivation rec {
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
    pacapt = pname:
      { stdenvNoCC }:
      stdenvNoCC.mkDerivation rec {
        inherit pname;
        inherit (Inputs.${pname}) version;
        src = inputs.${pname};
        installPhase = ''
          mkdir --parents $out/bin
          cp $src/${pname} $out/bin/
          chmod 755 $out/bin/*
        '';
        meta = {
          description =
            "An ArchLinux's pacman-like shell wrapper for many package managers. 56KB and run anywhere.";
          homepage = "https://github.com/${Inputs.${pname}.owner}/${pname}";
        };
      };
    flk = pname:
      { stdenv }:
      let owner = "chr15m";
      in stdenv.mkDerivation rec {
        inherit pname;
        version = "1.0.0.0";
        src = inputs.${pname};
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
    mdsh = pname:
      { stdenvNoCC }:
      let owner = "bashup";
      in stdenvNoCC.mkDerivation rec {
        inherit pname;
        version = "1.0.0.0";
        src = inputs.${pname};
        installPhase = ''
          mkdir --parents $out/bin
          cp $src/bin/${pname} $out/bin/
        '';
        meta = {
          description =
            "Multi-lingual, Markdown-based Literate Programming... in run-anywhere bash";
          homepage = "https://github.com/${Inputs.${pname}.owner}/${pname}";
          license = licenses.mit;
        };
      };

    # Adapted From: https://github.com/NixOS/nixpkgs/issues/14671#issuecomment-1016376290
    # Allows us to build `caddy' with plugins
    caddy = pname:
      { callPackage, buildGoModule, caddyPackages ? [ ]
      , withDefaultPackages ? true, sha256 ? "" }:
      let
        noPackages = caddyPackages == [ ];
        defaultPackages = [
          "github.com/mholt/${pname}-l4"
          "github.com/abiosoft/${pname}-yaml"
          "github.com/${pname}-dns/cloudflare"
        ];
        imports = concatMapStrings (pkg: "			_ \"${pkg}\"\n")
          (if withDefaultPackages then
            (defaultPackages ++ caddyPackages)
          else
            caddyPackages);
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
        vendorSha256 = if noPackages then
          "sha256-sNwXjeKqcKCxf9mktlSN6YL/xw+E1KZZ2e3mhrloZFc="
        else
          sha256;
        overrideModAttrs = (_: {
          preBuild = postPatch;
          postInstall = "cp go.sum go.mod $out/";
        });
        postPatch = "echo '${main}' > cmd/${pname}/main.go";
        postConfigure = ''
          cp vendor/go.sum ./
          cp vendor/go.mod ./
        '';
        passthru = {
          withPackages = caddyPackages': withDefaultPackages': sha256':
            callPackage callPackages.caddy {
              inherit pname;
              caddyPackages = caddyPackages';
              sha256 = sha256';
              withDefaultPackages = withDefaultPackages';
            };
          tests."${pname}" = nixosTests.${pname};
        };
        meta = {
          homepage = "https://caddyserver.com";
          description =
            "Fast, cross-platform HTTP/2 web server with automatic HTTPS";
          license = licenses.asl20;
          maintainers = with maintainers; [ Br1ght0ne ];
        };
      };

    # Adapted From: https://github.com/pukkamustard/nixpkgs/blob/guix/pkgs/development/guix/guix.nix
    guix = pname:
      { stdenv, fetchurl, hello }:
      if (iron.enableGuix stdenv.targetPlatform.system) then
        (stdenv.mkDerivation rec {
          inherit pname;
          version = "1.0.0";
          src = fetchurl {
            url =
              "https://ftp.gnu.org/gnu/guix/guix-binary-${version}.${stdenv.targetPlatform.system}.tar.xz";
            sha256 = {
              "x86_64-linux" =
                "11y9nnicd3ah8dhi51mfrjmi8ahxgvx1mhpjvsvdzaz07iq56333";
              "i686-linux" =
                "14qkz12nsw0cm673jqx0q6ls4m2bsig022iqr0rblpfrgzx20f0i";
              "aarch64-linux" =
                "0qzlpvdkiwz4w08xvwlqdhz35mjfmf1v3q8mv7fy09bk0y3cwzqs";
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
            homepage = "https://www.gnu.org/software/guix/";
            license = licenses.gpl3Plus;
            maintainers = [ maintainers.johnazoidberg ];
            platforms = [ "aarch64-linux" "i686-linux" "x86_64-linux" ];
          };
        })
      else
        hello;

    # Adapted From: https://github.com/nix-community/gomod2nix#usage
    saku = pname:
      { buildGoApplication }:
      buildGoApplication rec {
        inherit pname;
        inherit (Inputs.${pname}) version;
        src = inputs.${pname};
        modules = "${toString ./.}/go/${pname}/gomod2nix.toml";
      };
  };

  # Generated using `node2nix': https://github.com/svanderburg/node2nix#deploying-a-collection-of-npm-packages-from-the-npm-registry
  node = iron.fold.set [
    (iron.imports.set {
      dir = ./callPackages/nodejs;
      ignores.dirs = true;
    })
    (iron.mapPassName {
      uglifycss = name:
        { nodeEnv, nix-gitignore, stdenv, lib, globalBuildInputs ? [ ] }:
        let sources = { };
        in {
          ${name} = nodeEnv.buildNodePackage {
            inherit name;
            packageName = name;
            version = "0.0.29";
            src = inputs.${name};
            buildInputs = globalBuildInputs;
            meta = {
              description = "Port of YUI CSS Compressor to NodeJS";
              homepage = "https://github.com/fmarcia/${name}";
              license = "MIT";
            };
            production = true;
            bypassCache = true;
            reconstructLock = true;
          };
        };
    })
  ];

  # Generated using `yarn2nix': https://nixos.wiki/wiki/Node.js#Package_with_yarn2nix
  yarn = iron.fold.set [
    (iron.imports.set { dir = ./yarn; })
    (iron.mapPassName {
      maid = name:
        { mkYarnPackage }:
        mkYarnPackage rec {
          inherit name;
          src = inputs.${name};
          packageJSON = "${src}/package.json";
          yarnLock = "${src}/yarn.lock";
          yarnNix = "${toString ./.}/yarn/${name}/yarn.nix";
        };
    })
  ];

  emacs = iron.mapPassName (removeAttrs {
    naked = pname:
      { emacs }:
      emacs.pkgs.trivialBuild rec {
        inherit pname;
        ename = pname;
        version = "0";

        # Deprecated; kept for documentation purposes
        # src = fetchurl {
        #     url = "https://www.emacswiki.org/emacs/download/naked.el";
        #     sha256 = "sha256:0v8dv3qkiyr4vkrcmyp55l04z82sr45xai6lxbfr1wbibhz4m6j2";
        # };

        src = inputs.emacswiki;
        postPatch = ''
          TEMP=$(mktemp)
          trap "rm -rf $TEMP" EXIT
          mv ${pname}.el $TEMP
          rm -rf *
          mv $TEMP ${pname}.el
        '';
        buildInputs = flatten [ emacs propagatedUserEnvPkgs ];
        propagatedUserEnvPkgs = with emacs.pkgs; [ ];
        meta = {
          homepage = "https://www.emacswiki.org/emacs/naked.el";
          description =
            "Provide for naked key descriptions: no angle brackets.";
          inherit (emacs.meta) platforms;
        };
      };
    dired-plus = pname:
      { emacs }:
      emacs.pkgs.trivialBuild rec {
        inherit pname;
        ename = pname;
        version = "2022.11.04";
        src = inputs.emacswiki;
        buildInputs = flatten [ emacs propagatedUserEnvPkgs ];
        propagatedUserEnvPkgs = with emacs.pkgs; [ ];
        postPatch = ''
          TEMP=$(mktemp)
          trap "rm -rf $TEMP" EXIT
          mv dired+.el $TEMP
          rm -rf *
          mv $TEMP dired+.el
        '';
        meta = {
          homepage = "https://www.emacswiki.org/emacs/dired%2b.el";
          description = "Extensions to Dired.";
          inherit (emacs.meta) platforms;
        };
      };
    help-fns-plus = pname:
      { emacs }:
      emacs.pkgs.trivialBuild rec {
        inherit pname;
        ename = pname;
        version = "2022.11.04";
        src = inputs.emacswiki;
        buildInputs = flatten [ emacs propagatedUserEnvPkgs ];
        propagatedUserEnvPkgs = with emacs.pkgs; [ ];
        postPatch = ''
          TEMP=$(mktemp)
          trap "rm -rf $TEMP" EXIT
          mv help-fns+.el $TEMP
          rm -rf *
          mv $TEMP help-fns+.el
        '';
        meta = {
          homepage = "https://www.emacswiki.org/emacs/help-fns+.el";
          description = "Extensions to `help-fns.el'.";
          inherit (emacs.meta) platforms;
        };
      };
    vlfi = pname:
      { emacs }:
      emacs.pkgs.trivialBuild rec {
        inherit pname;
        ename = pname;
        version = "2022.11.04";
        src = inputs.vlfi;
        buildInputs = flatten [ emacs propagatedUserEnvPkgs ];
        propagatedUserEnvPkgs = with emacs.pkgs; [ ];
        meta = {
          homepage = "https://github.com/m00natic/vlfi";
          description = "View Large Files in Emacs";
          inherit (emacs.meta) platforms;
        };
      };
    org = pname:
      { emacs }:
      emacs.pkgs.trivialBuild rec {
        inherit pname;
        ename = pname;
        version = "9.5.6";
        src = inputs.${pname};
        buildInputs = flatten [ emacs propagatedUserEnvPkgs ];
        propagatedUserEnvPkgs = with emacs.pkgs; [ ];

        # Adapted From: https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/emacs/trivial.nix#L10
        # And: https://github.com/NixOS/nix/issues/670#issuecomment-1211700127
        buildPhase = ''
          runHook preBuild

          # TODO: Do I need one of these?
          # HOME=$(pwd)
          # HOME=$(mktemp -d)

          make all
          make autoloads

          # The following three blocks result in an org-version mismatch:

          # make ORGVERSION=${version} GITVERSION=org-${version} autoloads

          # for dir in "mk/org-fixup.el lisp/org-version.el"; do
          #     substituteInPlace $dir --replace "N/A" "${version}"
          # done

          # substituteInPlace mk/org-fixup.el --replace "N/A" "${version}"
          # substituteInPlace lisp/org-version.el --replace "N/A" "${version}"

          runHook postBuild
        '';
        installPhase = iron.mkEmacsInstallPhase "lisp/*";
        meta = {
          homepage = "https://elpa.gnu.org/packages/org.html";
          license = lib.licenses.free;
        };
      };
    org-contrib = pname:
      { emacs }:
      emacs.pkgs.trivialBuild rec {
        inherit pname;
        ename = pname;
        version = "0.3";
        src = inputs.${pname};
        buildInputs = flatten [ emacs propagatedUserEnvPkgs ];
        propagatedUserEnvPkgs = with emacs.pkgs; [ ];
        installPhase = iron.mkEmacsInstallPhase "lisp/*";
        meta = {
          homepage = "https://elpa.gnu.org/packages/org-contrib.html";
          license = lib.licenses.free;
        };
      };
  } [
    # "org"
  ]);
  python = iron.mapPassName {
    backtrace = pname:
      { buildPythonPackage, pytestCheckHook, colorama }:
      buildPythonPackage rec {
        inherit pname;
        version = iron.pyVersion src;
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
    xontrib-readable-traceback = pname:
      { buildPythonPackage, fetchPypi, colorama, backtrace }:
      buildPythonPackage rec {
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
    xonsh-autoxsh = pname:
      { buildPythonPackage, fetchPypi }:
      buildPythonPackage rec {
        inherit pname;
        version = "0.3";
        src = fetchPypi {
          inherit pname version;
          sha256 = "sha256-qwXbNbQ5mAwkZ4N+htv0Juw2a3NF6pv0XpolLIQfIe4=";
        };
        meta = {
          description =
            "Automatically execute scripts for directories in Xonsh Shell.";
          homepage = "https://github.com/Granitosaurus/${pname}";
          license = lib.licenses.mit;
        };
      };
    xonsh-direnv = pname:
      { buildPythonPackage, fetchPypi }:
      buildPythonPackage rec {
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
    xontrib-pipeliner = pname:
      { buildPythonPackage, fetchPypi, six }:
      buildPythonPackage rec {
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
          description =
            "Let your pipe lines flow thru the Python code in xonsh.";
          homepage = "https://github.com/anki-code/${pname}";
          license = lib.licenses.mit;
        };
      };
    xontrib-sh = pname:
      { buildPythonPackage, fetchPypi }:
      buildPythonPackage rec {
        inherit pname;
        version = "0.3.0";
        src = fetchPypi {
          inherit pname version;
          sha256 = "sha256-eV++ZuopnAzNXRuafXXZM7tmcay1NLBIB/U+SVrQV+U=";
        };
        meta = {
          description =
            "Paste and run commands from bash, zsh, fish, tcsh in xonsh shell.";
          homepage = "https://github.com/anki-code/${pname}";
          license = lib.licenses.mit;
        };
      };
  };
}
