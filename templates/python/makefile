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

tangle-python: tangle
|org-tangle $(mkfileDir)/$$(cat $(mkfileDir)/pyproject.toml | tomlq .tool.poetry.name | tr -d '"') $(mkfileDir)/tests.org

test: tangle-python
|hy $(mkfileDir)/tests.hy

poetry2setup:
|poetry2setup > $(mkfileDir)/setup.py
