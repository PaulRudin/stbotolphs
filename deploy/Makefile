# getting the dependencies right is inherently flaky with terraform, because some state is remote,
# so we assume that people know when init needs to be run
# normally we just need to apply - we're remaking some files unncessarily, but they're cheap.
.DEFAULT_GOAL := tfapply
.PHONY: tfbootstrap tfinit tfplan tfapply

jsonnet = jsonnet

bootstrap_files = terraform/bootstrap/main.tf.json

%.tf.json: %.tf.jsonnet config.jsonnet
	$(jsonnet) $< -o $@

# one off step so that we have credentials to do everything else.
tfbootstrap: $(bootstrap_files)
	cd terraform/bootstrap; \
	terraform init; \
	terraform apply -auto-approve

tf_files = terraform/main/main.tf.json terraform/main/backend.tf.json
tf = terraform

tfinit: $(tf_files)
	cd terraform/main; $(tf) init


tfplan: $(tf_files)
	cd terraform/main; $(tf) plan

tfshow: $(tf_files)
	cd terraform/main; $(tf) show

tfapply: $(tf_files)
	cd terraform/main; $(tf) apply


tfdestroy: $(tf_files)
	cd terraform/main; $(tf) destroy
