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

## Profile a model in Docker

Use the helper to build the headless Linux image if needed, slice a model, and collect measurements:

```bash
bash scripts/profile_slice_docker.sh /path/to/model.3mf
```

The script writes `profile.log`, `profile-time.txt`, and the generated G-code into `./orca-profile-output` by default. You can choose another output directory and plate:

```bash
bash scripts/profile_slice_docker.sh /path/to/model.3mf ./slice-profile 2
```

For an STL with exported OrcaSlicer JSON presets, place the `profiles/` directory beside the model's containing directory (for example, `Test Files/giant/model.stl` and `Test Files/profiles/*.json`). The script auto-detects `../profiles`, loading machine/process files with `--load-settings` and filament files with `--load-filaments`. You can also pass the profile directory as the fourth argument or set `ORCA_PROFILE_DIR`.

The container defaults to the AWS `m6a.large` resource envelope: `linux/amd64`, 2 vCPU, and 8 GiB RAM, with swap disabled for the run. Override the CPU and memory caps with `ORCA_PROFILE_CPUS` and `ORCA_PROFILE_MEMORY`; the platform can be changed with `ORCA_DOCKER_PLATFORM`. Set `ORCA_PROFILE_TBB_THREADS` to optionally cap oneTBB parallelism for a profiling comparison (for example, `ORCA_PROFILE_TBB_THREADS=2`). On macOS, Docker Desktop must be allocated at least 8 GiB. These limits match the instance capacity, but running under Docker Desktop does not reproduce the AWS AMD EPYC CPU model or performance.

The runner enables `ORCA_PROFILE_DETAIL=1`, which adds aggregated nested timings for infill preparation, surface grouping, grid scanline generation, clipping, and path connection. After changing slicer source, use `ORCA_PROFILE_REBUILD=1` for one run so Docker rebuilds the executable with those changes while reusing its dependency caches.

`profile.log` contains `[ORCA_PROFILE]` records for slice/perimeter generation, infill, support, conflict checking, G-code export, and other major phases. Each record includes wall time, process CPU time (summed across worker threads), and start/end RSS plus a 50 ms sampled RSS peak. `profile-time.txt` is GNU `time -v` output for the whole CLI process, including maximum resident set size. RSS peaks sampled inside short phases may be missed; the whole-process peak is still reported separately.

The script enables this instrumentation only for its run. To use it with another Linux build, set `ORCA_PROFILE=1` and run OrcaSlicer with `--debug 3`. A 3MF with embedded print settings is the easiest input; standalone STL files need printer, filament, and process profiles supplied separately.

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
