include: $(dir $(abspath $(lastword $(MAKEFILE_LIST))))/include.mk

poetry2setup: tu
|$(call nixShell,$(type)) "cd $(mkfileDir) && poetry2setup > $(mkfileDir)/setup.py && cd -"

touch-tests:
|-find $(mkfileDir)/tests -print | grep -v __pycache__ | xargs touch

tut: tu touch-tests

define pytest
$(call nixShell,$(type)) "pytest $1 --suppress-no-test-exit-code $(mkfileDir)"
endef

test: tut
|$(call pytest)

test-native: tut
|$(call pytest,--tb=native)

test-%: tut
|$(call pytest,-m $(call wildcardValue,$@))

super: test push
