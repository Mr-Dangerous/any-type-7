#!/usr/bin/env python3
"""
Clear all coordinate_points in ship_visuals_database.csv and add empty scale_factor column
"""
import sys
from pathlib import Path

CSV_PATH = Path(__file__).parent.parent / "data" / "ship_visuals_database.csv"

def clear_coordinates():
    with open(CSV_PATH, 'r') as f:
        lines = f.readlines()

    updated_lines = []
    cleared_count = 0

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
        parts.append(current.rstrip('\n'))

        # If this is the header, just keep it (already updated)
        if 'ship_ID' in parts[0]:
            updated_lines.append(line)
            continue

        # For data rows: insert empty scale_factor at column 5 if not present
        # Expected: ship_ID,sprite_path,sprite_exists,sprite_width,sprite_height,scale_factor,...
        # If row has 13 columns (old format), need to insert scale_factor at index 5
        if len(parts) == 13:
            parts.insert(5, '')  # Insert empty scale_factor after sprite_height
            print(f"Added scale_factor column to: {parts[0]}")

        # Ensure we have the right number of columns (14 total)
        while len(parts) < 14:
            parts.append('')

        # Clear coordinate_points (now column 13, was 12)
        if parts[13].strip() and parts[13] != '[]':
            parts[13] = '[]'
            cleared_count += 1
            print(f"Cleared coordinates: {parts[0]}")

        updated_lines.append(','.join(parts) + '\n')

    with open(CSV_PATH, 'w') as f:
        f.writelines(updated_lines)

    print(f"\n✓ Cleared {cleared_count} ships' coordinates")
    print(f"✓ CSV updated with scale_factor column")

if __name__ == '__main__':
    clear_coordinates()
