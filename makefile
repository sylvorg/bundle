.RECIPEPREFIX := |
.DEFAULT_GOAL := tangle

mkfilePath := $(abspath $(lastword $(MAKEFILE_LIST)))
mkfileDir := $(dir $(mkfilePath))
realfileDir := $(realpath $(mkfileDir))

define exportSettings
export PATH := $(shell nix-shell -E 'with (import ./.).pkgs.$${builtins.currentSystem}; mkShell { buildInputs = lib.toList settings; shellHook = "echo $$PATH; exit"; }'):$(PATH)
export SHELL := $(shell which sh)
endef

define exportPathShell
export PATH := $(shell nix-shell -E '(import $(realfileDir)).devShells.$${builtins.currentSystem}.makefile' --show-trace):$(PATH)
export SHELL := $(shell which sh)
endef

add:
|git -C $(mkfileDir) add .

commit: add
|git -C $(mkfileDir) commit --allow-empty-message -am ""

push: commit
|git -C $(mkfileDir) push

update:
|$(shell nix eval --impure --expr 'with (import ./.); with pkgs.$${builtins.currentSystem}.lib; "nix flake lock --update-input $${concatStringsSep " --update-input " (filter (input: ! (elem input [ "nixos-master" ])) (attrNames inputs))}"' | tr -d '"')

update-master:
|nix flake update

tangle: $(eval $(call exportSettings))
|org-tangle $(mkfileDir)/README.org $(mkfileDir)/flake.org

quick: tangle push

super: tangle update push

super-master: tangle update-master push
