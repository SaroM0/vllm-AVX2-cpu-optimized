#!/bin/bash
# Build vLLM CPU image optimized for CPUs without AVX512
# This script builds vLLM from source with proper CPU flags

set -e

# Default values
AVX512_ENABLED="false"
CORES=""
TAG="vllm-cpu-optimized:latest"
VLLM_VERSION="main"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --enable-avx512)
            AVX512_ENABLED="true"
            shift
            ;;
        --cores)
            CORES="$2"
            shift 2
            ;;
        --tag)
            TAG="$2"
            shift 2
            ;;
        --version)
            VLLM_VERSION="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --enable-avx512     Enable AVX512 instructions (default: disabled)"
            echo "  --cores RANGE       CPU cores to bind (e.g., 0-7)"
            echo "  --tag TAG           Docker image tag (default: vllm-cpu-optimized:latest)"
            echo "  --version VERSION   vLLM version to build (default: main)"
            echo "  -h, --help          Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                          # Build with AVX512 disabled"
            echo "  $0 --enable-avx512          # Build with AVX512 enabled"
            echo "  $0 --cores 0-7              # Build with custom core binding"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Detect CPU features
echo -e "${GREEN}=========================================="
echo "vLLM CPU Optimized Build Script"
echo -e "==========================================${NC}"
echo ""

echo "Detecting CPU features..."
if command -v lscpu &> /dev/null; then
    CPU_MODEL=$(lscpu | grep "Model name" | cut -d: -f2 | xargs)
    echo -e "${GREEN}CPU Model:${NC} $CPU_MODEL"
    
    if lscpu | grep -i avx512 &> /dev/null && [ "$AVX512_ENABLED" = "false" ]; then
        echo -e "${YELLOW}⚠ Your CPU supports AVX512 but build will use AVX2${NC}"
        echo -e "${YELLOW}  Use --enable-avx512 for better performance${NC}"
    elif ! lscpu | grep -i avx512 &> /dev/null && [ "$AVX512_ENABLED" = "true" ]; then
        echo -e "${RED}✗ Your CPU does not support AVX512${NC}"
        echo -e "${RED}  Disabling AVX512...${NC}"
        AVX512_ENABLED="false"
    fi
    
    if lscpu | grep -i avx2 &> /dev/null; then
        echo -e "${GREEN}✓ AVX2 support detected${NC}"
    else
        echo -e "${RED}✗ AVX2 not detected - build may fail${NC}"
    fi
fi

echo ""
echo "Build Configuration:"
echo "  AVX512 Enabled: $AVX512_ENABLED"
echo "  Docker Tag: $TAG"
echo "  vLLM Version: $VLLM_VERSION"
[ -n "$CORES" ] && echo "  CPU Cores: $CORES"
echo ""
echo -e "${YELLOW}This build will take approximately 30-60 minutes...${NC}"
echo ""

# Clone vLLM repository if not exists
if [ ! -d "vllm_source" ]; then
    echo "Cloning vLLM repository..."
    git clone https://github.com/vllm-project/vllm.git vllm_source
    cd vllm_source
    if [ "$VLLM_VERSION" != "main" ]; then
        git checkout "$VLLM_VERSION"
    fi
    cd ..
else
    echo "vLLM repository already exists"
    cd vllm_source
    echo "Pulling latest changes..."
    git fetch
    if [ "$VLLM_VERSION" != "main" ]; then
        git checkout "$VLLM_VERSION"
    else
        git pull
    fi
    cd ..
fi

cd vllm_source

# Set build arguments based on configuration
if [ "$AVX512_ENABLED" = "true" ]; then
    DISABLE_AVX512="false"
    AVX512BF16="true"
    AVX512VNNI="true"
    echo -e "${GREEN}Building with AVX512 support enabled${NC}"
else
    DISABLE_AVX512="true"
    AVX512BF16="false"
    AVX512VNNI="false"
    echo -e "${YELLOW}Building with AVX512 disabled (using AVX2)${NC}"
fi

echo ""
echo "Building Docker image..."
echo ""

# Build the Docker image
docker build -f docker/Dockerfile.cpu \
    --build-arg VLLM_CPU_DISABLE_AVX512="$DISABLE_AVX512" \
    --build-arg VLLM_CPU_AVX512BF16="$AVX512BF16" \
    --build-arg VLLM_CPU_AVX512VNNI="$AVX512VNNI" \
    --tag "$TAG" \
    --target vllm-openai \
    .

BUILD_STATUS=$?

cd ..

echo ""
if [ $BUILD_STATUS -eq 0 ]; then
    echo -e "${GREEN}=========================================="
    echo "✓ Build Complete!"
    echo -e "==========================================${NC}"
    echo ""
    echo "Image created: $TAG"
    echo ""
    echo "Quick Test:"
    echo "  docker run --rm $TAG --help"
    echo ""
    echo "Run Example:"
    echo "  ./run-example.sh"
    echo ""
    echo "Deploy with Docker Compose:"
    echo "  docker-compose up -d"
    echo ""
else
    echo -e "${RED}=========================================="
    echo "✗ Build Failed!"
    echo -e "==========================================${NC}"
    echo ""
    echo "Check the error messages above."
    echo "Common issues:"
    echo "  - Out of memory: Increase Docker memory limit"
    echo "  - Network timeout: Check internet connection"
    echo ""
    exit 1
fi

