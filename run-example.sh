#!/bin/bash
# Quick example to test vLLM CPU build

set -e

IMAGE="vllm-cpu-optimized:latest"
MODEL="facebook/opt-125m"
PORT=8000

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=========================================="
echo "vLLM CPU Example - Quick Test"
echo -e "==========================================${NC}"
echo ""

# Check if image exists
if ! docker images | grep -q "vllm-cpu-optimized"; then
    echo -e "${YELLOW}Image not found. Building...${NC}"
    ./build.sh
fi

echo "Starting vLLM with small test model: $MODEL"
echo ""
echo -e "${YELLOW}This will:"
echo "  1. Download the model (first run only)"
echo "  2. Start vLLM server on port $PORT"
echo "  3. Run a test inference"
echo -e "  4. Clean up${NC}"
echo ""

# Start vLLM in background
echo "Starting vLLM server..."
CONTAINER_ID=$(docker run -d --rm \
    --shm-size=4g \
    -p $PORT:8000 \
    "$IMAGE" \
    --model "$MODEL" \
    --dtype float32 \
    --max-model-len 512)

echo "Container ID: $CONTAINER_ID"
echo ""
echo "Waiting for server to be ready..."

# Wait for server to be ready
MAX_WAIT=120
WAIT_COUNT=0
until curl -s http://localhost:$PORT/health > /dev/null 2>&1; do
    sleep 2
    WAIT_COUNT=$((WAIT_COUNT + 2))
    if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
        echo -e "${YELLOW}Server is taking longer than expected..."
        echo "This is normal for first run (downloading model)"
        echo "Check logs: docker logs $CONTAINER_ID"
        echo ""
    fi
    echo -n "."
done

echo ""
echo -e "${GREEN}✓ Server is ready!${NC}"
echo ""

# Test inference
echo "Testing inference..."
echo ""

RESPONSE=$(curl -s http://localhost:$PORT/v1/completions \
    -H "Content-Type: application/json" \
    -d '{
        "model": "'"$MODEL"'",
        "prompt": "Once upon a time",
        "max_tokens": 20,
        "temperature": 0.7
    }')

echo "Prompt: Once upon a time"
echo "Response:"
echo "$RESPONSE" | python3 -m json.tool | grep -A 1 '"text"' || echo "$RESPONSE"
echo ""

# Show stats
echo "Performance Stats:"
curl -s http://localhost:$PORT/metrics | grep -E "(vllm_request_success|vllm_time_to_first_token|vllm_e2e_request_latency)" | head -n 5 || echo "Metrics not available"
echo ""

# Cleanup
echo -e "${YELLOW}Cleaning up...${NC}"
docker stop "$CONTAINER_ID" > /dev/null 2>&1
echo ""

echo -e "${GREEN}=========================================="
echo "✓ Test Complete!"
echo -e "==========================================${NC}"
echo ""
echo "Next Steps:"
echo "  - Deploy with docker-compose: docker-compose up -d"
echo "  - Try a larger model: Edit docker-compose.yml"
echo "  - Read docs: cat docs/CONFIGURATION.md"
echo ""

