# Configuration Guide

This guide covers all configuration options for vLLM CPU Optimized.

## Build Configuration

### Build Arguments

```bash
./build.sh [OPTIONS]
```

| Option | Description | Default |
|--------|-------------|---------|
| `--enable-avx512` | Enable AVX512 instructions | disabled |
| `--cores RANGE` | CPU core binding (e.g., 0-7) | auto |
| `--tag TAG` | Docker image tag | vllm-cpu-optimized:latest |
| `--version VERSION` | vLLM version | main |

### Examples

```bash
# Basic build (AVX2 only)
./build.sh

# With AVX512 support
./build.sh --enable-avx512

# Custom core binding
./build.sh --cores 0-7

# Specific vLLM version
./build.sh --version v0.3.0 --tag vllm-cpu:v0.3.0
```

## Runtime Configuration

### Environment Variables

#### CPU Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `VLLM_CPU_DISABLE_AVX512` | bool | true | Disable AVX512 instructions |
| `VLLM_CPU_AVX512BF16` | bool | false | Enable AVX512 BF16 |
| `VLLM_CPU_AVX512VNNI` | bool | false | Enable AVX512 VNNI |
| `VLLM_CPU_KVCACHE_SPACE` | int | 4 | KV cache size in GB |
| `VLLM_CPU_OMP_THREADS_BIND` | string | 0-9 | CPU cores to bind |

#### Model Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `VLLM_DTYPE` | string | auto | Data type (auto/float32/bfloat16) |
| `VLLM_LOGGING_LEVEL` | string | INFO | Log level |

#### Memory Management

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `LD_PRELOAD` | string | libtcmalloc | Memory allocator library |

### Command Line Arguments

When starting vLLM, you can pass these arguments:

```bash
docker run vllm-cpu-optimized:latest [ARGS]
```

#### Essential Arguments

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `--model` | string | yes | Model name or path |
| `--dtype` | string | no | Data type (auto/float32/bfloat16) |
| `--max-model-len` | int | no | Max sequence length |
| `--host` | string | no | Bind address (0.0.0.0) |
| `--port` | int | no | Port number (8000) |

#### Performance Arguments

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `--max-num-batched-tokens` | int | auto | Max batched tokens |
| `--max-num-seqs` | int | 256 | Max sequences |
| `--gpu-memory-utilization` | float | 0.9 | Memory utilization (for CPU: ignored) |

## CPU-Specific Configurations

### Intel Core Ultra (Meteor Lake)

No AVX512, use AVX2 + AVX_VNNI:

```yaml
environment:
  VLLM_CPU_DISABLE_AVX512: "true"
  VLLM_CPU_OMP_THREADS_BIND: "0-9"  # 6P+2E cores
  VLLM_DTYPE: "float32"
command:
  - --dtype=float32
  - --max-model-len=2048
```

### Intel 11th-14th Gen (with AVX512)

```yaml
environment:
  VLLM_CPU_DISABLE_AVX512: "false"
  VLLM_CPU_AVX512BF16: "true"
  VLLM_CPU_AVX512VNNI: "true"
  VLLM_CPU_OMP_THREADS_BIND: "0-15"
  VLLM_DTYPE: "bfloat16"
command:
  - --dtype=bfloat16
  - --max-model-len=4096
```

### AMD Ryzen (no AVX512)

```yaml
environment:
  VLLM_CPU_DISABLE_AVX512: "true"
  VLLM_CPU_OMP_THREADS_BIND: "0-11"  # Adjust for your core count
  VLLM_DTYPE: "float32"
command:
  - --dtype=float32
  - --max-model-len=2048
```

### AMD Ryzen 7000+ (with AVX512)

```yaml
environment:
  VLLM_CPU_DISABLE_AVX512: "false"
  VLLM_CPU_AVX512BF16: "false"  # Not supported
  VLLM_CPU_AVX512VNNI: "true"
  VLLM_CPU_OMP_THREADS_BIND: "0-15"
command:
  - --dtype=float32
  - --max-model-len=4096
```

## Model-Specific Configurations

### Small Models (< 1B parameters)

Example: facebook/opt-125m, gpt2

```yaml
command:
  - --model=facebook/opt-125m
  - --dtype=float32
  - --max-model-len=512
shm_size: 2gb
deploy:
  resources:
    limits:
      memory: 4G
```

### Medium Models (1-7B parameters)

Example: meta-llama/Llama-2-7b-chat-hf

```yaml
command:
  - --model=meta-llama/Llama-2-7b-chat-hf
  - --dtype=float32
  - --max-model-len=2048
shm_size: 8gb
deploy:
  resources:
    limits:
      memory: 24G
```

### Large Models (7-13B parameters)

Example: meta-llama/Llama-2-13b-chat-hf

```yaml
command:
  - --model=meta-llama/Llama-2-13b-chat-hf
  - --dtype=bfloat16  # If supported
  - --max-model-len=2048
shm_size: 16gb
deploy:
  resources:
    limits:
      memory: 32G
```

## Performance Tuning

### CPU Core Binding

Find optimal core binding for your CPU:

```bash
# Check CPU topology
lscpu --extended

# For hybrid CPUs (P+E cores), bind to P-cores only
# Example: 6 P-cores
VLLM_CPU_OMP_THREADS_BIND="0-11"  # If they have HT

# For homogeneous CPUs, leave 2 cores for system
# Example: 8-core CPU
VLLM_CPU_OMP_THREADS_BIND="0-5"
```

### Memory Optimization

```yaml
environment:
  # Use TCMalloc for better memory allocation
  LD_PRELOAD: "/usr/lib/x86_64-linux-gnu/libtcmalloc_minimal.so.4"
  
  # Adjust KV cache based on available RAM
  VLLM_CPU_KVCACHE_SPACE: "8"  # Increase if you have RAM

shm_size: 8gb  # Increase for larger models
```

### Batch Size Tuning

```bash
# For interactive use (low latency)
--max-num-seqs=4
--max-num-batched-tokens=256

# For throughput (batch processing)
--max-num-seqs=32
--max-num-batched-tokens=2048
```

## Troubleshooting Common Issues

### Issue: Slow Performance

**Check core binding:**
```bash
docker exec vllm-cpu cat /proc/self/status | grep Cpus_allowed_list
```

**Check memory usage:**
```bash
docker stats vllm-cpu
```

### Issue: Out of Memory

**Reduce model size or sequence length:**
```yaml
command:
  - --max-model-len=1024  # Reduce from 2048
  - --max-num-seqs=8      # Reduce batch size
```

**Increase Docker memory:**
```yaml
deploy:
  resources:
    limits:
      memory: 32G  # Increase
```

### Issue: Build Failures

**AVX512 errors:**
```bash
# Rebuild with AVX512 disabled
docker rmi vllm-cpu-optimized:latest
./build.sh
```

**Out of disk space:**
```bash
# Clean Docker
docker system prune -a
```

## Advanced Configuration

### Custom Build from Source

```bash
# Clone and modify
git clone https://github.com/vllm-project/vllm.git
cd vllm

# Edit build flags in setup.py or CMakeLists.txt

# Build custom image
docker build -f docker/Dockerfile.cpu \
    --build-arg VLLM_CPU_DISABLE_AVX512=true \
    -t my-custom-vllm:latest .
```

### Multi-Instance Deployment

Run multiple models on different ports:

```yaml
services:
  vllm-small:
    image: vllm-cpu-optimized:latest
    ports:
      - "8000:8000"
    environment:
      VLLM_CPU_OMP_THREADS_BIND: "0-3"
    command:
      - --model=facebook/opt-125m
  
  vllm-medium:
    image: vllm-cpu-optimized:latest
    ports:
      - "8001:8000"
    environment:
      VLLM_CPU_OMP_THREADS_BIND: "4-9"
    command:
      - --model=meta-llama/Llama-2-7b-chat-hf
```

## References

- [vLLM Documentation](https://docs.vllm.ai/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [CPU Feature Detection](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/)

