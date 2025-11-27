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
var upgrades: Dictionary = {}           # upgrade_ID → upgrade data
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
	_load_database("res://data/ship_upgrade_database.csv", upgrades, "upgrade_id")
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

	# Read data rows
	var record_count := 0
	while not file.eof_reached():
		var row := file.get_csv_line()

		# Skip empty rows
		if row.is_empty() or (row.size() == 1 and row[0].strip_edges().is_empty()):
			continue

		# Build record dictionary
		var record := {}
		for i in range(min(row.size(), headers.size())):
			var key := headers[i].strip_edges()
			var value := row[i].strip_edges()
			record[key] = _convert_type(value)

		# Cache by ID
		var record_id: String = record.get(id_column, "")
		if not record_id.is_empty():
			target_dict[record_id] = record
			record_count += 1

	file.close()
	EventBus.data_load_completed.emit(csv_path.get_file(), record_count)
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
	return upgrades.get(upgrade_id, {})

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
	print("Upgrades: %d" % upgrades.size())
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
