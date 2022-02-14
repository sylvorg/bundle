.RECIPEPREFIX := |
.DEFAULT_GOAL := super-push

# Adapted From: https://www.systutorials.com/how-to-get-the-full-path-and-directory-of-a-makefile-itself/
mkfilePath := $(abspath $(lastword $(MAKEFILE_LIST)))
mkfileDir := $(dir $(mkfilePath))

pre-init:
|-fd . $(mkfileDir)/.. -HIt d -t e -x rm -rf

tangle-setup:
|cp $(mkfileDir)/org-tangle.sh $(mkfileDir)/backup-tangle.sh
|chmod +x $(mkfileDir)/org-tangle.sh $(mkfileDir)/backup-tangle.sh

tangle: tangle-setup
|yes yes | fd . $(mkfileDir)/.. \
    -HId 1 -e org \
    -x $(mkfileDir)/backup-tangle.sh
|fd . $(mkfileDir) \
    -HIe sh \
    -x chmod +x

pull: subinit
|git -C $(mkfileDir)/.. pull

add:
|git -C $(mkfileDir)/.. add .

commit:
|-git -C $(mkfileDir)/.. commit --allow-empty-message -am ""

cammit: pre-init add commit

push: cammit
|-git -C $(mkfileDir)/.. remote set-url --push origin git@github.com:shadowrylander/$$(basename `git -C $(mkfileDir)/.. config --get remote.origin.url`)
|-git -C $(mkfileDir)/.. push 2>/dev/null || git -C $(mkfileDir)/.. push origin HEAD:$$(git -C $(mkfileDir)/.. remote show origin | grep "HEAD branch" | sed 's/.*: //')

push-me: tangle-setup
|yes yes | fd . $(mkfileDir) \
    -HId 1 -e org \
    -x $(mkfileDir)/backup-tangle.sh
|fd . $(mkfileDir) \
    -HIe sh \
    -x chmod +x
|-fd . $(mkfileDir) -HIt d -t e -x rm -rf
|git -C $(mkfileDir) add .
|-git -C $(mkfileDir) commit --allow-empty-message -am ""
|-git -C $(mkfileDir) remote set-url --push origin git@github.com:shadowrylander/$$(basename `git -C $(mkfileDir) config --get remote.origin.url`)
|-git -C $(mkfileDir) push 2>/dev/null || git -C $(mkfileDir) push origin HEAD:$$(git -C $(mkfileDir) remote show origin | grep "HEAD branch" | sed 's/.*: //')

super-push: tangle push
