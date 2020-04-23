# getting the dependencies right is inherently flaky with terraform, because some state is remote,
# so we assume that people know when init needs to be run
# normally we just need to apply - we're remaking some files unncessarily, but they're cheap.
.DEFAULT_GOAL := tfapply
.PHONY: tfbootstrap tfinit tfplan tfapply tfshow tfdestroy install_tools bootstrap

makefile_dir := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))


project := $(shell jsonnet -e '(import "$(makefile_dir)config.jsonnet").gcloud.project')
github_user := $(shell jsonnet -e '(import "$(makefile_dir)config.jsonnet").github.user')
github_repo := $(shell jsonnet -e '(import "$(makefile_dir)config.jsonnet").github.repo')

bootstrap: install_tools tfbootstrap tfinit tfapply
	cd k8s && $(MAKE) env=base update 


install_tools:
	scripts/install_jsonnet.sh
	scripts/install_kubecfg.sh
	scripts/install_kubectl.sh
	scripts/install_kubeseal.sh
	scripts/install_sops.sh
	scripts/install_yq.sh
	scripts/install_fluxctl.sh

jsonnet = jsonnet

bootstrap_files = terraform/bootstrap/main.tf.json

js_files := $(shell find . -type f -name '*.jsonnet')
%.tf.json: %.tf.jsonnet $(js_files)
	$(jsonnet) $< -o $@


tf_dir = $(makefile_dir)terraform/main/
tf_files := $(tf_dir)main.tf.json $(tf_dir)backend.tf.json
tf_triggers := $(js_files) $(tf_files)
creds_file := $(tf_dir)tfsecrets.json

# one off step so that we have credentials to do everything else.
tfbootstrap: $(bootstrap_files)
	cd terraform/bootstrap; \
	terraform init; \
	terraform apply -auto-approve


tf := GOOGLE_APPLICATION_CREDENTIALS=$(creds_file) terraform

tfinit: $(tf_triggers)
	cd $(tf_dir); $(tf) init

tfplan: $(tf_triggers)
	cd $(tf_dir); $(tf) plan

tfshow: $(tf_triggers)
	cd $(tf_dir); $(tf) show

tfapply: $(tf_triggers)
	cd $(tf_dir); $(tf) apply -auto-approve

tfdestroy: $(tf_triggers)
	cd $(tf_dir); $(tf) destroy
