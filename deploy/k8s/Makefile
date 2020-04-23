.ONESHELL:

mkfile_dir := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

kdir := ./envs/$(env)/

KUBECFG := kubecfg -V "env=$(env)" -J $(mkfile_dir) -J $(mkfile_dir)vendor
JSONNET := jsonnet -J $(mkfile_dir) -J $(mkfile_dir)vendor 

%secrets.json: %secrets.enc.json
	sops -d $< > $@

%secrets.sealed.json: %secrets.json
	$(JSONNET) --tla-code-file 'secrets=$<' utils/secrets.jsonnet|kubeseal --scope cluster-wide --cert ./kubeseal-public-cert.pem -o json > $@


encrypted_secrets = $(shell find . -type f -name '*secrets.enc.json')
decrypted_secrets = $(encrypted_secrets:.enc.json=.json)
sealed_secrets = $(decrypted_secrets:.json=.sealed.json)

seal: $(sealed_secrets)

show: $(sealed_secrets)
	@cd $(kdir)
	@$(KUBECFG) show all.jsonnet

update: $(sealsed_secrets)
	cd $(kdir)
	$(KUBECFG) update --ignore-unknown all.jsonnet

diff: $(sealed_secrets)
	cd $(kdir)
	$(KUBECFG) diff --diff-strategy=subset all.jsonnet


JS_FILES := $(wildcard *.jsonnet)

fmt: $(JS_FILES:%=%-fmt)
fmttest: $(JS_FILES:%=%-fmttest)

%-fmt: %
	jsonnetfmt -i -- $<

%-fmttest: %
	jsonnetfmt --test $<

.PHONY: show update diff %-fmt %-fmttest fmt fmttest decrypt_secrets seal
