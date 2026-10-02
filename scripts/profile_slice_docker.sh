#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

usage() {
    echo "Usage: $0 MODEL [OUTPUT_DIR] [PLATE] [PROFILES_DIR]" >&2
    echo "If PROFILES_DIR is omitted, looks for ../profiles beside the model directory." >&2
    echo "Builds/uses an OrcaSlicer Linux Docker image and writes profiling output." >&2
}

if [[ $# -lt 1 || $# -gt 4 ]]; then
    usage
    exit 2
fi

MODEL_ARG=$1
OUTPUT_ARG=${2:-"$PWD/orca-profile-output"}
PLATE=${3:-${ORCA_PROFILE_PLATE:-1}}
PROFILES_ARG=${4:-${ORCA_PROFILE_DIR:-}}
MODEL_DIR="$(cd -- "$(dirname -- "$MODEL_ARG")" && pwd)"
MODEL_NAME="$(basename "$MODEL_ARG")"
MODEL_PATH="$MODEL_DIR/$MODEL_NAME"

if [[ ! -f "$MODEL_PATH" ]]; then
    echo "Model not found: $MODEL_PATH" >&2
    exit 2
fi

if [[ -z "$PROFILES_ARG" && -d "$MODEL_DIR/../profiles" ]]; then
    PROFILES_ARG="$MODEL_DIR/../profiles"
fi

SETTING_PROFILES=()
FILAMENT_PROFILES=()
PROFILE_DIR=""
if [[ -n "$PROFILES_ARG" ]]; then
    if [[ ! -d "$PROFILES_ARG" ]]; then
        echo "Profiles directory not found: $PROFILES_ARG" >&2
        exit 2
    fi
    if ! command -v python3 >/dev/null 2>&1; then
        echo "python3 is required to identify printer, process, and filament JSON profiles." >&2
        exit 2
    fi
    PROFILE_DIR="$(cd -- "$PROFILES_ARG" && pwd)"
    while IFS=$'\t' read -r profile_type profile_name; do
        case "$profile_type" in
            machine|process) SETTING_PROFILES+=("/profiles/$profile_name") ;;
            filament) FILAMENT_PROFILES+=("/profiles/$profile_name") ;;
        esac
    done < <(python3 - "$PROFILE_DIR" <<'PY'
import json
import pathlib
import sys

for path in sorted(pathlib.Path(sys.argv[1]).glob("*.json")):
    with path.open(encoding="utf-8") as profile_file:
        profile_type = json.load(profile_file).get("type", "")
    print(f"{profile_type}\t{path.name}")
PY
)
    if [[ ${#SETTING_PROFILES[@]} -eq 0 || ${#FILAMENT_PROFILES[@]} -eq 0 ]]; then
        echo "Profiles directory must contain at least one machine/process JSON and one filament JSON: $PROFILE_DIR" >&2
        exit 2
    fi
fi

mkdir -p "$OUTPUT_ARG"
OUTPUT_DIR="$(cd -- "$OUTPUT_ARG" && pwd)"
mkdir -p "$OUTPUT_DIR/profile-data"

IMAGE=${ORCA_PROFILE_IMAGE:-orcaslicer-linux:profile}
PLATFORM=${ORCA_DOCKER_PLATFORM:-linux/amd64}
CPUS=${ORCA_PROFILE_CPUS:-2}
MEMORY=${ORCA_PROFILE_MEMORY:-8g}
if [[ ${ORCA_PROFILE_REBUILD:-0} != 0 ]] || ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    echo "Building Docker image '$IMAGE' (first build can take a while)..."
    DOCKER_BUILDKIT=1 docker build \
        --platform "$PLATFORM" \
        -f "$REPO_ROOT/DockerFileLinux" \
        -t "$IMAGE" \
        "$REPO_ROOT"
fi

echo "Slicing $MODEL_NAME in Docker (plate $PLATE)"
echo "Results: $OUTPUT_DIR"
echo "Docker limits: $CPUS CPUs, $MEMORY RAM (m6a.large resource profile)"
DOCKER_ARGS=(docker run --rm --platform "$PLATFORM" --cpus "$CPUS" --memory "$MEMORY" --memory-swap "$MEMORY")
if [[ -n ${ORCA_PROFILE_TBB_THREADS:-} ]]; then
    DOCKER_ARGS+=(--env "ORCA_PROFILE_TBB_THREADS=$ORCA_PROFILE_TBB_THREADS")
    echo "TBB parallelism cap: $ORCA_PROFILE_TBB_THREADS"
fi
if [[ -n "$PROFILE_DIR" ]]; then
    SETTINGS_ARG=$(IFS=';'; printf '%s' "${SETTING_PROFILES[*]}")
    FILAMENTS_ARG=$(IFS=';'; printf '%s' "${FILAMENT_PROFILES[*]}")
    echo "Loading profiles from: $PROFILE_DIR"
    DOCKER_ARGS+=(--mount "type=bind,source=$PROFILE_DIR,target=/profiles,readonly")
    PROFILE_ARGS=(--load-settings "$SETTINGS_ARG" --load-filaments "$FILAMENTS_ARG")
else
    PROFILE_ARGS=()
fi
set -o pipefail
"${DOCKER_ARGS[@]}" \
    --user "$(id -u):$(id -g)" \
    --env ORCA_PROFILE=1 \
    --env ORCA_PROFILE_DETAIL=1 \
    --mount "type=bind,source=$MODEL_DIR,target=/input,readonly" \
    --mount "type=bind,source=$REPO_ROOT/resources,target=/resources,readonly" \
    --mount "type=bind,source=$OUTPUT_DIR,target=/output" \
    --entrypoint /usr/bin/time \
    "$IMAGE" \
    -v -o /output/profile-time.txt \
    /artifacts/orca-slicer \
    --debug 3 \
    --no-check \
    --slice "$PLATE" \
    --datadir /output/profile-data \
    --outputdir /output \
    "${PROFILE_ARGS[@]}" \
    "/input/$MODEL_NAME" 2>&1 | tee "$OUTPUT_DIR/profile.log"

echo
echo "Profiling complete:"
echo "  Phase log: $OUTPUT_DIR/profile.log"
echo "  Whole-process CPU/RSS: $OUTPUT_DIR/profile-time.txt"
echo "  G-code(s): $OUTPUT_DIR/plate_*.gcode"
