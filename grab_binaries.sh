# Usage: ./grab_binaries.sh [image_tag]
# Example: ./grab_binaries.sh orcaslicer-wasm:debug

IMAGE_TAG="${1:-orcaslicer-wasm:locked-5.0.1}"

# 1) Create a container from the selected image
CID=$(docker create "$IMAGE_TAG")

# 2) Copy WASM artifacts out from /artifacts/ in the image
docker cp "$CID:/artifacts/orca-slicer.js" ./orca-slicer.js
docker cp "$CID:/artifacts/orca-slicer.wasm" ./orca-slicer.wasm
docker cp "$CID:/artifacts/orca-slicer.worker.js" ./orca-slicer.worker.js

echo "✓ Extracted WASM artifacts to current directory:"
ls -lh orca-slicer.js orca-slicer.wasm orca-slicer.worker.js

# 3) Clean up
docker rm "$CID"