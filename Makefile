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

docker-dev:
	docker build . --target dev -t $(NAME)-dev:latest

tele:
	telepresence --swap-deployment k8s-sso \
	--docker-run --rm -it -v $(shell pwd)/app:/usr/src/app --env-file secrets.env $(NAME)-dev:latest

.PHONY: docker push docker-dev tele
