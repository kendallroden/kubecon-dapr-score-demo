#!/bin/bash

# Set up demo-magic
if [ ! -f demo-magic.sh ]; then
    echo "Downloading demo-magic.sh..."
    curl -sSL https://raw.githubusercontent.com/paxtonhare/demo-magic/master/demo-magic.sh -o demo-magic.sh
    chmod +x demo-magic.sh
fi

# Source demo-magic with appropriate options
# -d: enable debug mode
# We're keeping typing simulation on by not using -n
source ./demo-magic.sh -d

# Clear the screen
clear

pe "code -g ./services/order-processor/app.py:25"
pe "code -g ./services/order-processor/app.py:295"
pe "code -g ./services/order-processor/app.py:72"
pe "code -g ./services/order-processor/app.py:73"
clear 

pe "code -g ./services/order-processor/app.py:139"
pe "code ./components/subscription.yaml"
pe "code -g ./services/notifications/app.py:42"
clear

pe "code -g ./services/order-processor/app.py:149"
pe "code -g ./services/inventory/app.py:45"
clear