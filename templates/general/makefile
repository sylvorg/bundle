.RECIPEPREFIX := |
.DEFAULT_GOAL := tangle

mkfilePath := $(abspath $(lastword $(MAKEFILE_LIST)))
mkfileDir := $(dir $(mkfilePath))

export PATH := $(shell echo '$$PATH' |  nix-shell -E '(import ./.).devShells.$${builtins.currentSystem}.makefile' --show-trace)
export PYTHONPATH := $(shell echo '$$PYTHONPATH' | nix-shell -E '(import ./.).devShells.$${builtins.currentSystem}.makefile' --show-trace)

tangle:
|org-tangle $(mkfileDir)/nix.org

commit:
|git -C $(mkfileDir) commit --allow-empty-message -am ""

push: commit
|git -C $(mkfileDir) push
