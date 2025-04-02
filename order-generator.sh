#!/bin/bash

# Advanced script to generate order API calls with configurable parameters

# Default values
HOST="localhost"
PORT="8080"
ENDPOINT="/orders"
RATE=1  # requests per second
DURATION=0  # run forever by default
VERBOSE=true

# Parse command line arguments
while getopts "h:p:e:r:d:q" opt; do
  case $opt in
    h) HOST="$OPTARG" ;;
    p) PORT="$OPTARG" ;;
    e) ENDPOINT="$OPTARG" ;;
    r) RATE="$OPTARG" ;;
    d) DURATION="$OPTARG" ;;
    q) VERBOSE=false ;;
    \?) echo "Invalid option -$OPTARG" >&2; exit 1 ;;
  esac
done

# Get the service DNS
SERVICE_HOST=$(score-k8s resources get-outputs dns.default#order-processor.dns --format '{{ .host }}')

# Arrays of sample data
CUSTOMERS=("alice" "bob" "charlie" "david" "emma" "frank" "grace" "hannah" "ian" "julia" 
           "kevin" "lucy" "michael" "nina" "oliver" "penny" "quinn" "robert" "sarah" "thomas")
ITEMS=("apple" "banana" "cherry" "date" "elderberry" "fig" "grape" "honeydew" "kiwi" "lemon" 
       "mango" "orange" "pear" "quince" "raspberry" "strawberry" "tangerine" "watermelon")

# Calculate sleep time between requests
SLEEP_TIME=$(awk -v rate="$RATE" 'BEGIN{print 1/rate}')

# Print configuration
if $VERBOSE; then
  echo "=== Order Generator Configuration ==="
  echo "Target: $HOST:$PORT$ENDPOINT"
  echo "Service Host: $SERVICE_HOST"
  echo "Rate: $RATE requests per second"
  if [ "$DURATION" -gt 0 ]; then
    echo "Duration: $DURATION seconds"
  else
    echo "Duration: Running until stopped (Ctrl+C)"
  fi
  echo "======================================"
fi

# Function to generate a random decimal number between min and max
random_price() {
  local min=$1
  local max=$2
  local price=$(awk -v min="$min" -v max="$max" 'BEGIN{srand(); print min+rand()*(max-min)}')
  # Format to 2 decimal places
  printf "%.2f" $price
}

# Initialize counters
count=0
start_time=$(date +%s)

# Trap Ctrl+C to print summary before exiting
trap 'echo -e "\n=== Summary ===\nTotal orders sent: $count\nRunning time: $(($(date +%s) - start_time)) seconds\n==============="; exit' INT

# Main loop
while true; do
  # Check if we've reached the duration limit
  current_time=$(date +%s)
  elapsed=$((current_time - start_time))
  if [ "$DURATION" -gt 0 ] && [ "$elapsed" -ge "$DURATION" ]; then
    if $VERBOSE; then
      echo -e "\n=== Duration limit reached ==="
      echo "Total orders sent: $count"
      echo "Running time: $elapsed seconds"
      echo "============================"
    fi
    break
  fi
  
  # Select random customer, item, and total
  customer=${CUSTOMERS[$RANDOM % ${#CUSTOMERS[@]}]}
  item=${ITEMS[$RANDOM % ${#ITEMS[@]}]}
  
  # Generate a price with a realistic distribution
  # Items are more likely to be in the $5-25 range than $25-100
  if [ $((RANDOM % 100)) -lt 80 ]; then
    total=$(random_price 5.00 25.00)
  else
    total=$(random_price 25.00 100.00)
  fi
  
  echo "TRY"
  echo $HOST:$PORT$ENDPOINT -H "Host: $SERVICE_HOST"

  # Construct and execute the API call
  response=$(curl -s -w "\n%{http_code}" -X POST $HOST:$PORT$ENDPOINT \
    -H "Host: $SERVICE_HOST" \
    -H "Content-Type: application/json" \
    -d "{\"customer\": \"$customer\", \"item\": \"$item\", \"total\": $total}")
  
  # Extract status code and response body
  status_code=$(echo "$response" | tail -n1)
  response_body=$(echo "$response" | sed '$d')
  
  count=$((count + 1))
  
  # Print output if verbose mode is enabled
  if $VERBOSE; then
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    if [ "$status_code" -ge 200 ] && [ "$status_code" -lt 300 ]; then
      echo "[$timestamp] #$count - $customer ordered $item: \$$total - Success ($status_code)"
    else
      echo "[$timestamp] #$count - $customer ordered $item: \$$total - Failed ($status_code)"
      echo "Response: $response_body"
    fi
  fi
  
  # Sleep until next request
  sleep $SLEEP_TIME
done