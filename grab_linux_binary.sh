#!/bin/bash
# Usage: ./grab_linux_binary.sh [image_tag]
# Example: ./grab_linux_binary.sh orcaslicer-linux:debug

IMAGE_TAG="${1:-orcaslicer-linux:latest}"

# 1) Create a container from the selected image
CID=$(docker create "$IMAGE_TAG")

# 2) Copy Linux binary from /artifacts/ in the image
docker cp "$CID:/artifacts/orca-slicer" ./orca-slicer

echo "✓ Extracted Linux binary to current directory:"
ls -lh orca-slicer
echo
echo "Binary info:"
file orca-slicer

# 3) Clean up
docker rm "$CID"

echo
echo "To run the binary (may require dependencies on your system):"
echo "  ./orca-slicer --help"
