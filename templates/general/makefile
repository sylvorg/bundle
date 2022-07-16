.RECIPEPREFIX := |
.DEFAULT_GOAL := tangle

mkfilePath := $(abspath $(lastword $(MAKEFILE_LIST)))
mkfileDir := $(dir $(mkfilePath))
realfileDir := $(realpath $(mkfileDir))

export PATH := $(shell nix-shell -E 'with builtins; ((builtins.getFlake or import) (toString $(realfileDir))).devShells.$${currentSystem}.makefile' --show-trace)

tangle:
|org-tangle $(mkfileDir)/nix.org

add:
|git add .

commit: add
|git -C $(mkfileDir) commit --allow-empty-message -am ""

push: commit
|git -C $(mkfileDir) push
