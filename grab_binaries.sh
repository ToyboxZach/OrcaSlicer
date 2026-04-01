# Usage: ./grab_binaries.sh [image_tag]
# Example: ./grab_binaries.sh orcaslicer-wasm:debug

IMAGE_TAG="${1:-orcaslicer-wasm:locked-5.0.1}"

# 1) Create a container from the selected image
CID=$(docker create "$IMAGE_TAG")

# 2) Copy WASM artifacts out from /artifacts/ in the image
docker cp "$CID:/artifacts/orca-slicer.js" ./orca-slicer.js
docker cp "$CID:/artifacts/orca-slicer.wasm" ./orca-slicer.wasm

echo "✓ Extracted WASM artifacts to current directory:"
ls -lh orca-slicer.js orca-slicer.wasm 

# 3) Quick runtime config sanity check
echo "\nDetected runtime settings from orca-slicer.js:"
grep -Eo 'pthreadPoolSize=[^;]+' orca-slicer.js | head -n1 || true
grep -Eo 'INITIAL_MEMORY"\]\|\|[0-9]+' orca-slicer.js | head -n1 || true
if grep -q 'Cannot enlarge memory arrays to size' orca-slicer.js; then
	if grep -q 'abortOnCannotGrowMemory' orca-slicer.js; then
		echo "memory growth path: present"
	fi
fi

# 4) Clean up
docker rm "$CID"