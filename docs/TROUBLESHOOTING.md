# Troubleshooting Guide

Common issues and solutions for vLLM CPU Optimized.

## Build Issues

### Build Fails with "Illegal Instruction"

**Symptoms:**
```
Illegal instruction (core dumped)
```

**Cause:** CPU doesn't support AVX512 but build is trying to use it.

**Solution:**
```bash
# Clean and rebuild with AVX512 disabled
docker rmi vllm-cpu-optimized:latest
./build.sh
```

**Verify it's disabled:**
```bash
docker run --rm vllm-cpu-optimized:latest python -c \
  "import os; print('AVX512 disabled:', os.environ.get('VLLM_CPU_DISABLE_AVX512'))"
```

### Out of Memory During Build

**Symptoms:**
```
ERROR: failed to solve: process "/bin/sh -c ..." did not complete successfully
```

**Solutions:**

1. **Increase Docker memory:**
   - Docker Desktop → Settings → Resources → Memory: 8GB+

2. **Free system memory:**
   ```bash
   # Close other applications
   # Clear Docker cache
   docker system prune -a
   ```

3. **Build with reduced parallelism:**
   Edit `vllm_source/docker/Dockerfile.cpu`:
   ```dockerfile
   ARG max_jobs=1  # Changed from 2
   ```

### Build Takes Forever

**Expected time:** 30-60 minutes is normal for first build.

**Check progress:**
```bash
# Watch Docker build output
docker ps -a | grep vllm

# Check logs of build container
docker logs <container-id> -f
```

**Speed up subsequent builds:**
- Docker caches layers
- Rebuilds are much faster (5-10 min)

### "No space left on device"

**Solution:**
```bash
# Check Docker disk usage
docker system df

# Clean up
docker system prune -a --volumes

# Restart Docker daemon
sudo systemctl restart docker  # Linux
# or restart Docker Desktop
```

## Runtime Issues

### vLLM Crashes on Startup

**Symptoms:**
```
Illegal instruction
Signal 4 (SIGILL)
```

**Cause:** AVX512 instructions on unsupported CPU.

**Solution 1:** Set environment variable
```yaml
# docker-compose.yml
environment:
  VLLM_CPU_DISABLE_AVX512: "true"
```

**Solution 2:** Rebuild image
```bash
./build.sh
```

### Very Slow Inference (< 1 token/sec)

**Possible causes:**

1. **CPU cores not bound correctly:**
   ```bash
   # Check current binding
   docker exec vllm-cpu cat /proc/self/status | grep Cpus_allowed_list
   
   # Fix: Edit docker-compose.yml
   environment:
     VLLM_CPU_OMP_THREADS_BIND: "0-9"  # Adjust for your CPU
   ```

2. **Model too large for CPU:**
   ```bash
   # Try smaller model
   command:
     - --model=facebook/opt-125m  # Instead of 7B model
   ```

3. **Swapping to disk:**
   ```bash
   # Check memory usage
   docker stats vllm-cpu
   
   # Reduce memory usage
   command:
     - --max-model-len=1024  # Reduce sequence length
   ```

### Out of Memory at Runtime

**Symptoms:**
```
RuntimeError: CUDA out of memory
# (misleading error on CPU)
```
or
```
Killed
```

**Solutions:**

1. **Increase Docker memory:**
   ```yaml
   deploy:
     resources:
       limits:
         memory: 24G  # Increase based on model
   ```

2. **Reduce model memory usage:**
   ```yaml
   command:
     - --max-model-len=1024      # Reduce from 2048
     - --max-num-seqs=4          # Reduce batch size
   ```

3. **Use smaller model:**
   - opt-125m: ~1GB RAM
   - opt-1.3b: ~3GB RAM  
   - Llama-2-7b: ~14GB RAM
   - Llama-2-13b: ~26GB RAM

### Server Not Responding

**Check if container is running:**
```bash
docker ps | grep vllm-cpu
```

**Check logs:**
```bash
docker logs vllm-cpu

# Follow logs in real-time
docker logs vllm-cpu -f
```

**Check health:**
```bash
curl http://localhost:8000/health
```

**Restart container:**
```bash
docker-compose restart
```

### Port Already in Use

**Symptoms:**
```
Error starting userland proxy: listen tcp 0.0.0.0:8000: bind: address already in use
```

**Find process using port:**
```bash
lsof -i :8000
# or
netstat -tulpn | grep 8000
```

**Solutions:**

1. **Kill the process:**
   ```bash
   kill <PID>
   ```

2. **Use different port:**
   ```yaml
   # docker-compose.yml
   ports:
     - "8001:8000"  # Changed from 8000:8000
   ```

## Model Loading Issues

### Model Download Fails

**Symptoms:**
```
HTTPError: 401 Client Error
```

**Cause:** Private model requires authentication.

**Solution:**
```bash
# Login to Hugging Face
huggingface-cli login

# Mount token in container
docker run -v ~/.cache/huggingface:/root/.cache/huggingface ...
```

### Model Not Found

**Symptoms:**
```
OSError: [Model name] does not exist
```

**Solutions:**

1. **Check model name:**
   - Visit https://huggingface.co/
   - Verify exact model name

2. **Use full model path:**
   ```yaml
   command:
     - --model=meta-llama/Llama-2-7b-chat-hf  # Full path
   ```

3. **Download model first:**
   ```bash
   # Pre-download model
   docker run --rm -v ~/.cache/huggingface:/root/.cache/huggingface \
     vllm-cpu-optimized:latest \
     python -c "from transformers import AutoModel; \
                AutoModel.from_pretrained('facebook/opt-125m')"
   ```

## Performance Issues

### High CPU Usage but Slow

**Cause:** Suboptimal core binding or memory allocation.

**Check CPU binding:**
```bash
docker exec vllm-cpu cat /proc/self/status | grep Cpus_allowed_list
```

**Optimize for your CPU:**

For hybrid CPUs (Intel 12th gen+):
```yaml
# Bind to P-cores only
environment:
  VLLM_CPU_OMP_THREADS_BIND: "0-11"  # Adjust for your P-cores
```

For homogeneous CPUs:
```yaml
# Leave 2 cores for system
environment:
  VLLM_CPU_OMP_THREADS_BIND: "0-5"  # For 8-core CPU
```

### Memory Leak

**Symptoms:** Memory usage keeps increasing.

**Check:**
```bash
docker stats vllm-cpu --no-stream
```

**Solutions:**

1. **Restart container periodically:**
   ```yaml
   deploy:
     restart_policy:
       condition: on-failure
       max_attempts: 3
   ```

2. **Use TCMalloc (should be default):**
   ```yaml
   environment:
     LD_PRELOAD: "/usr/lib/x86_64-linux-gnu/libtcmalloc_minimal.so.4"
   ```

## API Issues

### 422 Validation Error

**Symptoms:**
```json
{
  "detail": [
    {
      "loc": ["body", "model"],
      "msg": "field required"
    }
  ]
}
```

**Cause:** Missing or incorrect API parameters.

**Solution:** Check API format
```python
# Correct format
response = client.chat.completions.create(
    model="facebook/opt-125m",  # Must match deployed model
    messages=[{"role": "user", "content": "Hello"}]
)
```

### Connection Refused

**Check container:**
```bash
docker ps | grep vllm-cpu
```

**Check port mapping:**
```bash
docker port vllm-cpu
```

**Test connection:**
```bash
curl -v http://localhost:8000/health
```

## Docker Issues

### Cannot Connect to Docker Daemon

**Symptoms:**
```
Cannot connect to the Docker daemon
```

**Solutions:**

Linux:
```bash
sudo systemctl start docker
sudo usermod -aG docker $USER
# Logout and login again
```

macOS/Windows:
- Start Docker Desktop

### Permission Denied

**Linux:**
```bash
sudo usermod -aG docker $USER
# Logout and login
```

### Docker BuildKit Error

**Symptoms:**
```
ERROR: BuildKit is enabled but not supported
```

**Solution:**
```bash
# Disable BuildKit
export DOCKER_BUILDKIT=0
./build.sh
```

## Getting Help

If you're still stuck:

1. **Check existing issues:**
   - https://github.com/SaroM0/vllm-AVX2-cpu-optimized/issues

2. **Gather information:**
   ```bash
   # System info
   uname -a
   lscpu | grep -E "Model name|Flags"
   docker --version
   
   # Container logs
   docker logs vllm-cpu > vllm-logs.txt
   
   # Resource usage
   docker stats vllm-cpu --no-stream
   ```

3. **Open an issue with:**
   - System information
   - Error messages and logs
   - Steps to reproduce
   - What you've tried

4. **Join community:**
   - GitHub Discussions
   - vLLM Discord
   - Stack Overflow (tag: vllm)

## FAQ

**Q: Is CPU inference production-ready?**
A: Generally no. CPU is 10-20x slower than GPU. Best for development/testing.

**Q: Can I use quantization to speed up?**
A: Yes, try INT8 or INT4 quantization. See vLLM docs for details.

**Q: What's the minimum RAM needed?**
A: Depends on model size. Rule of thumb: 2x model size. Example: 7B model ≈ 14GB RAM.

**Q: Can I use multiple CPUs?**
A: vLLM can use multiple cores, but not multiple CPU sockets effectively.

**Q: ARM64 support?**
A: Experimental. Try building on ARM64 system and report results.

**Q: Why is first request slow?**
A: Model loading and warmup. Subsequent requests are faster.

