# Docker Linux Build for OrcaSlicer

This Docker-based build produces a native Linux x86_64 binary of OrcaSlicer, useful for testing cross-platform compatibility and CI/CD workflows.

## Quick Start

### Build the default headless CLI binary:

```bash
DOCKER_BUILDKIT=1 docker build --platform=linux/amd64 -f DockerFileLinux -t orcaslicer-linux:latest .
```

### Extract the binary:

```bash
./grab_linux_binary.sh
```

## Build Variants

### With GUI enabled:

```bash
DOCKER_BUILDKIT=1 docker build --platform=linux/amd64 -f DockerFileLinux -t orcaslicer-linux:gui \
  --build-arg SLIC3R_GUI=ON .
```

### Debug build:

```bash
DOCKER_BUILDKIT=1 docker build --platform=linux/amd64 -f DockerFileLinux -t orcaslicer-linux:debug \
  --build-arg BUILD_TYPE=Debug .
```

### With tests:

```bash
DOCKER_BUILDKIT=1 docker build --platform=linux/amd64 -f DockerFileLinux -t orcaslicer-linux:test \
  --build-arg BUILD_TESTS=ON .
```

### Headless mode (strip SLA features):

```bash
DOCKER_BUILDKIT=1 docker build --platform=linux/amd64 -f DockerFileLinux -t orcaslicer-linux:headless \
  --build-arg SLIC3R_HEADLESS=ON .
```

## Build Arguments

| Argument          | Default   | Description                                               |
| ----------------- | --------- | --------------------------------------------------------- |
| `BUILD_TYPE`      | `Release` | CMake build type: `Release`, `Debug`, or `RelWithDebInfo` |
| `SLIC3R_GUI`      | `OFF`     | Enable GUI components (wxWidgets, OpenGL)                 |
| `SLIC3R_STATIC`   | `ON`      | Link libraries statically                                 |
| `SLIC3R_HEADLESS` | `OFF`     | Remove SLA/resin printing features                        |
| `BUILD_TESTS`     | `OFF`     | Build and run test suite                                  |

## Architecture

The Docker build process:

1. **Base image**: Ubuntu 22.04 with all system dependencies
2. **Dependency building**: Cached layers for each major library (Boost, CGAL, OpenVDB, OCCT, etc.)
3. **OrcaSlicer build**: Uses bind mounts to avoid copying the full repository
4. **Artifact extraction**: Binary copied from cache mount to `/artifacts/` in the image

## Extraction

Use the provided extraction script:

```bash
./grab_linux_binary.sh [image_tag]
```

Or manually:

```bash
docker create --name temp_orca orcaslicer-linux:latest
docker cp temp_orca:/artifacts/orca-slicer ./orca-slicer
docker rm temp_orca
```

## Running the Binary

The extracted binary is dynamically linked and may require system libraries on your host:

```bash
# Check dependencies
ldd orca-slicer

# Run CLI
./orca-slicer --help
./orca-slicer --export-gcode model.stl
```

For GUI builds, you'll need X11 forwarding or a display server.

## Cache Management

Docker BuildKit caches are used for:

- `/ccache` - Compiler cache for faster rebuilds
- `/build` - CMake build artifacts

To rebuild from scratch:

```bash
docker builder prune  # Clear all build cache
```

To keep caches but force layer rebuild:

```bash
docker build --no-cache -f DockerFileLinux -t orcaslicer-linux:latest .
```

## Comparison to WASM Build

| Feature       | Linux Build             | WASM Build       |
| ------------- | ----------------------- | ---------------- |
| Target        | Native x86_64           | WebAssembly      |
| Platform      | Linux (Ubuntu/Debian)   | Browser/Node.js  |
| GUI           | Optional                | Disabled         |
| SLA Support   | Full (unless headless)  | Excluded         |
| Binary Output | `orca-slicer` ELF       | `.js` + `.wasm`  |
| Use Case      | Testing, CI/CD, servers | Web applications |

## Testing Native vs WASM Compatibility

To verify the SLIC3R_HEADLESS option doesn't break native builds:

```bash
# Native full build
DOCKER_BUILDKIT=1 docker build -f DockerFileLinux -t orca-native .

# Native headless build (should match WASM feature set)
DOCKER_BUILDKIT=1 docker build -f DockerFileLinux -t orca-headless \
  --build-arg SLIC3R_HEADLESS=ON .

# WASM build (auto-enables headless)
DOCKER_BUILDKIT=1 docker build -f DockerFileWasm -t orca-wasm .
```
