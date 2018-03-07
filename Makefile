# If the USE_SUDO_FOR_DOCKER env var is set, prefix docker commands with 'sudo'
ifdef USE_SUDO_FOR_DOCKER
	SUDO_CMD = sudo
endif

IMAGE ?= quay.io/eriknelson/servicebroker
TAG ?= $(shell git describe --tags --always)
PULL ?= IfNotPresent

build:
	go build -i github.com/eriknelson/nsk-broker/cmd/servicebroker

test:
	go test -v $(shell go list ./... | grep -v /vendor/ | grep -v /test/)

linux:
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 \
	go build -o servicebroker-linux --ldflags="-s" github.com/eriknelson/nsk-broker/cmd/servicebroker

image: linux
	cp servicebroker-linux image/servicebroker
	$(SUDO_CMD) docker build image/ -t "$(IMAGE):$(TAG)"

clean:
	rm -f servicebroker
	rm -f servicebroker-linux

push: image
	$(SUDO_CMD) docker push "$(IMAGE):$(TAG)"

deploy-openshift: image
	oc new-project nsk-broker
	oc process -f openshift/starter-pack.yaml -p IMAGE=$(IMAGE):$(TAG) | oc create -f -

create-ns:
	kubectl create ns test-ns

provision: create-ns
	kubectl apply -f manifests/service-instance.yaml

bind:
	kubectl apply -f manifests/service-binding.yaml

.PHONY: build test linux image clean push deploy-openshift create-ns provision bind
