.RECIPEPREFIX := |
.DEFAULT_GOAL := tangle

define nixShell
nix-shell -E '(import ./.).devShells.$${builtins.currentSystem}.makeshell-$1' --show-trace --run
endef

mkfilePath := $(abspath $(lastword $(MAKEFILE_LIST)))
mkfileDir := $(dir $(mkfilePath))
realfileDir := $(realpath $(mkfileDir))
type := $(shell echo $$(nix eval --impure --expr '(import ./.).type' || echo "general") | tr -d '"')
projectName := $(shell echo $$(nix eval --impure --expr '(import ./.).pname' || echo $$(cat $(mkfileDir)/pyproject.toml | tomlq .tool.poetry.name) || basename $(mkfileDir)) | tr -d '"')

add:
|git -C $(mkfileDir) add .

commit: add
|git -C $(mkfileDir) commit --allow-empty-message -am ""

push: commit
|git -C $(mkfileDir) push

update-settings:
|nix flake lock --update-input settings || :

files := $(mkfileDir)/nix.org $(mkfileDir)/flake.org $(mkfileDir)/tests.org

ifeq ($(projectName), settings)
files := $(files) $(mkfileDir)/README.org
else
files := $(files) $(mkfileDir)/$(projectName)
endif

tangle: update-settings
|$(call nixShell,general) "org-tangle -f $(files)"

update:
ifeq ($(projectName), settings)
|$(shell nix eval --impure --expr 'with (import ./.); with pkgs.$${builtins.currentSystem}.lib; "nix flake lock --update-input $${concatStringsSep " --update-input " (filter (input: ! (elem input [ "nixos-master" ])) (attrNames inputs))}"' | tr -d '"')
else
|nix flake update
endif

quick: tangle push

poetry2setup:
|$(call nixShell,$(type)) "cd $(mkfileDir) && poetry2setup > $(mkfileDir)/setup.py && cd -"

test: tangle update
|$(call nixShell,$(type)) pytest

super: test push
