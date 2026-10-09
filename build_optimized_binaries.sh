#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET_PLATFORM="linux/amd64"
LINUX_IMAGE="orcaslicer-linux:opt"
WASM_IMAGE="orcaslicer-wasm:opt"
OUTPUT_DIR="${1:-"${SCRIPT_DIR}/build_optimized_binaries"}"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Usage: $0 [output-folder]"
    echo "Build optimized Linux and WASM binaries for ${TARGET_PLATFORM}."
    echo "Default output: ${SCRIPT_DIR}/build_optimized_binaries"
    exit 0
fi
if (( $# > 1 )); then
    echo "Usage: $0 [output-folder]" >&2
    exit 2
fi
if [[ "${OUTPUT_DIR}" != /* ]]; then
    OUTPUT_DIR="${SCRIPT_DIR}/${OUTPUT_DIR}"
fi

if ! command -v docker >/dev/null 2>&1; then
    echo "Error: docker is required but was not found in PATH." >&2
    exit 1
fi

export DOCKER_BUILDKIT=1

cd "${SCRIPT_DIR}"
echo "Building optimized Linux binary (${LINUX_IMAGE})..."
docker build --platform="${TARGET_PLATFORM}" -f DockerFileLinux -t "${LINUX_IMAGE}" \
    --build-arg BUILD_TYPE=Release \
    --build-arg SLIC3R_GUI=OFF \
    --build-arg SLIC3R_HEADLESS=ON \
    --build-arg SLIC3R_STATIC=ON \
    .

echo "Building optimized WASM binaries (${WASM_IMAGE})..."
docker build --platform="${TARGET_PLATFORM}" -f DockerFileWasm -t "${WASM_IMAGE}" \
    --build-arg 'EMSCRIPT_CXX_FLAGS=-DPRINT_STATISTICS_IN_CONSOLE -DSMALL_WASM_BINARY=1 -pthread -matomics -mbulk-memory -ferror-limit=0 -fwasm-exceptions -DNDEBUG' \
    .

mkdir -p "${OUTPUT_DIR}/linux-amd64" "${OUTPUT_DIR}/wasm"

copy_artifact() {
    local image="$1"
    local source="$2"
    local destination="$3"
    local container_id

    container_id="$(docker create --platform="${TARGET_PLATFORM}" "${image}")"
    if ! docker cp "${container_id}:${source}" "${destination}"; then
        docker rm "${container_id}" >/dev/null
        return 1
    fi
    docker rm "${container_id}" >/dev/null
}

echo "Extracting artifacts to ${OUTPUT_DIR}..."
copy_artifact "${LINUX_IMAGE}" "/artifacts/orca-slicer" "${OUTPUT_DIR}/linux-amd64/orca-slicer"
copy_artifact "${WASM_IMAGE}" "/artifacts/orca-slicer.js" "${OUTPUT_DIR}/wasm/orca-slicer.js"
copy_artifact "${WASM_IMAGE}" "/artifacts/orca-slicer.wasm" "${OUTPUT_DIR}/wasm/orca-slicer.wasm"

printf '\nOptimized binaries are ready:\n'
ls -lh "${OUTPUT_DIR}/linux-amd64/orca-slicer" \
    "${OUTPUT_DIR}/wasm/orca-slicer.js" \
    "${OUTPUT_DIR}/wasm/orca-slicer.wasm"
