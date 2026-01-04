# Asset Organization Structure

## Overview
All game assets are now organized under `godot/assets/` for easy management and clear separation from code.

## Directory Structure

```
godot/
├── assets/                         # Main assets directory
│   ├── models/                     # 3D models and their textures
│   │   ├── airfield.glb
│   │   ├── airfield_*.png
│   │   ├── barracks.glb
│   │   ├── barracks_*.png/jpg
│   │   ├── factory.glb
│   │   ├── factory_*.png
│   │   ├── gripen.glb
│   │   ├── gripen_*.png
│   │   ├── f-35_lightning_ii_-_fighter_jet_-_free.glb
│   │   └── f-35_lightning_ii_-_fighter_jet_-_free_*.png
│   │
│   ├── textures/                   # Standalone textures
│   │   ├── ground037_alb_ht.png
│   │   ├── ground037_nrm_rgh.png
│   │   ├── rock023_alb_ht.png
│   │   ├── rock023_nrm_rgh.png
│   │   ├── Grass004_1K-JPG_Color.jpg
│   │   ├── Ground068_1K-JPG_Color.jpg
│   │   ├── Ice002_1K-JPG_Color.jpg
│   │   └── icon.png
│   │
│   ├── terrain/                    # Terrain3D data files
│   │   └── terrain3d_*.res         # All terrain resource files
│   │
│   ├── maps/                       # Map data files
│   │   └── gotland_*.png           # Map textures and data
│   │
│   ├── vendor/                     # Third-party assets
│   │   └── kenney_city-kit-industrial/
│   │
│   └── icons/                      # UI icons (if needed)
│
├── scenes/                         # Godot scene files (.tscn)
├── scripts/                        # GDScript files (.gd)
├── data/                          # Game data (JSON, etc.)
└── addons/                        # Godot addons (Terrain3D, etc.)
```

## Asset Categories

### Models (`assets/models/`)
- **3D models** (.glb, .fbx, .obj)
- **Model textures** (automatically imported with numbered suffixes like `_0.png`, `_1.png`)
- All textures that belong to a specific model are kept together

### Textures (`assets/textures/`)
- **Standalone textures** used across multiple objects
- **Terrain textures** for Terrain3D material
- **UI elements** and icons

### Terrain (`assets/terrain/`)
- **Terrain3D resource files** (.res)
- Height maps, splat maps, and other terrain data
- Referenced by Terrain3D nodes via `data_directory = "res://assets/terrain"`

### Maps (`assets/maps/`)
- **Map definition files** (JSON)
- **Map-specific textures** (satellite imagery, height maps)

### Vendor (`assets/vendor/`)
- **Third-party asset packs** (Kenney assets, etc.)
- Preserved in original structure for licensing clarity

## Path Conventions

All asset paths use Godot's `res://` protocol:

```gdscript
# Models
res://assets/models/barracks.glb

# Textures
res://assets/textures/ground037_alb_ht.png

# Terrain data directory
res://assets/terrain

# Maps
res://assets/maps/gotland_satellite_z10.png
```

## Import Files

Godot automatically creates `.import` files alongside assets. These are automatically moved with their parent files and should **not** be manually edited.

## Adding New Assets

When adding new assets:

1. **3D Models**: Place in `assets/models/` (textures will auto-import there)
2. **Textures**: Place in `assets/textures/`
3. **Terrain Data**: Let Terrain3D save to `assets/terrain/`
4. **Maps**: Place JSON and map textures in `assets/maps/`

## Migration Notes

This structure was created on 2026-01-03 by consolidating:
- Loose files from `godot/` root (96 files)
- `demo/assets/textures/` contents
- `terr/` folder contents
- Existing `assets/` subfolders

All references in `.tscn`, `.gd`, and `.import` files were automatically updated.

## Cleanup

The following old locations are now empty and can be safely removed:
- `godot/demo/` (if empty)
- Any remaining empty asset folders

---

**Last Updated**: 2026-01-03
