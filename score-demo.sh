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
sudo rm compose.yaml || true
#sudo make cleanup-staging
#sudo make deploy-staging
sudo rm staging/manifests.yaml || true
clear

pe "code services/notifications/score.yaml"
clear
pe "code services/inventory/score.yaml"

pe "echo \"Demo #1 - score-compose\""
pe "sudo make compose.yaml"
clear
pe "code compose.yaml"
pe "sudo docker compose up --build -d"
pe "sudo docker ps | grep redis"
pe "make get-notifications-local"
pe "make test-local"
pe "clear"

pe "echo \"Demo #2 - score-k8s in Staging\""
pe "sudo make staging/manifests.yaml"
pe "code staging/manifests.yaml"
pe "sudo kubectl apply -f staging/manifests.yaml -n staging"
pe "sudo kubectl get statefulset -n staging"
pe "make get-notifications-staging"
pe "make test-staging"

clear
pe "echo \"The end.\""