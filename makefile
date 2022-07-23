.RECIPEPREFIX := |
.DEFAULT_GOAL := tangle

define nixShell
nix-shell -E '(import ./.).devShells.$${builtins.currentSystem}.makeshell-$1' --show-trace --run
endef

mkfilePath := $(abspath $(lastword $(MAKEFILE_LIST)))
mkfileDir := $(dir $(mkfilePath))
realfileDir := $(realpath $(mkfileDir))
type := $(shell nix eval --impure --expr '(import ./.).type' || echo "general" | tr -d '"')
projectName := $(shell echo $$(nix eval --impure --expr '(import ./.).pname' || echo $$(cat $(mkfileDir)/pyproject.toml | tomlq .tool.poetry.name) || basename $(mkfileDir)) | tr -d '"')

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

tangle:
|$(call nixShell,general) "org-tangle $(mkfileDir)/README.org $(mkfileDir)/flake.org"

quick: tangle push

super: tangle update push

super-master: tangle update-master push
