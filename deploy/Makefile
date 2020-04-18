JSONNET := "jsonnet"
JCONF := ${JSONNET} -e '(import "config.jsonnet")'
GCONF := ${JCONF}.gcloud
GCLOUD_PROJECT := $(shell ${GCONF}.admin_project)
GCLOUD_SA := $(shell ${GCONF}.admin_sa)
SA_NAME := $(shell ${GCONF}.admin_sa_name)

# one off step so that we have credentials to do everything else.
terraform/tfsecrets.json: config.jsonnet
	gcloud projects create $(GCLOUD_PROJECT) \
		|| echo "project $(GCLOUD_PROJECT) already exists, continuing"
	gcloud iam service-accounts create --project="$(GCLOUD_PROJECT)" $(GCLOUD_SA) \
		|| echo "service account $(GCLOUD_SA) already exists, continuing"
	gcloud projects add-iam-policy-binding $(GCLOUD_PROJECT) \
		--member="serviceAccount:$(SA_NAME)" \
		--role="roles/owner" \
		|| echo "policy binding for $(GCLOUD_SA) to $(CGLOUD_PROJECT) already exists, continuing"
	gcloud
	gcloud iam service-accounts keys create $@ --iam-account=$(SA_NAME)

%.tf.json: %.tf.jsonnet
	${JSONNET} $< -o $@

TF_FILES := terraform/main.tf.json terraform/backend.tf.json terraform/tfsecrets.json config.jsonnet
TF := terraform

tfinit: ${TF_FILES}
	cd terraform; ${TF} init

tfplan: ${TF_FILES}
	cd terraform; ${TF} show

tfapply: ${TF_FILES}
	cd terraform; ${TF} apply

.PHONY: tfinit tfshow tfapply
