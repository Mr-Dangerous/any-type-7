#!/usr/bin/env python3
"""
Merge ship coordinate JSONs into ship_visuals_database.csv

Reads all JSON files from tools/ship_JSONS/ and updates the
coordinate_points column in the CSV.
"""

import json
import os
from pathlib import Path

# Paths
SCRIPT_DIR = Path(__file__).parent
JSON_DIR = SCRIPT_DIR / "ship_JSONS"
CSV_PATH = SCRIPT_DIR.parent / "data" / "ship_visuals_database.csv"

def load_json_files():
    """Load all ship coordinate JSONs from ship_JSONS directory"""
    ship_data = {}

    if not JSON_DIR.exists():
        print(f"Creating directory: {JSON_DIR}")
        JSON_DIR.mkdir(exist_ok=True)
        return ship_data

    json_files = list(JSON_DIR.glob("*.json"))

    if not json_files:
        print(f"No JSON files found in {JSON_DIR}")
        return ship_data

    print(f"Found {len(json_files)} JSON file(s)")

    for json_file in json_files:
        try:
            with open(json_file, 'r') as f:
                data = json.load(f)
                ship_id = data.get('ship_id')
                points = data.get('points', [])
                sprite_size = data.get('sprite_size', {})
                png_size = data.get('png_size', {})  # NEW
                scale_factor = data.get('scale_factor')  # NEW

                if ship_id:
                    ship_data[ship_id] = {
                        'points': points,
                        'sprite_size': sprite_size,
                        'png_size': png_size,
                        'scale_factor': scale_factor
                    }

                    size_info = f"sprite: {sprite_size.get('width')}×{sprite_size.get('height')}" if sprite_size else "no size"

                    if png_size:
                        size_info += f", PNG: {png_size.get('width')}×{png_size.get('height')}"

                    if scale_factor:
                        size_info += f", scale: {scale_factor:.4f}"

                    print(f"  ✓ {json_file.name}: {len(points)} points ({size_info})")
                else:
                    print(f"  ✗ {json_file.name}: Missing ship_id")
        except Exception as e:
            print(f"  ✗ {json_file.name}: Error - {e}")

    return ship_data

def update_csv(ship_data):
    """Update ship_visuals_database.csv with coordinate data and sprite sizes"""

    if not CSV_PATH.exists():
        print(f"Error: CSV not found at {CSV_PATH}")
        return

    # Read CSV
    with open(CSV_PATH, 'r') as f:
        lines = f.readlines()

    # Process lines
    updated_lines = []
    updated_count = 0

    for line in lines:
        stripped = line.strip()

        # Keep comments and empty lines
        if not stripped or stripped.startswith('#'):
            updated_lines.append(line)
            continue

        # Parse CSV line (handle JSON arrays in coordinate_points)
        parts = []
        current = ''
        in_brackets = False

        for char in line:
            if char == '[':
                in_brackets = True
            if char == ']':
                in_brackets = False

            if char == ',' and not in_brackets:
                parts.append(current)
                current = ''
            else:
                current += char
        parts.append(current.rstrip('\n'))  # Last part

        # If this is the header, just keep it
        if 'ship_ID' in parts[0]:
            updated_lines.append(line)
            continue

        # Extract ship_ID (first column)
        ship_id = parts[0].strip()

        # If we have data for this ship, update it
        if ship_id in ship_data:
            # Ensure we have the right number of columns (14 total, was 13)
            while len(parts) < 14:
                parts.append('')

            data = ship_data[ship_id]
            updates = []

            # Update sprite_width and sprite_height if provided (columns 3 and 4)
            if data.get('sprite_size'):
                sprite_size = data['sprite_size']
                if 'width' in sprite_size:
                    parts[3] = str(sprite_size['width'])
                if 'height' in sprite_size:
                    parts[4] = str(sprite_size['height'])
                    updates.append(f"sprite: {sprite_size['width']}×{sprite_size['height']}")

            # Update scale_factor (column 5) - NEW
            if data.get('scale_factor'):
                scale_factor = data['scale_factor']
                parts[5] = f"{scale_factor:.4f}"
                updates.append(f"scale: {scale_factor:.4f}")

            # Validate coordinates
            if data.get('png_size') and data.get('points'):
                png_width = data['png_size']['width']
                png_height = data['png_size']['height']

                for point in data['points']:
                    if point['x'] > png_width or point['y'] > png_height:
                        print(f"  ⚠ WARNING {ship_id}: Point '{point['label']}' ({point['x']}, {point['y']}) exceeds PNG size")
                    if point['x'] < 0 or point['y'] < 0:
                        print(f"  ⚠ WARNING {ship_id}: Point '{point['label']}' has negative coordinates")

            # Update coordinate_points (column 13, was 12)
            if data.get('points'):
                parts[13] = json.dumps(data['points'])
                updates.append(f"{len(data['points'])} points")

            updated_count += 1
            update_str = ", ".join(updates) if updates else "no changes"
            print(f"  ✓ Updated {ship_id}: {update_str}")

        # Reconstruct line
        updated_lines.append(','.join(parts) + '\n')

    # Write updated CSV
    with open(CSV_PATH, 'w') as f:
        f.writelines(updated_lines)

    print(f"\n✓ Updated {updated_count} ships in {CSV_PATH.name}")

def main():
    print("=" * 60)
    print("Ship Coordinate Merger")
    print("=" * 60)
    print()

    # Load JSONs
    ship_data = load_json_files()

    if not ship_data:
        print("\nNo ship data to merge.")
        return

    print(f"\nMerging data for {len(ship_data)} ship(s)...")

    # Update CSV
    update_csv(ship_data)

    print("\nDone!")

if __name__ == '__main__':
    main()
