extends Node

# ============================================================
# DATA MANAGER - CSV LOADING & CACHING SYSTEM
# ============================================================
# Purpose: Load, parse, cache, and query all CSV databases
# All game content is data-driven from /data/*.csv files
# ============================================================

# ============================================================
# CACHED DATA DICTIONARIES
# ============================================================

var ships: Dictionary = {}              # ship_ID → ship data
var abilities: Dictionary = {}          # ability_ID → ability data
var relics_t1: Dictionary = {}          # item_id → tier 1 relic data
var relics_t2: Dictionary = {}          # item_id → tier 2 relic data
var status_effects: Dictionary = {}     # effect_ID → effect data
var combos: Dictionary = {}             # combo_ID → combo data
var weapons: Dictionary = {}            # weapon_ID → weapon data
var drones: Dictionary = {}             # drone_ID → drone data
var powerups: Dictionary = {}           # powerup_ID → powerup data
var blueprints: Dictionary = {}         # blueprint_ID → blueprint data
var ship_visuals: Dictionary = {}       # visual_ID → visual data
var drone_visuals: Dictionary = {}      # drone_visual_ID → visual data

# Combat scenarios (currently empty CSV)
var combat_scenarios: Dictionary = {}  # scenario_ID → scenario data

# Personnel (currently empty CSV)
var personnel: Dictionary = {}          # personnel_ID → personnel data

# Sector exploration data
var sector_nodes: Dictionary = {}       # node_type → node config
var environment_bands: Dictionary = {}  # band_id → band config
var environment_node_weights: Dictionary = {}  # band_id|node_type → weight modifier
var sector_progression: Dictionary = {}  # sector_number → progression data

# Hangar/Fleet data
var starting_fleets: Dictionary = {}    # scenario_name → starting fleet data
var combination_recipes: Dictionary = {}  # "item1|item2" → result_item_id

# ============================================================
# LOAD STATUS
# ============================================================

var is_loaded: bool = false
var load_errors: Array[String] = []

# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
	print("[DataManager] Starting CSV data load...")
	load_all_databases()

func load_all_databases() -> void:
	# Load order: static data first, dynamic data later

	_load_database("res://data/ship_stat_database.csv", ships, "ship_ID")
	_load_database("res://data/ability_database.csv", abilities, "ability_id")
	_load_database("res://data/item_relics_t1.csv", relics_t1, "item_id")
	_load_database("res://data/item_relics_t2.csv", relics_t2, "item_id")
	_load_database("res://data/status_effects.csv", status_effects, "effect_id")
	_load_database("res://data/elemental_combos.csv", combos, "element")
	_load_database("res://data/weapon_database.csv", weapons, "ship_system_id")
	_load_database("res://data/drone_database.csv", drones, "drone_ID")
	_load_database("res://data/powerups_database.csv", powerups, "powerup_ID")
	_load_database("res://data/blueprints_database.csv", blueprints, "blueprint_id")
	_load_database("res://data/ship_visuals_database.csv", ship_visuals, "ship_ID")
	_load_database("res://data/drone_visuals_database.csv", drone_visuals, "drone_ID")

	# Empty CSVs (will have headers but no data rows)
	_load_database("res://data/combat_scenarios.csv", combat_scenarios, "scenario_id")
	_load_database("res://data/personnel_database.csv", personnel, "personnel_id")

	# Sector exploration data
	_load_database("res://data/sector_nodes.csv", sector_nodes, "node_type")
	_load_database("res://data/environment_bands.csv", environment_bands, "band_id")
	_load_database("res://data/sector_progression.csv", sector_progression, "sector_number")

	# Load environment_node_weights with composite key (band_id|node_type)
	_load_environment_node_weights()

	# Hangar/Fleet data
	_load_database("res://data/starting_fleets.csv", starting_fleets, "scenario_name")
	_load_combination_recipes()

	is_loaded = true
	EventBus.all_data_loaded.emit()
	print("[DataManager] All databases loaded successfully")
	_print_load_summary()

# ============================================================
# CSV PARSING
# ============================================================

func _load_database(csv_path: String, target_dict: Dictionary, id_column: String) -> void:
	EventBus.data_load_started.emit(csv_path.get_file())

	if not FileAccess.file_exists(csv_path):
		var error := "File not found: " + csv_path
		load_errors.append(error)
		EventBus.data_load_failed.emit(csv_path.get_file(), error)
		push_error(error)
		return

	var file := FileAccess.open(csv_path, FileAccess.READ)
	if file == null:
		var error := "Failed to open: " + csv_path
		load_errors.append(error)
		EventBus.data_load_failed.emit(csv_path.get_file(), error)
		push_error(error)
		return

	# Read header row
	var header_line := file.get_csv_line()
	if header_line.is_empty():
		file.close()
		var error := "Empty CSV file: " + csv_path
		load_errors.append(error)
		EventBus.data_load_failed.emit(csv_path.get_file(), error)
		push_error(error)
		return

	var headers := header_line
	var id_column_index := headers.find(id_column)

	if id_column_index == -1:
		file.close()
		var error := "ID column '%s' not found in %s" % [id_column, csv_path]
		load_errors.append(error)
		EventBus.data_load_failed.emit(csv_path.get_file(), error)
		push_error(error)
		return

	# Check if CSV has 'enabled' column
	var enabled_column_index := headers.find("enabled")
	var has_enabled_filter := (enabled_column_index != -1)

	# Read data rows
	var record_count := 0
	var filtered_count := 0
	while not file.eof_reached():
		var row := file.get_csv_line()

		# Skip empty rows
		if row.is_empty() or (row.size() == 1 and row[0].strip_edges().is_empty()):
			continue

		# Build record dictionary
		var record := {}
		for i in range(min(row.size(), headers.size())):
			var key: String = headers[i].strip_edges()
			var value: String = row[i].strip_edges()
			record[key] = _convert_type(value)

		# Filter by 'enabled' column if present
		if has_enabled_filter:
			var enabled_value = record.get("enabled", "yes")
			# Convert to string for consistent comparison
			var enabled_str := str(enabled_value).to_lower()
			# Skip if not enabled (accept "yes" or "true")
			if enabled_str != "yes" and enabled_str != "true":
				filtered_count += 1
				continue

		# Cache by ID (convert to string to handle both string and int IDs)
		var record_id_raw = record.get(id_column, "")
		var record_id: String = str(record_id_raw)
		if not record_id.is_empty():
			target_dict[record_id] = record
			record_count += 1

	file.close()
	EventBus.data_load_completed.emit(csv_path.get_file(), record_count)

	# Print load summary
	if has_enabled_filter and filtered_count > 0:
		print("[DataManager] Loaded %d records from %s (filtered %d disabled)" % [record_count, csv_path.get_file(), filtered_count])
	else:
		print("[DataManager] Loaded %d records from %s" % [record_count, csv_path.get_file()])

# ============================================================
# TYPE CONVERSION
# ============================================================

func _convert_type(value: String) -> Variant:
	# Empty string
	if value.is_empty():
		return ""

	# Boolean
	if value.to_lower() == "true":
		return true
	if value.to_lower() == "false":
		return false

	# Integer (no decimal point)
	if value.is_valid_int():
		return value.to_int()

	# Float (has decimal point)
	if value.is_valid_float():
		return value.to_float()

	# Default: String
	return value

# ============================================================
# QUERY FUNCTIONS
# ============================================================

func get_ship(ship_id: String) -> Dictionary:
	return ships.get(ship_id, {})

func get_ability(ability_id: String) -> Dictionary:
	return abilities.get(ability_id, {})

func get_upgrade(upgrade_id: String) -> Dictionary:
	# Legacy function - now checks both tier 1 and tier 2 relics
	if relics_t1.has(upgrade_id):
		return relics_t1.get(upgrade_id)
	elif relics_t2.has(upgrade_id):
		return relics_t2.get(upgrade_id)
	return {}

func get_status_effect(effect_id: String) -> Dictionary:
	return status_effects.get(effect_id, {})

func get_combo(combo_id: String) -> Dictionary:
	return combos.get(combo_id, {})

func get_weapon(weapon_id: String) -> Dictionary:
	return weapons.get(weapon_id, {})

func get_drone(drone_id: String) -> Dictionary:
	return drones.get(drone_id, {})

func get_powerup(powerup_id: String) -> Dictionary:
	return powerups.get(powerup_id, {})

func get_blueprint(blueprint_id: String) -> Dictionary:
	return blueprints.get(blueprint_id, {})

func get_ship_visual(visual_id: String) -> Dictionary:
	return ship_visuals.get(visual_id, {})

func get_drone_visual(drone_visual_id: String) -> Dictionary:
	return drone_visuals.get(drone_visual_id, {})

func get_sector_node(node_type: String) -> Dictionary:
	return sector_nodes.get(node_type, {})

# ============================================================
# BULK QUERIES
# ============================================================

func get_ships_by_class(size_class: String) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for ship: Dictionary in ships.values():
		if ship.get("ship_size_class", "") == size_class:
			results.append(ship)
	return results

func get_ships_by_tier(tier: String) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for ship: Dictionary in ships.values():
		if ship.get("tier", "") == tier:
			results.append(ship)
	return results

func get_abilities_by_type(ability_type: String) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for ability: Dictionary in abilities.values():
		if ability.get("type", "") == ability_type:
			results.append(ability)
	return results

func get_all_ship_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(ships.keys())
	return ids

func get_spawnable_nodes() -> Array[Dictionary]:
	"""Get all sector nodes that can spawn in default space (not band-exclusive)"""
	var results: Array[Dictionary] = []
	for node_data: Dictionary in sector_nodes.values():
		# Skip band-exclusive nodes
		if node_data.get("band_exclusive", "no") == "yes":
			continue
		# Skip nodes with 0 spawn weight (like wormhole)
		if int(node_data.get("spawn_weight", 0)) <= 0:
			continue
		results.append(node_data)
	return results

# ============================================================
# SPECIAL CSV LOADERS
# ============================================================

func _load_environment_node_weights() -> void:
	"""Load environment_node_weights.csv with composite key (band_id|node_type)"""
	var csv_path := "res://data/environment_node_weights.csv"

	if not FileAccess.file_exists(csv_path):
		print("[DataManager] WARNING: %s not found" % csv_path)
		return

	var file := FileAccess.open(csv_path, FileAccess.READ)
	if not file:
		print("[DataManager] ERROR: Could not open %s" % csv_path)
		return

	# Read header
	var header_line := file.get_csv_line()

	# Read data rows
	var row_count := 0
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 4 or row[0].is_empty():
			continue

		var band_id: String = row[0].strip_edges()
		var node_type: String = row[1].strip_edges()
		var weight_multiplier: float = float(row[2])
		var spawn_weight_override: int = int(row[3])

		# Composite key: band_id|node_type
		var key: String = band_id + "|" + node_type
		environment_node_weights[key] = {
			"band_id": band_id,
			"node_type": node_type,
			"weight_multiplier": weight_multiplier,
			"spawn_weight_override": spawn_weight_override
		}
		row_count += 1

	file.close()
	print("[DataManager] Loaded %d environment node weights" % row_count)

func _load_combination_recipes() -> void:
	"""Load combination_recipes.csv with composite key (component_1|component_2)"""
	var csv_path := "res://data/combination_recipes.csv"

	if not FileAccess.file_exists(csv_path):
		print("[DataManager] WARNING: %s not found" % csv_path)
		return

	var file := FileAccess.open(csv_path, FileAccess.READ)
	if not file:
		print("[DataManager] ERROR: Could not open %s" % csv_path)
		return

	# Read header
	var header_line := file.get_csv_line()

	# Read data rows
	var row_count := 0
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 3 or row[0].is_empty():
			continue

		var component_1: String = row[0].strip_edges()
		var component_2: String = row[1].strip_edges()
		var result_item: String = row[2].strip_edges()

		# Create both orderings (chronometer|amplifier and amplifier|chronometer)
		var sorted_components := [component_1, component_2]
		sorted_components.sort()
		var key: String = sorted_components[0] + "|" + sorted_components[1]

		combination_recipes[key] = result_item
		row_count += 1

	file.close()
	print("[DataManager] Loaded %d combination recipes" % row_count)

# ============================================================
# SECTOR EXPLORATION QUERY FUNCTIONS
# ============================================================

func get_node_config(node_type: String) -> Dictionary:
	"""Get node configuration by type

	Args:
		node_type: The node type identifier

	Returns:
		Node config dictionary (empty if not found)
	"""
	return sector_nodes.get(node_type, {})

func get_band_config(band_id: String) -> Dictionary:
	"""Get environmental band configuration

	Args:
		band_id: The band identifier

	Returns:
		Band config dictionary (empty if not found)
	"""
	return environment_bands.get(band_id, {})

func get_band_node_weight_modifier(band_id: String, node_type: String) -> float:
	"""Get spawn weight modifier for node type in specific band

	Args:
		band_id: The environmental band
		node_type: The node type

	Returns:
		Weight multiplier (1.0 = no change)
	"""
	# Check specific node type first
	var key: String = band_id + "|" + node_type
	if environment_node_weights.has(key):
		var data: Dictionary = environment_node_weights[key]
		var override: int = data.get("spawn_weight_override", -1)
		if override >= 0:
			# Override takes precedence, but we need to return multiplier
			# So we calculate it: override / base_weight
			var base_weight: int = get_node_config(node_type).get("spawn_weight", 1)
			if base_weight > 0:
				return float(override) / float(base_weight)
		return data.get("weight_multiplier", 1.0)

	# Check "all" wildcard
	var all_key: String = band_id + "|all"
	if environment_node_weights.has(all_key):
		return environment_node_weights[all_key].get("weight_multiplier", 1.0)

	return 1.0  # No modifier

func get_available_bands(sector_number: int) -> Array:
	"""Get all bands available for current sector

	Args:
		sector_number: Current sector

	Returns:
		Array of band dictionaries that are unlocked
	"""
	var bands := []
	for band_id in environment_bands:
		var band: Dictionary = environment_bands[band_id]
		var min_sector: int = band.get("min_sector", 1)
		if min_sector <= sector_number:
			bands.append(band)
	return bands

func get_nodes_for_band(band_id: String) -> Array[Dictionary]:
	"""Get all nodes available for a specific band (universal + exclusive)

	Args:
		band_id: The environmental band identifier

	Returns:
		Array of node config dictionaries available in this band
	"""
	var available_nodes: Array[Dictionary] = []

	for node_type in sector_nodes.keys():
		var node: Dictionary = sector_nodes[node_type]
		var is_exclusive: bool = node.get("band_exclusive", "no") == "yes"

		if is_exclusive:
			# Only include if this is the exclusive band
			if node.get("exclusive_band_id", "") == band_id:
				available_nodes.append(node)
		else:
			# Non-exclusive nodes available in all bands (unless weight is 0)
			var weight_modifier := get_band_node_weight_modifier(band_id, node_type)
			if weight_modifier > 0.0:
				available_nodes.append(node)

	return available_nodes

func get_sector_progression(sector_number: int) -> Dictionary:
	"""Get sector progression data

	Args:
		sector_number: The sector number

	Returns:
		Progression config dictionary (empty if not found)
	"""
	return sector_progression.get(str(sector_number), {})

# ============================================================
# RELIC SYSTEM QUERY FUNCTIONS
# ============================================================

func get_relic_t1(item_id: String) -> Dictionary:
	"""Get Tier 1 relic data

	Args:
		item_id: The relic identifier

	Returns:
		Tier 1 relic config (empty if not found)
	"""
	return relics_t1.get(item_id, {})

func get_relic_t2(item_id: String) -> Dictionary:
	"""Get Tier 2 relic data

	Args:
		item_id: The relic identifier

	Returns:
		Tier 2 relic config (empty if not found)
	"""
	return relics_t2.get(item_id, {})

func get_starting_fleet(scenario_name: String) -> Dictionary:
	"""Get starting fleet configuration

	Args:
		scenario_name: The scenario identifier

	Returns:
		Starting fleet config (empty if not found)
	"""
	return starting_fleets.get(scenario_name, {})

func get_combination_result(item_a: String, item_b: String) -> String:
	"""Get Tier 2 item result from combining two Tier 1 items

	Args:
		item_a: First item ID
		item_b: Second item ID

	Returns:
		Resulting Tier 2 item ID (empty string if no recipe exists)
	"""
	var sorted_items := [item_a, item_b]
	sorted_items.sort()
	var key: String = sorted_items[0] + "|" + sorted_items[1]
	return combination_recipes.get(key, "")

# ============================================================
# VALIDATION
# ============================================================

func validate_ship_references() -> Array[String]:
	var errors: Array[String] = []

	for ship_id in ships.keys():
		var ship: Dictionary = ships[ship_id]
		var ability_id: String = ship.get("ship_ability", "")

		if not ability_id.is_empty() and not abilities.has(ability_id):
			errors.append("Ship '%s' references unknown ability '%s'" % [ship_id, ability_id])

	return errors

# ============================================================
# DEBUG & VALIDATION
# ============================================================

func _print_load_summary() -> void:
	print("=".repeat(60))
	print("DATA LOAD SUMMARY")
	print("=".repeat(60))
	print("Ships: %d" % ships.size())
	print("Abilities: %d" % abilities.size())
	print("Relics (Tier 1): %d" % relics_t1.size())
	print("Relics (Tier 2): %d" % relics_t2.size())
	print("Status Effects: %d" % status_effects.size())
	print("Combos: %d" % combos.size())
	print("Weapons: %d" % weapons.size())
	print("Drones: %d" % drones.size())
	print("Powerups: %d" % powerups.size())
	print("Blueprints: %d" % blueprints.size())
	print("Ship Visuals: %d" % ship_visuals.size())
	print("Drone Visuals: %d" % drone_visuals.size())
	print("Combat Scenarios: %d" % combat_scenarios.size())
	print("Personnel: %d" % personnel.size())
	print("---")
	print("Sector Nodes: %d (base + band-exclusive)" % sector_nodes.size())
	print("Environment Bands: %d" % environment_bands.size())
	print("Environment Node Weights: %d" % environment_node_weights.size())
	print("Sector Progression: %d" % sector_progression.size())
	print("---")
	print("Starting Fleets: %d" % starting_fleets.size())
	print("Combination Recipes: %d" % combination_recipes.size())
	print("=".repeat(60))

	if not load_errors.is_empty():
		print("ERRORS:")
		for error in load_errors:
			print("  - " + error)
		print("=".repeat(60))

func print_ship_data(ship_id: String) -> void:
	var ship := get_ship(ship_id)
	if ship.is_empty():
		print("Ship '%s' not found" % ship_id)
		return

	print("=".repeat(60))
	print("SHIP DATA: %s" % ship_id)
	print("=".repeat(60))
	for key in ship.keys():
		print("  %s: %s" % [key, str(ship[key])])
	print("=".repeat(60))
