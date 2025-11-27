# Ship Coordinate JSONs

This directory stores JSON files containing coordinate point data for ship sprites.

## Workflow

### 1. Mark Coordinates in HTML Tool
- Open `ship_visual_processor/ship_visual_processor.html` in browser
- Load `data/ship_visuals_database.csv`
- Select a ship and mark coordinate points (exhaust positions, weapon mounts, etc.)

### 2. Export JSON
- Click "Export to ship_JSONS/" button
- **Save the downloaded JSON file to this directory** (`tools/ship_JSONS/`)

### 3. Merge into CSV
Run the merge script from the project root:
```bash
python3 tools/merge_ship_coordinates.py
```

This will:
- Read all `.json` files from this directory
- Update `data/ship_visuals_database.csv` with the coordinate data
- Show progress for each ship updated

### 4. Verify in HTML Tool
- Reload the CSV in the HTML tool
- Select the ship - coordinate points should now appear in **green** (loaded from CSV)

## JSON Format

Each JSON file should follow this structure:
```json
{
  "ship_id": "basic_interceptor",
  "sprite_size": {
    "width": 32,
    "height": 32
  },
  "points": [
    {"label": "exhaust_1", "x": 16, "y": 28},
    {"label": "projectile_odd_row_1", "x": 10, "y": 8}
  ]
}
```

## File Naming

Recommended naming: `{ship_id}_points.json` (e.g., `basic_interceptor_points.json`)

The merge script will use the `ship_id` field in the JSON, not the filename.
