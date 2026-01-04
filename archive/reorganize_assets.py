#!/usr/bin/env python3
"""
Asset reorganization script for Operation Gotland RTS
Moves all assets into a unified structure under godot/assets/
"""

import os
import shutil
import re
from pathlib import Path
from typing import Dict, List, Tuple

# Base paths
GODOT_ROOT = Path("C:/Users/Bouncy/Desktop/projekt/OperationGotland-1/godot")
NEW_ASSETS_ROOT = GODOT_ROOT / "assets"

# New directory structure
NEW_STRUCTURE = {
    "models": NEW_ASSETS_ROOT / "models",
    "textures": NEW_ASSETS_ROOT / "textures",
    "terrain": NEW_ASSETS_ROOT / "terrain",
    "maps": NEW_ASSETS_ROOT / "maps",
    "vendor": NEW_ASSETS_ROOT / "vendor",
    "icons": NEW_ASSETS_ROOT / "icons",
}

# File type mappings
FILE_CATEGORIES = {
    "models": [".glb", ".fbx", ".obj", ".gltf"],
    "textures": [".png", ".jpg", ".jpeg", ".tga", ".bmp"],
    "terrain": [".res"],  # Terrain3D resource files
    "maps": [".json"],  # Map data
}

# Existing folders to consolidate
CONSOLIDATE_FOLDERS = {
    "demo/assets/textures": "textures",
    "assets/maps": "maps",
    "assets/vendor": "vendor",
}

def create_directory_structure():
    """Create the new unified asset directory structure"""
    print("Creating new asset directory structure...")
    for name, path in NEW_STRUCTURE.items():
        path.mkdir(parents=True, exist_ok=True)
        print(f"  Created: {path.relative_to(GODOT_ROOT)}")

def move_loose_files():
    """Move all loose asset files from godot root to appropriate folders"""
    print("\nMoving loose files from root directory...")
    moved_count = 0

    # Get all files in godot root (not subdirectories)
    for item in GODOT_ROOT.iterdir():
        if not item.is_file():
            continue

        ext = item.suffix.lower()

        # Skip .import files and project.godot
        if ext == ".import" or item.name == "project.godot":
            continue

        # Determine destination
        dest_folder = None

        # Terrain resource files
        if ext == ".res" and item.name.startswith("terrain3d"):
            dest_folder = NEW_STRUCTURE["terrain"]
        # 3D models
        elif ext in FILE_CATEGORIES["models"]:
            dest_folder = NEW_STRUCTURE["models"]
        # Textures (usually model textures with numbered suffixes)
        elif ext in FILE_CATEGORIES["textures"]:
            # Check if it's a model texture (has _0, _1, etc suffix)
            if re.search(r'_\d+\.(png|jpg)$', item.name):
                dest_folder = NEW_STRUCTURE["models"]  # Keep with models
            else:
                dest_folder = NEW_STRUCTURE["textures"]

        if dest_folder:
            dest_path = dest_folder / item.name
            print(f"  Moving: {item.name} -> {dest_path.relative_to(GODOT_ROOT)}")
            shutil.move(str(item), str(dest_path))

            # Also move .import file if it exists
            import_file = Path(str(item) + ".import")
            if import_file.exists():
                shutil.move(str(import_file), str(dest_path) + ".import")

            moved_count += 1

    print(f"Moved {moved_count} files")

def consolidate_existing_folders():
    """Consolidate existing asset folders into new structure"""
    print("\nConsolidating existing asset folders...")

    # Move demo/assets/textures contents to assets/textures
    demo_textures = GODOT_ROOT / "demo" / "assets" / "textures"
    if demo_textures.exists():
        for item in demo_textures.iterdir():
            dest = NEW_STRUCTURE["textures"] / item.name
            print(f"  Moving: {item.relative_to(GODOT_ROOT)} -> {dest.relative_to(GODOT_ROOT)}")
            if dest.exists():
                print(f"    Warning: {dest.name} already exists, skipping")
            else:
                shutil.move(str(item), str(dest))

    # Move assets/maps to new structure (if different)
    old_maps = GODOT_ROOT / "assets" / "maps"
    if old_maps.exists() and old_maps != NEW_STRUCTURE["maps"]:
        # Assets/maps should already be in the right place, just verify
        print(f"  Maps folder already in correct location")

    # Move assets/vendor
    old_vendor = GODOT_ROOT / "assets" / "vendor"
    if old_vendor.exists() and old_vendor != NEW_STRUCTURE["vendor"]:
        print(f"  Vendor folder already in correct location")

def find_all_references() -> Dict[str, List[str]]:
    """Find all file references that need to be updated"""
    print("\nScanning for file references to update...")
    references = {}

    # Scan .tscn files
    for tscn_file in GODOT_ROOT.rglob("*.tscn"):
        if ".godot" in str(tscn_file):
            continue
        refs = scan_file_for_paths(tscn_file)
        if refs:
            references[str(tscn_file)] = refs

    # Scan .gd files
    for gd_file in GODOT_ROOT.rglob("*.gd"):
        if ".godot" in str(gd_file):
            continue
        refs = scan_file_for_paths(gd_file)
        if refs:
            references[str(gd_file)] = refs

    total_refs = sum(len(refs) for refs in references.values())
    print(f"Found {total_refs} references in {len(references)} files")

    return references

def scan_file_for_paths(filepath: Path) -> List[str]:
    """Scan a file for res:// paths"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        # Find all res:// paths
        pattern = r'res://[^"\s\]]+'
        matches = re.findall(pattern, content)
        return list(set(matches))  # Unique paths
    except Exception as e:
        print(f"  Error reading {filepath}: {e}")
        return []

def create_path_mapping() -> Dict[str, str]:
    """Create a mapping of old paths to new paths"""
    mapping = {}

    # Map loose model files
    for ext in FILE_CATEGORIES["models"]:
        for old_file in GODOT_ROOT.glob(f"*{ext}"):
            if old_file.is_file():
                old_path = f"res://{old_file.name}"
                new_path = f"res://assets/models/{old_file.name}"
                mapping[old_path] = new_path

    # Map loose texture files
    for ext in FILE_CATEGORIES["textures"]:
        for old_file in GODOT_ROOT.glob(f"*{ext}"):
            if old_file.is_file():
                old_path = f"res://{old_file.name}"
                # Check if it's a model texture
                if re.search(r'_\d+\.(png|jpg)$', old_file.name):
                    new_path = f"res://assets/models/{old_file.name}"
                else:
                    new_path = f"res://assets/textures/{old_file.name}"
                mapping[old_path] = new_path

    # Map terrain files
    for old_file in GODOT_ROOT.glob("terrain3d*.res"):
        if old_file.is_file():
            old_path = f"res://{old_file.name}"
            new_path = f"res://assets/terrain/{old_file.name}"
            mapping[old_path] = new_path

    # Map demo/assets/textures
    demo_tex = GODOT_ROOT / "demo" / "assets" / "textures"
    if demo_tex.exists():
        for tex_file in demo_tex.rglob("*"):
            if tex_file.is_file() and tex_file.suffix in FILE_CATEGORIES["textures"]:
                rel_path = tex_file.relative_to(demo_tex)
                old_path = f"res://demo/assets/textures/{rel_path.as_posix()}"
                new_path = f"res://assets/textures/{rel_path.as_posix()}"
                mapping[old_path] = new_path

    return mapping

def update_file_references(path_mapping: Dict[str, str]):
    """Update all file references to new paths"""
    print("\nUpdating file references...")
    updated_files = 0

    # Update .tscn files
    for tscn_file in GODOT_ROOT.rglob("*.tscn"):
        if ".godot" in str(tscn_file):
            continue
        if update_paths_in_file(tscn_file, path_mapping):
            updated_files += 1

    # Update .gd files
    for gd_file in GODOT_ROOT.rglob("*.gd"):
        if ".godot" in str(gd_file):
            continue
        if update_paths_in_file(gd_file, path_mapping):
            updated_files += 1

    # Update .import files
    for import_file in GODOT_ROOT.rglob("*.import"):
        if ".godot" in str(import_file):
            continue
        if update_paths_in_file(import_file, path_mapping):
            updated_files += 1

    print(f"Updated {updated_files} files")

def update_paths_in_file(filepath: Path, path_mapping: Dict[str, str]) -> bool:
    """Update paths in a single file, return True if any changes made"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        original_content = content

        # Replace all mapped paths
        for old_path, new_path in path_mapping.items():
            content = content.replace(old_path, new_path)

        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"  Updated: {filepath.relative_to(GODOT_ROOT)}")
            return True

        return False
    except Exception as e:
        print(f"  Error updating {filepath}: {e}")
        return False

def main():
    """Main reorganization process"""
    print("=" * 60)
    print("Operation Gotland - Asset Reorganization")
    print("=" * 60)

    # Safety check
    if not GODOT_ROOT.exists():
        print(f"Error: Godot root not found at {GODOT_ROOT}")
        return

    print(f"\nWorking directory: {GODOT_ROOT}")
    print("\nThis will reorganize all assets into:")
    for name, path in NEW_STRUCTURE.items():
        print(f"  - {path.relative_to(GODOT_ROOT)}")

    response = input("\nProceed? (yes/no): ")
    if response.lower() != "yes":
        print("Cancelled.")
        return

    # Execute reorganization steps
    create_directory_structure()

    # Create path mapping BEFORE moving files (while old paths still exist)
    path_mapping = create_path_mapping()
    print(f"\nCreated path mapping with {len(path_mapping)} entries")

    move_loose_files()
    consolidate_existing_folders()
    update_file_references(path_mapping)

    print("\n" + "=" * 60)
    print("Reorganization complete!")
    print("=" * 60)
    print("\nNew structure:")
    print(f"  godot/assets/")
    print(f"    ├── models/      (3D models + textures)")
    print(f"    ├── textures/    (standalone textures)")
    print(f"    ├── terrain/     (Terrain3D data)")
    print(f"    ├── maps/        (map JSON files)")
    print(f"    └── vendor/      (third-party assets)")
    print("\nPlease test your project in Godot to ensure everything works!")

if __name__ == "__main__":
    main()
