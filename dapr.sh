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

# Define custom wait function that waits for user to press enter
function wait_for_user() {
  read -s
}

# Type and execute commands
# pe "dapr uninstall --all"
# clear

pe "dapr init"
pe clear

pe "docker ps | grep -i dapr"
pe clear

pe "dapr run -f ."
pe clear
