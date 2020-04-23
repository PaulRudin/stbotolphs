GIT_SHA := $(shell git rev-parse --short HEAD)

REGISTRY := $(shell jsonnet -e "(import 'deploy/tfdata.json').registry")
NAME :=  webapp
IMAGE_NAME := $(REGISTRY)/$(NAME)
LOCAL_TAGS := -t $(NAME):$(GIT_SHA) -t $(NAME):latest
REG_TAGS := -t $(IMAGE_NAME):$(GIT_SHA) -t $(IMAGE_NAME):latest

docker:
	docker build . $(LOCAL_TAGS) $(REG_TAGS)

push: docker
	docker push $(IMAGE_NAME)


.PHONY: docker push docker-dev tele
