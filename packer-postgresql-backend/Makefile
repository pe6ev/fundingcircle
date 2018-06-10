.DEFAULT_GOAL := build

define packer
	mkdir -p log
 	packer $(1) packer.json | tee log/build.log
endef

.PHONY: clean
clean:
	@rm -rf log

.PHONY: prepare
prepare:
	#ansible-galaxy install -f -r cm/ansible/requirements.yml

.PHONY: validate
validate: clean
	@$(call packer,validate)

.PHONY: build
build: validate prepare
	@$(call packer,build)
