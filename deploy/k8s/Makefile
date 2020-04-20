.ONESHELL:

mkfile_dir := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

kdir := ./envs/$(env)/

KUBECFG := kubecfg -V "env=$(env)" -J $(mkfile_dir) -J $(mkfile_dir)vendor --context $(env)
JSONNET := jsonnet -J $(mkfile_dir)

%secrets.sealed.json: %secrets.json
	$(JSONNET) --tla-code-file 'secrets=$<' utils/secrets.jsonnet|kubeseal --cert $(@D)/kubeseal-public-cert.pem -o json > $@

show:
	cd $(kdir)
	$(KUBECFG) show all.jsonnet

update:
	cd $(kdir)
	$(KUBECFG) update --ignore-unknown all.jsonnet

diff:
	cd $(kdir)
	$(KUBECFG) diff --diff-strategy=subset all.jsonnet


JS_FILES := $(wildcard *.jsonnet)

fmt: $(JS_FILES:%=%-fmt)
fmttest: $(JS_FILES:%=%-fmttest)

%-fmt: %
	jsonnetfmt -i -- $<

%-fmttest: %
	jsonnetfmt --test $<

.PHONY: show update diff %-fmt %-fmttest fmt fmttest
