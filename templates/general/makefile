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
tangleTask := make -nf $(mkfilePath) test && echo test || echo tangle

add:
|git -C $(mkfileDir) add .

commit: add
|git -C $(mkfileDir) commit --allow-empty-message -am ""

push: commit
|git -C $(mkfileDir) push

update-%: updateInput := nix flake lock --update-input
update-%:
|$(eval input := $(shell echo $@ | cut -d "-" -f2-))
ifeq ($(input), settings)
|$(updateInput) $(input) || :
else ifeq ($(input), all)
|nix flake update
else
|$(updateInput) $(input)
endif

files := $(mkfileDir)/nix.org $(mkfileDir)/flake.org $(mkfileDir)/tests.org $(mkfileDir)/README.org $(mkfileDir)/$(projectName)

tangle: update-settings
|$(call nixShell,general) "org-tangle -f $(files)"

update:
ifeq ($(projectName), settings)
|$(shell nix eval --impure --expr 'with (import ./.); with pkgs.$${builtins.currentSystem}.lib; "nix flake lock --update-input $${concatStringsSep " --update-input " (filter (input: ! ((elem input [ "nixos-master" ]) || (hasSuffix "-small" input))) (attrNames inputs))}"' | tr -d '"')
else
|nix flake update
endif

quick: tangle push

super: $(shell $(tangleTask)) update push

super-%: $(shell $(tangleTask)) update-% push ;
