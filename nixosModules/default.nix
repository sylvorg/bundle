lib:
with lib; rec {
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
  options = args@{ config, options, pkgs, system, ... }: {
    options = {

      # Adapted From: https://discourse.nixos.org/t/variables-for-a-system/2342/6
      # And: https://discourse.nixos.org/t/variables-for-a-system/2342/12
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
          default = (!config.variables.server) && (!config.variables.relay);
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

        # Adapted From: https://github.com/pukkamustard/nixpkgs/blob/guix/nixos/modules/services/development/guix.nix
        guix = mkIf (iron.enableGuix system) {
          enable = mkEnableOption "GNU Guix package manager";
          package = mkOption {
            type = types.package;
            default = pkgs.guix;
            defaultText = "pkgs.guix";
            description =
              "Package that contains the guix binary and initial store.";
          };
        };
      };
    };
    imports = [ var ];
    config = mkMerge [

      # Adapted From: https://discourse.nixos.org/t/variables-for-a-system/2342/6
      # And: https://discourse.nixos.org/t/variables-for-a-system/2342/12
      { _module.args.variables = config.variables; }

      (let cfg = config.programs.mosh;
      in mkIf cfg.enable {
        networking.firewall.allowedUDPPortRanges = optional cfg.openFirewall {
          from = 60000;
          to = 61000;
        };
      })

      # Adapted From: https://github.com/pukkamustard/nixpkgs/blob/guix/nixos/modules/services/development/guix.nix
      (let cfg = config.services.guix;
      in mkIf cfg.enable {
        users = {
          extraUsers = iron.fold.set (map buildGuixUser (lib.range 1 10));
          extraGroups.guixbuild = { name = "guixbuild"; };
        };
        systemd.services.guix-daemon = {
          enable = true;
          description = "Build daemon for GNU Guix";
          serviceConfig = {
            ExecStart =
              "/var/guix/profiles/per-user/root/current-guix/bin/guix-daemon --build-users-group=guixbuild";
            Environment =
              "GUIX_LOCPATH=/var/guix/profiles/per-user/root/guix-profile/lib/locale";
            RemainAfterExit = "yes";

            # See <https://lists.gnu.org/archive/html/guix-devel/2016-04/msg00608.html>.
            # Some package builds (for example, go@1.8.1) may require even more than
            # 1024 tasks.
            TasksMax = "8192";
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

  # Adapted From: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/system/etc/etc-activation.nix
  # And: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/system/etc/etc.nix
  var = { config, pkgs, ... }:
    let
      var' = filter (f: f.enable) (attrValues config.environment.vars);
      var = pkgs.runCommandLocal "var" {
        # This is needed for the systemd module
        passthru.targets = map (x: x.target) var';
      } # sh
        ''
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
          ${concatMapStringsSep "\n" (varEntry:
            escapeShellArgs [
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
          default = { };
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
          type = with types;
            attrsOf (submodule ({ name, config, options, ... }: {
              options = {
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
                source = mkIf (config.text != null)
                  (let name' = "var-" + baseNameOf name;
                  in mkDerivedConfig options.text (pkgs.writeText name'));
              };
            }));
        };
      };
      config = {
        system = {
          activationScripts.vars = lib.stringAfter [ "users" "groups" ]
            config.system.build.varActivationCommands;
          build = {
            var = var;
            varActivationCommands = ''
              # Set up the statically computed bits of /var.
              echo "setting up /var..."
              ${pkgs.perl.withPackages (p: [ p.FileSlurp ])}/bin/perl ${
                ./setup-var.pl
              } ${var}/var
            '';
          };
        };
      };
    };
}
