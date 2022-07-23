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

update:
|nix flake update

tangle:
|$(call nixShell,general) "org-tangle $(mkfileDir)/nix.org"

tangle-python: tangle
|$(call nixShell,general) "org-tangle $(mkfileDir)/$(projectName) $(mkfileDir)/tests.org"

poetry2setup:
|$(call nixShell,$(type)) "cd $(mkfileDir) && poetry2setup > $(mkfileDir)/setup.py && cd -"

test: tangle-python update 
|$(call nixShell,$(type)) pytest

quick: tangle-python push

super: test push
