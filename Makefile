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

.score-compose/state.yaml:
	score-compose init \
		--no-sample \
		--provisioners https://raw.githubusercontent.com/score-spec/community-provisioners/refs/heads/main/score-compose/10-service.provisioners.yaml \
		--provisioners https://raw.githubusercontent.com/score-spec/community-provisioners/refs/heads/main/score-compose/10-redis-dapr-state-store.provisioners.yaml

compose.yaml: services/notifications/score.yaml services/order-processor/score.yaml services/payments/score.yaml services/shipping/score.yaml .score-compose/state.yaml Makefile
	score-compose generate \
		services/notifications/score.yaml \
		--build 'notifications={"context":"services/notifications/","tags":["notifications:latest"]}'
	
	score-compose generate \
		services/order-processor/score.yaml \
		--build 'order-processor={"context":"services/order-processor/","tags":["order-processor:latest"]}'
	
	score-compose generate \
		services/payments/score.yaml \
		--build 'payments={"context":"services/payments/","tags":["payments:latest"]}'
	
	score-compose generate \
		services/shipping/score.yaml \
		--build 'shipping={"context":"services/shipping/","tags":["shipping:latest"]}'
	
	scripts/inject-dapr-sidecar.sh
	scripts/inject-dapr-placement.sh

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
		--no-sample

manifests.yaml: score/score.yaml .score-k8s/state.yaml Makefile
	score-k8s generate score/score.yaml \
		--image ${CONTAINER_IMAGE} \
		--override-property containers.${CONTAINER_NAME}.variables.MESSAGE="Hello, Kubernetes!" \
		--patch-manifests 'Deployment/*/spec.template.spec.automountServiceAccountToken=false' \
		--patch-manifests 'Deployment/*/spec.template.spec.securityContext={"fsGroup":65532,"runAsGroup":65532,"runAsNonRoot":true,"runAsUser":65532,"seccompProfile":{"type":"RuntimeDefault"}}'
	echo '{"spec":{"template":{"spec":{"containers":[{"name":"${CONTAINER_NAME}","securityContext":{"allowPrivilegeEscalation":false,"privileged": false,"readOnlyRootFilesystem": true,"capabilities":{"drop":["ALL"]}}}]}}}}' > deployment-patch.yaml

## Create a local Kind cluster.
.PHONY: kind-create-cluster
kind-create-cluster:
	./scripts/setup-kind-cluster.sh

## Load the local container image in the current Kind cluster.
.PHONY: kind-load-image
kind-load-image:
	kind load docker-image ${CONTAINER_IMAGE}

NAMESPACE ?= default
## Generate a manifests.yaml file from the score spec, deploy it to Kubernetes and wait for the Pods to be Ready.
.PHONY: k8s-up
k8s-up: manifests.yaml
	kubectl apply \
		-f manifests.yaml \
		-n ${NAMESPACE}
	kubectl patch \
		deployment ${WORKLOAD_NAME} \
		--patch-file deployment-patch.yaml \
		-n ${NAMESPACE}
	kubectl wait deployments/${WORKLOAD_NAME} \
		-n ${NAMESPACE} \
		--for condition=Available \
		--timeout=90s
	kubectl wait pods \
		-n ${NAMESPACE} \
		-l app.kubernetes.io/name=${WORKLOAD_NAME} \
		--for condition=Ready \
		--timeout=90s

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