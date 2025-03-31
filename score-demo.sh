#!/bin/bash

# setup
if [ ! -f demo-magic.sh ]; then
    curl -LO https://github.com/paxtonhare/demo-magic/raw/master/demo-magic.sh
fi
. demo-magic.sh -d #-n
clear

# demo cleanup
#sudo make cleanup-local
#sudo make deploy-local
sudo rm compose.yaml
#sudo make cleanup-development
#sudo make deploy-development
#sudo rm development/manifests.yaml
#sudo make cleanup-staging
#sudo make deploy-staging
#sudo rm staging/manifests.yaml
#clear

pe "echo \"Developers should not write either Docker Compose file or Kubernetes manifests, let me show you how!\""
pe "code services/notifications/score.yaml"
pe "clear"

pe "echo \"Demo #1 - score-compose\""
pe "sudo make compose.yaml"
pe "code -g Makefile:19"
pe "score-compose resources list | grep dapr"
pe "code compose.yaml"
pe "sudo docker compose up --build -d"
pe "sudo docker ps | grep redis"
pe "make get-notifications-local"
pe "make test-local"
pe "clear"

pe "echo \"Demo #2 - score-k8s in Development\""
pe "sudo make development/manifests.yaml"
pe "code -g Makefile:86"
pe "code development/manifests.yaml"
pe "sudo kubectl apply -f development/manifests.yaml -n development"
pe "sudo kubectl get statefulset -n development"
pe "make get-notifications-development"
pe "make test-development"
pe "clear"

pe "echo \"Demo #3 - score-k8s in Staging\""
pe "sudo make staging/manifests.yaml"
pe "code -g Makefile:86"
pe "code staging/manifests.yaml"
pe "sudo kubectl apply -f staging/manifests.yaml -n staging"
pe "sudo kubectl get statefulset -n staging"
pe "make get-notifications-staging"
pe "make test-staging"