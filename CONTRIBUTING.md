# Contributing to vLLM CPU Optimized

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to the project.

## How to Contribute

### Reporting Issues

If you encounter a problem:

1. **Check existing issues** to avoid duplicates
2. **Gather information**:
   - CPU model and features (`lscpu`)
   - Operating system and version
   - Docker version
   - Error messages and logs
3. **Create a detailed issue** with:
   - Clear description of the problem
   - Steps to reproduce
   - Expected vs actual behavior
   - System information
   - Relevant logs

### Suggesting Enhancements

We welcome suggestions for:

- New CPU architecture support
- Performance optimizations
- Documentation improvements
- Additional examples
- Better monitoring tools

Please open an issue with:
- Clear description of the enhancement
- Use case and benefits
- Implementation ideas (if any)

### Code Contributions

#### Development Setup

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/SaroM0/vllm-AVX2-cpu-optimized.git
   cd vllm-AVX2-cpu-optimized
   ```
3. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

#### Making Changes

1. **Test your changes**:
   ```bash
   # Build the image
   ./build.sh
   
   # Run tests
   ./run-example.sh
   
   # Test on your system
   docker-compose up
   ```

2. **Follow coding standards**:
   - Shell scripts: Use shellcheck
   - Python: Follow PEP 8
   - Clear, descriptive comments
   - Error handling

3. **Update documentation**:
   - Update README.md if needed
   - Add/update docs in `docs/`
   - Include inline comments for complex logic

4. **Commit your changes**:
   ```bash
   git add .
   git commit -m "feat: Add support for ARM64 architecture"
   ```

#### Commit Message Guidelines

Follow conventional commits:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `perf:` Performance improvements
- `refactor:` Code refactoring
- `test:` Test additions/changes
- `chore:` Build process or auxiliary tool changes

Examples:
```
feat: Add AVX512 detection and auto-configuration
fix: Resolve memory leak in monitor script
docs: Update troubleshooting guide with new CPU types
perf: Optimize core binding for hybrid CPUs
```

#### Pull Request Process

1. **Update documentation** for any new features
2. **Test thoroughly** on your system
3. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```
4. **Create Pull Request** with:
   - Clear description of changes
   - Related issue numbers
   - Testing performed
   - Screenshots/logs if relevant

5. **Respond to feedback**:
   - Address review comments
   - Update your PR as needed
   - Be patient and respectful

## Testing on Different CPU Architectures

We especially need testing on:

- Intel 10th-14th gen CPUs
- AMD Ryzen 3000-7000 series
- ARM64 CPUs (Apple Silicon, AWS Graviton)
- Server-grade CPUs (Xeon, EPYC)

If you test on a new CPU architecture:

1. Document the results in an issue
2. Include:
   - CPU model and features
   - Build time
   - Performance metrics (tokens/sec)
   - Any issues encountered
3. Consider adding a config file for that CPU

## Documentation Contributions

Documentation is crucial! You can help by:

- Fixing typos or unclear explanations
- Adding examples
- Translating to other languages
- Creating video tutorials
- Writing blog posts (link them in an issue)

## Community Guidelines

- **Be respectful** and inclusive
- **Help others** in discussions
- **Provide constructive feedback**
- **Share your experiences** with different hardware
- **Celebrate contributions** from others

## Development Roadmap

Current priorities:

1. **ARM64 Support**: Native builds for ARM CPUs
2. **Performance Benchmarks**: Standardized benchmarking suite
3. **Auto-Configuration**: Detect CPU features and configure automatically
4. **Monitoring Dashboard**: Web-based performance monitoring
5. **Multi-Model Support**: Run multiple models simultaneously

Want to work on something? Check the [issues](https://github.com/SaroM0/vllm-AVX2-cpu-optimized/issues) or propose your own!

## Questions?

- Open a [Discussion](https://github.com/SaroM0/vllm-AVX2-cpu-optimized/discussions)
- Join the [vLLM Discord](https://discord.gg/vllm)
- Check existing issues and docs

## Recognition

Contributors will be:
- Listed in our README
- Credited in release notes
- Recognized in the community

Thank you for contributing! 🎉

