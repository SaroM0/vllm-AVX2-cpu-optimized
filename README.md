# vLLM CPU Optimized

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)](https://www.docker.com/)
[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)

> **A CPU-optimized build of vLLM for running LLMs on CPUs without AVX512 support**

This project provides pre-configured scripts and Docker configurations to build and deploy [vLLM](https://github.com/vllm-project/vllm) optimized for CPUs that lack AVX512 instructions. Perfect for development, testing, and running LLMs on consumer-grade hardware.

## 🎯 Why This Project?

Standard vLLM builds often fail or crash on CPUs without AVX512 support (common in consumer laptops and older processors). This project solves that by:

- ✅ Building vLLM with AVX512 **disabled**
- ✅ Falling back to AVX2 instructions (widely supported)
- ✅ Optimized memory allocation with TCMalloc
- ✅ CPU core binding for better performance
- ✅ Easy Docker-based deployment
- ✅ Pre-configured for common CPU types

## 🚀 Quick Start

### Prerequisites

- Docker installed
- 4GB+ RAM available
- CPU with AVX2 support (most modern CPUs have this)

### Build & Run

```bash
# Clone the repository
git clone https://github.com/SaroM0/vllm-AVX2-cpu-optimized.git
cd vllm-AVX2-cpu-optimized

# Build the optimized vLLM image (takes 30-60 minutes)
./build.sh

# Run a test inference
./run-example.sh
```

## 📦 What's Included

```
vllm-cpu-optimized/
├── build.sh              # Build script with CPU optimizations
├── run-example.sh        # Quick example to test the build
├── docker-compose.yml    # Production deployment setup
├── monitor.sh            # Performance monitoring script
├── configs/              # Sample configurations
│   ├── cpu-no-avx512.yml
│   ├── cpu-avx2-only.yml
│   └── cpu-performance.yml
└── docs/
    ├── CONFIGURATION.md  # Detailed configuration guide
    ├── PERFORMANCE.md    # Performance tuning tips
    └── TROUBLESHOOTING.md
```

## 🔧 Configuration

### Build Arguments

The build script supports several CPU configurations:

```bash
# For CPUs WITHOUT AVX512 (default)
./build.sh

# For CPUs WITH AVX512 support
./build.sh --enable-avx512

# Custom core binding
./build.sh --cores="0-7"
```

### Runtime Environment Variables

Key environment variables for tuning performance:

| Variable | Default | Description |
|----------|---------|-------------|
| `VLLM_CPU_KVCACHE_SPACE` | `4` | KV cache size in GB |
| `VLLM_CPU_OMP_THREADS_BIND` | `0-9` | CPU cores to bind |
| `VLLM_DTYPE` | `auto` | Data type (auto, float32, bfloat16) |
| `LD_PRELOAD` | `libtcmalloc...` | Memory allocator |

## 📊 Performance Expectations

Performance varies significantly based on your CPU:

| CPU Type | Tokens/sec | Use Case |
|----------|------------|----------|
| Modern i7/i9 (AVX2) | 5-10 | Development, Testing |
| Modern i5 (AVX2) | 3-7 | Light Development |
| Older i7 (AVX2) | 2-5 | Basic Testing |

> **Note:** CPU inference is 10-20x slower than GPU. This is best for development, testing, and low-throughput scenarios.

## 🐳 Docker Deployment

### Single Container

```bash
docker run --rm -it \
  --shm-size=4g \
  -p 8000:8000 \
  vllm-cpu-optimized:latest \
  --model facebook/opt-125m \
  --dtype float32 \
  --max-model-len 2048
```

### Docker Compose (Recommended)

```bash
# Edit docker-compose.yml with your model and settings
docker-compose up -d

# Monitor logs
docker-compose logs -f

# Check health
curl http://localhost:8000/health
```

## 🔍 Supported CPU Types

This build has been tested on:

| CPU Family | AVX512 | Status | Notes |
|------------|--------|--------|-------|
| Intel Core Ultra (Meteor Lake) | ❌ | ✅ Supported | Use default config |
| Intel 10th-12th Gen (no AVX512) | ❌ | ✅ Supported | Use default config |
| Intel 11th-14th Gen (with AVX512) | ✅ | ✅ Supported | Use `--enable-avx512` |
| AMD Ryzen 3000-5000 | ❌ | ✅ Supported | Use default config |
| AMD Ryzen 7000+ (with AVX512) | ✅ | ✅ Supported | Use `--enable-avx512` |

To check your CPU features:
```bash
lscpu | grep -i avx
```

## 🛠️ Advanced Usage

### Custom Model Deployment

```bash
docker run --rm -it \
  --shm-size=8g \
  -p 8000:8000 \
  -v ~/.cache/huggingface:/root/.cache/huggingface \
  vllm-cpu-optimized:latest \
  --model meta-llama/Llama-2-7b-chat-hf \
  --dtype bfloat16 \
  --max-model-len 4096 \
  --gpu-memory-utilization 0.9
```

### API Usage

Once running, vLLM exposes an OpenAI-compatible API:

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8000/v1",
    api_key="dummy-key"
)

response = client.chat.completions.create(
    model="meta-llama/Llama-2-7b-chat-hf",
    messages=[
        {"role": "user", "content": "Hello, how are you?"}
    ]
)

print(response.choices[0].message.content)
```

### Monitoring Performance

Use the included monitoring script:

```bash
# Monitor CPU usage, memory, and inference metrics
./monitor.sh

# Output:
# CPU Usage: 87%
# Memory: 8.2GB / 16GB
# Tokens/sec: 6.3
# Requests: 42
```

## 🐛 Troubleshooting

### Build Issues

**Problem:** Build fails with "Illegal instruction"
```bash
# Solution: Rebuild with AVX512 disabled
docker rmi vllm-cpu-optimized:latest
./build.sh --no-avx512
```

**Problem:** Out of memory during build
```bash
# Solution: Increase Docker memory limit
# Docker Desktop → Settings → Resources → Memory: 8GB+
```

### Runtime Issues

**Problem:** vLLM crashes with SIGILL
- **Cause:** AVX512 instructions on unsupported CPU
- **Solution:** Set `VLLM_CPU_DISABLE_AVX512=true` in docker-compose.yml

**Problem:** Very slow inference (< 1 token/sec)
- **Check:** CPU core binding (`VLLM_CPU_OMP_THREADS_BIND`)
- **Check:** Model size vs available RAM
- **Try:** Smaller model or reduced `--max-model-len`

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for more solutions.

## 📚 Documentation

- [Configuration Guide](docs/CONFIGURATION.md) - Detailed configuration options
- [Performance Tuning](docs/PERFORMANCE.md) - Optimize for your hardware
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions
- [Examples](examples/) - Usage examples and recipes

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Areas for Contribution

- [ ] Testing on different CPU architectures
- [ ] Performance benchmarks
- [ ] Additional example configurations
- [ ] Documentation improvements
- [ ] ARM64 support and testing

## 📝 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

The original vLLM project is also licensed under Apache 2.0: https://github.com/vllm-project/vllm

## 🙏 Acknowledgments

- [vLLM Team](https://github.com/vllm-project/vllm) - For the amazing inference engine
- Community contributors who tested on various CPU architectures

## 📞 Support

- **Issues:** [GitHub Issues](https://github.com/SaroM0/vllm-AVX2-cpu-optimized/issues)
- **Discussions:** [GitHub Discussions](https://github.com/SaroM0/vllm-AVX2-cpu-optimized/discussions)
- **vLLM Discord:** [Join here](https://discord.gg/vllm)

## ⭐ Star History

If this project helped you, please consider giving it a star! ⭐

---

**Note:** This is not an official vLLM project. It's a community build optimized for CPU usage. For the official vLLM project, visit https://github.com/vllm-project/vllm

