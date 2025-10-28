#!/bin/bash
# Monitor vLLM CPU performance and resource usage

CONTAINER_NAME="vllm-cpu"
REFRESH_INTERVAL=2

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if container is running
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo -e "${RED}Container $CONTAINER_NAME is not running${NC}"
    echo "Start it with: docker-compose up -d"
    exit 1
fi

echo -e "${GREEN}=========================================="
echo "vLLM CPU Monitor"
echo "Container: $CONTAINER_NAME"
echo -e "==========================================${NC}"
echo ""
echo "Press Ctrl+C to stop monitoring"
echo ""

# Function to get metrics
get_metrics() {
    # Get container stats
    STATS=$(docker stats "$CONTAINER_NAME" --no-stream --format "{{.CPUPerc}}|{{.MemUsage}}|{{.NetIO}}")
    CPU_USAGE=$(echo "$STATS" | cut -d'|' -f1)
    MEM_USAGE=$(echo "$STATS" | cut -d'|' -f2)
    NET_IO=$(echo "$STATS" | cut -d'|' -f3)
    
    # Get vLLM metrics (if available)
    METRICS=$(curl -s http://localhost:8000/metrics 2>/dev/null)
    
    if [ -n "$METRICS" ]; then
        # Parse key metrics
        REQUESTS=$(echo "$METRICS" | grep "vllm_request_success_total" | tail -1 | awk '{print $2}' | cut -d'.' -f1)
        TOKENS_GENERATED=$(echo "$METRICS" | grep "vllm_request_success{finished_reason=\"length\"}" | tail -1 | awk '{print $2}' | cut -d'.' -f1)
        
        # Calculate tokens/sec (rough estimate)
        if [ -n "$PREV_TOKENS" ] && [ -n "$TOKENS_GENERATED" ]; then
            TOKENS_DIFF=$((TOKENS_GENERATED - PREV_TOKENS))
            TOKENS_PER_SEC=$(echo "scale=1; $TOKENS_DIFF / $REFRESH_INTERVAL" | bc 2>/dev/null || echo "N/A")
        else
            TOKENS_PER_SEC="N/A"
        fi
        PREV_TOKENS=$TOKENS_GENERATED
    fi
}

# Main monitoring loop
PREV_TOKENS=0

while true; do
    clear
    
    echo -e "${GREEN}=========================================="
    echo "vLLM CPU Monitor - $(date '+%H:%M:%S')"
    echo -e "==========================================${NC}"
    echo ""
    
    get_metrics
    
    # System Resources
    echo -e "${YELLOW}System Resources:${NC}"
    echo "  CPU Usage:    $CPU_USAGE"
    echo "  Memory:       $MEM_USAGE"
    echo "  Network I/O:  $NET_IO"
    echo ""
    
    # vLLM Metrics
    if [ -n "$METRICS" ]; then
        echo -e "${YELLOW}vLLM Metrics:${NC}"
        echo "  Total Requests:    ${REQUESTS:-0}"
        echo "  Tokens Generated:  ${TOKENS_GENERATED:-0}"
        echo "  Tokens/sec:        $TOKENS_PER_SEC"
        echo ""
        
        # Running requests
        RUNNING=$(echo "$METRICS" | grep "vllm_num_requests_running" | tail -1 | awk '{print $2}' | cut -d'.' -f1)
        WAITING=$(echo "$METRICS" | grep "vllm_num_requests_waiting" | tail -1 | awk '{print $2}' | cut -d'.' -f1)
        
        if [ -n "$RUNNING" ] || [ -n "$WAITING" ]; then
            echo -e "${YELLOW}Request Queue:${NC}"
            echo "  Running:  ${RUNNING:-0}"
            echo "  Waiting:  ${WAITING:-0}"
            echo ""
        fi
        
        # Average latencies (if available)
        TTFT=$(echo "$METRICS" | grep "vllm_time_to_first_token_seconds_sum" | tail -1 | awk '{print $2}')
        TTFT_COUNT=$(echo "$METRICS" | grep "vllm_time_to_first_token_seconds_count" | tail -1 | awk '{print $2}')
        
        if [ -n "$TTFT" ] && [ -n "$TTFT_COUNT" ] && [ "$TTFT_COUNT" != "0" ]; then
            AVG_TTFT=$(echo "scale=2; $TTFT / $TTFT_COUNT" | bc 2>/dev/null || echo "N/A")
            echo -e "${YELLOW}Performance:${NC}"
            echo "  Avg Time to First Token: ${AVG_TTFT}s"
            echo ""
        fi
    else
        echo -e "${RED}vLLM metrics not available${NC}"
        echo "Make sure the server is running on port 8000"
        echo ""
    fi
    
    # Recent logs (last 5 lines)
    echo -e "${YELLOW}Recent Logs:${NC}"
    docker logs "$CONTAINER_NAME" --tail 5 2>&1 | sed 's/^/  /'
    echo ""
    
    echo -e "${GREEN}========================================${NC}"
    echo "Refreshing in ${REFRESH_INTERVAL}s... (Ctrl+C to stop)"
    
    sleep $REFRESH_INTERVAL
done

