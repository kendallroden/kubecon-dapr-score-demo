# Disable all the default make stuff
MAKEFLAGS += --no-builtin-rules
.SUFFIXES:

## Display a list of the documented make targets
.PHONY: help
help:
	@echo Documented Make targets:
	@perl -e 'undef $$/; while (<>) { while ($$_ =~ /## (.*?)(?:\n# .*)*\n.PHONY:\s+(\S+).*/mg) { printf "\033[36m%-30s\033[0m %s\n", $$2, $$1 } }' $(MAKEFILE_LIST) | sort

.PHONY: .FORCE
.FORCE:

dapr-up:
	dapr init || true
	dapr run -f . 

.score-compose/state.yaml:
	score-compose init \
		--no-sample \
		--provisioners https://raw.githubusercontent.com/score-spec/community-provisioners/refs/heads/main/score-compose/10-redis-dapr-state-store.provisioners.yaml \
		--provisioners https://raw.githubusercontent.com/score-spec/community-provisioners/refs/heads/main/score-compose/10-redis-dapr-pubsub.provisioners.yaml \
		--provisioners https://raw.githubusercontent.com/score-spec/community-provisioners/refs/heads/main/score-compose/10-dapr-subscription.provisioners.yaml \
		--patch-templates https://raw.githubusercontent.com/score-spec/community-patchers/refs/heads/main/score-compose/dapr.tpl

compose.yaml: services/inventory/score.yaml services/notifications/score.yaml services/order-processor/score.yaml services/payments/score.yaml services/shipping/score.yaml .score-compose/state.yaml Makefile
	score-compose generate \
		services/inventory/score.yaml \
		--build 'inventory={"context":"services/inventory/","tags":["inventory:local"]}'
	
	score-compose generate \
		services/notifications/score.yaml \
		--build 'notifications={"context":"services/notifications/","tags":["notifications:local"]}'
	
	score-compose generate \
		services/order-processor/score.yaml \
		--build 'order-processor={"context":"services/order-processor/","tags":["order-processor:local"]}'
	
	score-compose generate \
		services/payments/score.yaml \
		--build 'payments={"context":"services/payments/","tags":["payments:local"]}'
	
	score-compose generate \
		services/shipping/score.yaml \
		--build 'shipping={"context":"services/shipping/","tags":["shipping:local"]}'

## Generate a compose.yaml file from the score spec and launch it.
.PHONY: compose-up
compose-up: compose.yaml
	docker compose up --build -d --remove-orphans
	sleep 5

## Generate a compose.yaml file from the score spec, launch it and test (curl) the exposed container.
.PHONY: compose-test
compose-test: compose-up
	curl $$(score-compose resources get-outputs dns.default#${WORKLOAD_NAME}.dns --format '{{ .host }}:8080')

## Delete the containers running via compose down.
.PHONY: compose-down
compose-down:
	docker compose down -v --remove-orphans || true

.score-k8s/state.yaml:
	score-k8s init \
		--provisioners https://raw.githubusercontent.com/score-spec/community-provisioners/refs/heads/main/score-k8s/10-redis-dapr-state-store.provisioners.yaml \
		--provisioners https://raw.githubusercontent.com/score-spec/community-provisioners/refs/heads/main/score-k8s/10-redis-dapr-pubsub.provisioners.yaml \
		--provisioners https://raw.githubusercontent.com/score-spec/community-provisioners/refs/heads/main/score-k8s/10-dapr-subscription.provisioners.yaml \
		--no-sample

manifests.yaml: services/inventory/score.yaml services/notifications/score.yaml services/order-processor/score.yaml services/payments/score.yaml services/shipping/score.yaml .score-k8s/state.yaml Makefile
	score-k8s generate services/inventory/score.yaml \
		--image inventory:local

	score-k8s generate services/notifications/score.yaml \
		--image notifications:local
	
	score-k8s generate services/order-processor/score.yaml \
		--image order-processor:local
	
	score-k8s generate services/payments/score.yaml \
		--image payments:local
	
	score-k8s generate services/shipping/score.yaml \
		--image shipping:local

## Create a local Kind cluster.
.PHONY: kind-create-cluster
kind-create-cluster:
	./scripts/setup-kind-cluster.sh

## Load the local container image in the current Kind cluster.
.PHONY: kind-load-image
kind-load-image:
	kind load docker-image inventory:local
	kind load docker-image notifications:local
	kind load docker-image order-processor:local
	kind load docker-image payments:local
	kind load docker-image shipping:local

NAMESPACE ?= default
## Generate a manifests.yaml file from the score spec, deploy it to Kubernetes and wait for the Pods to be Ready.
.PHONY: k8s-up
k8s-up: manifests.yaml
	kubectl apply \
		-f manifests.yaml \
		-n ${NAMESPACE}

## Expose the container deployed in Kubernetes via port-forward.
.PHONY: k8s-test
k8s-test: k8s-up
	curl $$(score-k8s resources get-outputs dns.default#${WORKLOAD_NAME}.dns --format '{{ .host }}')

## Delete the deployment of the local container in Kubernetes.
.PHONY: k8s-down
k8s-down:
	kubectl delete \
		-f manifests.yaml \
		-n ${NAMESPACE}