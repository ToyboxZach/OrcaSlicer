#!/usr/bin/env bash
set -eu

BIN="${1:?orca-slicer binary required}"
PY="${2:-python3}"
[ -x "$BIN" ] || { echo "SKIP: orca-slicer binary not found: $BIN"; exit 77; }
WORK="$(mktemp -d "${TMPDIR:-/tmp}/orca-empty-first-layer.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/datadir"

cat > "$WORK/machine.json" <<'EOF'
{
    "type": "machine",
    "from": "User",
    "name": "First layer test printer",
    "printable_area": ["0x0", "200x0", "200x200", "0x200"],
    "printable_height": "300",
    "layer_change_gcode": "G92 E0"
}
EOF
cat > "$WORK/process.json" <<'EOF'
{
    "type": "process",
    "from": "User",
    "name": "First layer test process",
    "enable_support": "0",
    "enforce_support_layers": "0",
    "detect_thin_wall": "0",
    "wall_generator": "classic"
}
EOF

"$PY" - "$WORK" <<'EOF'
import sys
from pathlib import Path

def write(name, rings):
    vertices = [v for ring in rings for v in ring]
    top = 4 * (len(rings) - 1)
    faces = [(0, 2, 1), (0, 3, 2), (top, top + 1, top + 2), (top, top + 2, top + 3)]
    for r in range(len(rings) - 1):
        for i in range(4):
            a, b = 4 * r + i, 4 * r + (i + 1) % 4
            faces.extend(((a, b, b + 4), (a, b + 4, a + 4)))
    with (Path(sys.argv[1]) / (name + ".stl")).open("w") as f:
        f.write("solid test\n")
        for face in faces:
            f.write("facet normal 0 0 0\nouter loop\n")
            for i in face:
                f.write("vertex %g %g %g\n" % vertices[i])
            f.write("endloop\nendfacet\n")
        f.write("endsolid test\n")

def ring(radius, z):
    return [(-radius, -radius, z), (radius, -radius, z),
            (radius, radius, z), (-radius, radius, z)]

write("narrow", [ring(0.01, 0), ring(10, 20)])
write("cube", [ring(10, 0), ring(10, 20)])
write("beyond_limit", [ring(0.01, 0), ring(0.01, 205), ring(10, 210)])
EOF

run() {
    local name="$1" model="$2"
    shift 2
    mkdir -p "$WORK/$name"
    "$BIN" --datadir "$WORK/datadir" --load-settings "$WORK/machine.json;$WORK/process.json" \
        "$@" --slice 0 --outputdir "$WORK/$name" "$WORK/$model.stl" >"$WORK/$name/log" 2>&1
}

if run disabled narrow; then
    echo "An empty first layer unexpectedly succeeded without --allow-tb-fixes" >&2
    exit 1
fi
grep -q "empty first layer" "$WORK/disabled/log"
if run explicitly_disabled narrow --allow-tb-fixes=0; then
    echo "An empty first layer unexpectedly succeeded with --allow-tb-fixes=0" >&2
    exit 1
fi
grep -q "empty first layer" "$WORK/explicitly_disabled/log"

if ! run narrow narrow --allow-tb-fixes; then
    cat "$WORK/narrow/log" >&2
    exit 1
fi
grep -q "Automatically lowered object" "$WORK/narrow/log"
test -s "$WORK/narrow/plate_1.gcode"
"$PY" - "$WORK/narrow/result.json" <<'EOF'
import json
import sys

with open(sys.argv[1]) as f:
    result = json.load(f)
fixes = [w for w in result["warnings"] if w["class"] == "auto_cut_empty_first_layer"]
assert fixes and all(0 < w["lowered_mm"] <= 200 for w in fixes), fixes
EOF

if ! run cube cube --allow-tb-fixes; then
    cat "$WORK/cube/log" >&2
    exit 1
fi
if grep -q "Automatically lowered object" "$WORK/cube/log"; then
    echo "A printable first layer was unexpectedly lowered" >&2
    exit 1
fi
test -s "$WORK/cube/plate_1.gcode"

if run beyond_limit beyond_limit --allow-tb-fixes; then
    echo "A first printable layer beyond the 200 mm limit unexpectedly succeeded" >&2
    exit 1
fi
grep -q "empty first layer" "$WORK/beyond_limit/log"
if grep -q "Automatically lowered object" "$WORK/beyond_limit/log"; then
    echo "The 200 mm limit was exceeded" >&2
    exit 1
fi
