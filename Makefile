GIT_SHA := $(shell git rev-parse --short HEAD)
GIT_TAG := $(shell git describe --tags --abbrev=0 --dirty)
REGISTRY := $(shell jsonnet -e "(import 'deploy/k8s/tfdata.json').registry")
NAME :=  webapp
IMAGE_NAME := $(REGISTRY)/$(NAME)
LOCAL_TAGS := -t $(NAME):$(GIT_SHA) -t $(NAME):latest -t $(NAME):$(GIT_TAG)
REG_TAGS := -t $(IMAGE_NAME):$(GIT_SHA) -t $(IMAGE_NAME):latest -t $(IMAGE_NAME):$(GIT_TAG)

docker:
	docker build . $(LOCAL_TAGS) $(REG_TAGS)

push: docker
	docker push $(IMAGE_NAME)


.PHONY: docker push docker-dev tele
