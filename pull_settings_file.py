import json
import os
from typing import Dict

# example usage:
# python3  ./pull_settings_file.py "Alpha3Process" --root "/Users/zacholigschlaeger/Library/Application\ Support/OrcaSlicer" > Alpha3Process.json
def index_json_files(root_dir: str) -> Dict[str, str]:
    json_map = {}
    for dirpath, _, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename.endswith(".json"):
                name_without_ext = filename[:-5]
                json_map[name_without_ext] = os.path.join(dirpath, filename)
    return json_map

def load_full_json(name: str, json_map: Dict[str, str], visited=None) -> dict:
    if visited is None:
        visited = set()
    if name in visited:
        raise ValueError(f"Circular inheritance detected: {name}")
    visited.add(name)

    if name not in json_map:
        raise FileNotFoundError(f"'{name}.json' not found in scanned directories")

    with open(json_map[name], "r", encoding="utf-8") as f:
        data = json.load(f)

    base_data = {}
    if "inherits" in data:
        parent_name = data["inherits"]
        base_data = load_full_json(parent_name, json_map, visited)

    merged = {**base_data, **data}
    return merged

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Resolve JSON inheritance")
    parser.add_argument("json_name", help="JSON file name without .json (e.g. my_config)")
    parser.add_argument("--root", default=".", help="Root directory to scan")
    args = parser.parse_args()

    root_dir = normalize_root_dir(args.root)
    json_files = index_json_files(root_dir)
    resolved = load_full_json(args.json_name, json_files)

    print(json.dumps(resolved, indent=2, ensure_ascii=False))