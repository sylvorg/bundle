self: inputs: lib: pname:
with lib;
let
  overlayset = iron.functors.xelf (import ../overlays self inputs lib);
  preMkOutputs = inputs.valiant.mkOutputs.base overlayset.overlays pname lib
    (import ../languages inputs lib);
in preMkOutputs.general {
  inherit self inputs pname overlayset;
  inherit (inputs.flake-registry) registry;
  patches = lib.iron.imports.set {
    dir = ./patches;
    ignores.dirs = true;
    suffix = ".patch";
    files = true;
  };
  templates = let
    allTemplates = mapAttrs (n: path: {
      description = "The ${n} template!";
      inherit path;
    }) (iron.imports.set {
      dir = ../templates;
      ignores.files = true;
      files = true;
    });
  in iron.fold.set [ allTemplates { default = allTemplates.python-package; } ];
  defaultTemplate = self.templates.default;
  template = self.defaultTemplate;
  profiles = {

    # Adapted From: https://github.com/hlissner/dotfiles/blob/master/hosts/linode.nix
    # And: https://www.linode.com/docs/guides/install-nixos-on-linode/#prepare-your-linode
    server = { config, pkgs, ... }:
      let
        relayNo = if config.variables.relay then "no" else "yes";
        relayYes = if config.variables.relay then "yes" else "no";
      in {
        imports = attrValues nixosModules;
        environment.systemPackages = with pkgs; [ inetutils mtr sysstat git ];
        variables.server = true;
      };

  };

  devices = {

    # Adapted From: https://github.com/hlissner/dotfiles/blob/master/hosts/linode.nix
    # And: https://www.linode.com/docs/guides/install-nixos-on-linode/#prepare-your-linode
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

    # Adapted From: https://nixos.wiki/wiki/NixOS_on_ARM/Raspberry_Pi_3
    rpi3 = { config, pkgs, ... }: {
      imports = toList profiles.server;
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
          ExecStart =
            "${pkgs.bluez}/bin/btattach -B /dev/ttyAMA0 -P bcm -S 3000000";
        };
      };
      boot.kernelModules = [ "bcm2835-v4l2" ];
      boot.initrd.kernelModules = [ "vc4" "bcm2835_dma" "i2c_bcm2835" ];
    };

    rpi4 = { config, pkgs, ... }: {
      imports = flatten [ profiles.server inputs.hardware.raspberry-pi-4 ];
      boot.kernelPackages = mkForce pkgs.linuxPackages_rpi4;
    };
  };

  callPackageset = import ../callPackages inputs lib;
  nixosModules = import ../nixosModules lib;
  defaultNixosModule = self.nixosModules.default;
  nixosModule = self.defaultNixosModule;
  mkOutputs = inputs.valiant.mkOutputs.base self.overlays self.pname lib
    (import ../languages inputs lib);
  callPackage = packages@{ stdenv, runCommandLocal, makeWrapper, libuuid
    , emacs-nox, pandoc }:
    let
      orgs = listToAttrs
        (map (o: nameValuePair "$src/bin/org-${o}" "$out/bin/org-${o}") [
          "tangle"
          "export"
          "interpreter"
        ]);
    in stdenv.mkDerivation rec {
      inherit (self) pname;
      version = "1.0.0.0";
      src = ./..;
      phases = [ "installPhase" ];
      buildInputs = [ makeWrapper ];
      installPhase = with inputs;
        let
          quote = pkg: ''"${pkg}"'';
          tangle-load-path =
            concatMapStringsSep " " quote [
              uuidgen
              a
              dash
              s
              f
              (fetchGit {
                url = "https://github.com/syvlorg/riot.git";
                rev = "75f9e3aa263af9783efb00314a7eb00a5900bc91";
              })
            ];
          export-load-path = concatMapStringsSep " " quote [ htmlize ];
        in ''
          mkdir --parents $out/bin
          cp $src/README.org $out/bin/README.ORG
          ${concatStringsSep "\n" (mapAttrsToList
            (n: v: "cp ${n} ${v}; chmod +x ${v}; patchShebangs ${v}") orgs)}
          echo '(setq load-path `(,@load-path ${tangle-load-path}))' > $out/bin/org-tangle-functions.el
          cat $src/bin/org-tangle-functions.el >> $out/bin/org-tangle-functions.el
          echo '(setq load-path `(,@load-path ${export-load-path}))' > $out/bin/org-export-functions.el
          cat $src/bin/org-export-functions.el >> $out/bin/org-export-functions.el
          substituteInPlace $out/bin/org-tangle-functions.el --replace "(link-or-file nix-path return-link)" "(link-or-file \"$out/bin/README.org\" return-link)"
          substituteInPlace $out/bin/org-tangle --replace "(load-file (concat (file-name-directory (or load-file-name buffer-file-name)) \"org-tangle-functions.el\"))" "(load-file \"$out/bin/org-tangle-functions.el\")"
          substituteInPlace $out/bin/org-export --replace "(load-file (concat (file-name-directory (or load-file-name buffer-file-name)) \"org-export-functions.el\"))" "(load-file \"$out/bin/org-export-functions.el\")"
          ${concatMapStringsSep "\n" (o: "wrapProgram ${o} $makeWrapperArgs")
          (attrValues orgs)}
        '';
      meta.mainProgram = "org-tangle";
      makeWrapperArgs = toList "--set PATH ${
          makeBinPath (map (pkg:
            if (elem stdenv.targetPlatform.system
              (attrNames inputs.nixpkgs.legacyPackages)) then
              inputs.nixpkgs.legacyPackages.${stdenv.targetPlatform.system}.${pkg}
            else
              packages.${pkg}) [ "emacs-nox" "pandoc" ])
        }";
    };
} {
  inherit lib;
  languages = true;
}
