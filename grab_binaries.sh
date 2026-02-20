# Usage: ./grab_binaries.sh [image_tag]
# Example: ./grab_binaries.sh orcaslicer-wasm:debug

IMAGE_TAG="${1:-orcaslicer-wasm:locked-3.1.39}"

# 1) Create a container from the selected image
CID=$(docker create "$IMAGE_TAG")

# 2) Copy WASM artifacts out (prefer new cached build path, fallback to legacy path)
if docker cp "$CID:/build_wasm/src/orca-slicer.js" ./orca-slicer.js; then
	docker cp "$CID:/build_wasm/src/orca-slicer.wasm" ./orca-slicer.wasm
else
	docker cp "$CID:/work/build_wasm/src/orca-slicer.js" ./orca-slicer.js
	docker cp "$CID:/work/build_wasm/src/orca-slicer.wasm" ./orca-slicer.wasm
fi

# Optional: copy everything from the build output dir
# docker cp "$CID:/build_wasm/src" ./wasm_artifacts

# 3) Clean up
docker rm "$CID"