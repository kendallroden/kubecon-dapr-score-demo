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
	score-compose init --no-sample \
		--provisioners https://raw.githubusercontent.com/score-spec/community-provisioners/refs/heads/main/score-compose/10-redis-dapr-state-store.provisioners.yaml \
		--provisioners https://raw.githubusercontent.com/score-spec/community-provisioners/refs/heads/main/score-compose/10-redis-dapr-pubsub.provisioners.yaml \
		--provisioners https://raw.githubusercontent.com/score-spec/community-provisioners/refs/heads/main/score-compose/10-dapr-subscription.provisioners.yaml \
		--provisioners score-provisioners/00-redis-dapr-state-store-with-actor-compose.provisioners.yaml \
		--patch-templates score-provisioners/dapr.tpl

compose.yaml: services/inventory/score.yaml services/notifications/score.yaml services/order-processor/score.yaml services/payments/score.yaml services/shipping/score.yaml .score-compose/state.yaml Makefile
	score-compose generate services/inventory/score.yaml --build 'inventory={"context":"services/inventory/","tags":["inventory:local"]}'
	score-compose generate services/notifications/score.yaml --build 'notifications={"context":"services/notifications/","tags":["notifications:local"]}'
	score-compose generate services/order-processor/score.yaml --build 'order-processor={"context":"services/order-processor/","tags":["order-processor:local"]}'
	score-compose generate services/payments/score.yaml --build 'payments={"context":"services/payments/","tags":["payments:local"]}'
	score-compose generate services/shipping/score.yaml --build 'shipping={"context":"services/shipping/","tags":["shipping:local"]}'

## Generate a compose.yaml file from the score spec and launch it.
.PHONY: deploy-local
deploy-local: compose.yaml
	docker compose up --build -d --remove-orphans
	sleep 5

## Delete the containers running via compose down.
.PHONY: cleanup-local
cleanup-local:
	docker compose down -v --remove-orphans || true

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

development/.score-k8s/state.yaml:
	mkdir development -p
	cd development && \
	score-k8s init --no-sample \
		--provisioners https://raw.githubusercontent.com/score-spec/community-provisioners/refs/heads/main/score-k8s/10-redis-dapr-pubsub.provisioners.yaml \
		--provisioners https://raw.githubusercontent.com/score-spec/community-provisioners/refs/heads/main/score-k8s/10-dapr-subscription.provisioners.yaml \
		--provisioners https://raw.githubusercontent.com/score-spec/community-provisioners/refs/heads/main/score-k8s/10-shared-gateway-httproute.provisioners.yaml \
		--provisioners ../score-provisioners/00-redis-dapr-state-store-with-actor-k8s.provisioners.yaml

development/manifests.yaml: services/inventory/score.yaml services/notifications/score.yaml services/order-processor/score.yaml services/payments/score.yaml services/shipping/score.yaml development/.score-k8s/state.yaml Makefile
	cd development && score-k8s generate ../services/inventory/score.yaml --image inventory:local
	cd development && score-k8s generate ../services/notifications/score.yaml --image notifications:local
	cd development && score-k8s generate ../services/order-processor/score.yaml --image order-processor:local
	cd development && score-k8s generate ../services/payments/score.yaml --image payments:local
	cd development && score-k8s generate ../services/shipping/score.yaml --image shipping:local

## Generate a manifests.yaml file from the score spec, deploy it to Kubernetes and wait for the Pods to be Ready.
.PHONY: deploy-development
deploy-development: development/manifests.yaml
	kubectl create namespace development || true
	cd development && kubectl apply -f manifests.yaml -n development
	sleep 5

## Delete the deployment of the local container in Kubernetes.
.PHONY: cleanup-development
cleanup-development:
	cd development && kubectl delete -f manifests.yaml -n development

staging/.score-k8s/state.yaml:
	mkdir staging -p
	cd staging && \
	score-k8s init --no-sample \
		--provisioners https://raw.githubusercontent.com/score-spec/community-provisioners/refs/heads/main/score-k8s/10-rabbitmq-dapr-pubsub.provisioners.yaml \
		--provisioners https://raw.githubusercontent.com/score-spec/community-provisioners/refs/heads/main/score-k8s/10-dapr-subscription.provisioners.yaml \
		--provisioners https://raw.githubusercontent.com/score-spec/community-provisioners/refs/heads/main/score-k8s/10-shared-gateway-httproute.provisioners.yaml \
		--provisioners ../score-provisioners/00-redis-dapr-state-store-with-actor-k8s.provisioners.yaml

staging/manifests.yaml: services/inventory/score.yaml services/notifications/score.yaml services/order-processor/score.yaml services/payments/score.yaml services/shipping/score.yaml staging/.score-k8s/state.yaml Makefile
	cd staging && score-k8s generate ../services/inventory/score.yaml --image inventory:local
	cd staging && score-k8s generate ../services/notifications/score.yaml --image notifications:local
	cd staging && score-k8s generate ../services/order-processor/score.yaml --image order-processor:local
	cd staging && score-k8s generate ../services/payments/score.yaml --image payments:local
	cd staging && score-k8s generate ../services/shipping/score.yaml --image shipping:local

## Generate a manifests.yaml file from the score spec, deploy it to Kubernetes and wait for the Pods to be Ready.
.PHONY: deploy-staging
deploy-staging: staging/manifests.yaml
	kubectl create namespace staging || true
	cd staging && kubectl apply -f manifests.yaml -n staging
	sleep 5

## Delete the deployment of the local container in Kubernetes.
.PHONY: cleanup-staging
cleanup-staging:
	cd staging && kubectl delete -f manifests.yaml -n staging


production/.score-k8s/state.yaml:
	mkdir production -p
	cd production && \
	score-k8s init --no-sample \
		--provisioners https://raw.githubusercontent.com/score-spec/community-provisioners/refs/heads/main/score-k8s/10-redis-dapr-pubsub.provisioners.yaml \
		--provisioners https://raw.githubusercontent.com/score-spec/community-provisioners/refs/heads/main/score-k8s/10-dapr-subscription.provisioners.yaml \
		--provisioners https://raw.githubusercontent.com/score-spec/community-provisioners/refs/heads/main/score-k8s/10-shared-gateway-httproute.provisioners.yaml \
		--provisioners ../score-provisioners/00-azure-redis-dapr-state-store-with-actor-k8s.provisioners.yaml

production/manifests.yaml: services/inventory/score.yaml services/notifications/score.yaml services/order-processor/score.yaml services/payments/score.yaml services/shipping/score.yaml production/.score-k8s/state.yaml Makefile
	cd production && score-k8s generate ../services/inventory/score.yaml --image inventory:local
	cd production && score-k8s generate ../services/notifications/score.yaml --image notifications:local
	cd production && score-k8s generate ../services/order-processor/score.yaml --image order-processor:local
	cd production && score-k8s generate ../services/payments/score.yaml --image payments:local
	cd production && score-k8s generate ../services/shipping/score.yaml --image shipping:local

## Generate a manifests.yaml file from the score spec, deploy it to Kubernetes and wait for the Pods to be Ready.
.PHONY: deploy-production
deploy-production: production/manifests.yaml
	kubectl create namespace production || true
	cd production && kubectl apply -f manifests.yaml -n production
	sleep 5

## Delete the deployment of the local container in Kubernetes.
.PHONY: cleanup-production
cleanup-production:
	cd production && kubectl delete -f manifests.yaml -n production