extends Node

# ============================================================
# GAME STATE - STATE MANAGEMENT
# ============================================================
# Purpose: Track persistent game state and progression
# Manages sector progression, fleet ownership, and game flow
# ============================================================

# ============================================================
# GAME STATE
# ============================================================

var current_sector: int = 1
var current_screen: String = "main_menu"
var is_paused: bool = false
var game_started: bool = false
var sector_active: bool = false  # True when in sector exploration mode

# ============================================================
# FLEET STATE
# ============================================================

var owned_ships: Array[String] = []        # Ship instance IDs (e.g., "basic_fighter_001")
var active_loadout: Array[String] = []     # Ships deployed in current combat
var unlocked_blueprints: Array[String] = []

# Ship Instance System
var ship_instances: Dictionary = {}        # instance_id → ship instance data
var ship_instance_counter: Dictionary = {} # blueprint_id → count (for generating unique IDs)

# Ship instance data structure:
# {
#   "blueprint_id": "basic_fighter",
#   "current_hp": 125,
#   "max_hp": 125,
#   "equipped_upgrades": ["chronometer", "autocannon_protocol"],
#   "equipped_weapons": ["missile_launcher"],
#   "deployment_position": {"lane": 7, "file": 2} or null
# }

# ============================================================
# PROGRESSION
# ============================================================

var sectors_completed: int = 0
var total_combats_won: int = 0
var total_combats_lost: int = 0
var total_enemies_destroyed: int = 0
var total_nodes_visited: int = 0

# ============================================================
# RUN STATISTICS
# ============================================================

var run_start_time: int = 0  # Unix timestamp
var nodes_visited_this_sector: int = 0
var combats_this_sector: int = 0
var elapsed_time: float = 0.0  # Time elapsed in current run (seconds)
var enemy_triggers: int = 0  # Number of times hit by enemy sweeps

# Upgrade Inventories
var tier_1_inventory: Dictionary = {}  # item_id → count (e.g., {"chronometer": 2, "amplifier": 1})
var tier_2_inventory: Dictionary = {}  # item_id → count (e.g., {"autocannon_protocol": 1})
var weapon_inventory: Dictionary = {}  # weapon_id → count (e.g., {"missile_launcher": 1})

# ============================================================
# RESOURCE STREAK SYSTEM
# ============================================================

var current_streak_resource: String = ""  # metal, crystals, fuel, item (empty = no streak)
var current_streak_count: int = 0  # Number of consecutive collections (max 10 for 100% bonus)
var streak_time_remaining: float = 0.0  # Time until streak expires (10 seconds)

# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
	print("[GameState] Initialized")
	_initialize_starter_fleet()

func _process(delta: float) -> void:
	# Update elapsed time (only when not paused and game is started)
	if game_started and not is_paused:
		elapsed_time += delta

		# Update streak timer
		if streak_time_remaining > 0.0:
			streak_time_remaining -= delta
			if streak_time_remaining <= 0.0:
				_break_streak()
				EventBus.resource_streak_broken.emit()

func _initialize_starter_fleet() -> void:
	# Load starting fleet from CSV (default: "test_fleet" scenario)
	load_starting_fleet("test_fleet")

# ============================================================
# GAME FLOW
# ============================================================

func start_new_game() -> void:
	game_started = true
	current_sector = 1
	sectors_completed = 0
	total_combats_won = 0
	total_combats_lost = 0
	total_enemies_destroyed = 0
	total_nodes_visited = 0
	enemy_triggers = 0
	elapsed_time = 0.0
	run_start_time = Time.get_unix_time_from_system()

	# Clear inventories (will be repopulated by starting fleet)
	tier_1_inventory.clear()
	tier_2_inventory.clear()
	weapon_inventory.clear()

	# Clear fleet data (will be repopulated by starting fleet)
	owned_ships.clear()
	ship_instances.clear()
	ship_instance_counter.clear()

	_initialize_starter_fleet()
	EventBus.game_started.emit()
	print("[GameState] New game started")

func end_game(victory: bool) -> void:
	game_started = false
	var run_duration := Time.get_unix_time_from_system() - run_start_time

	print("[GameState] Game ended - Victory: %s, Duration: %d seconds" % [victory, run_duration])
	print("[GameState] Final stats - Sectors: %d, Combats Won: %d, Enemies: %d" %
		[sectors_completed, total_combats_won, total_enemies_destroyed])

# ============================================================
# SECTOR MANAGEMENT
# ============================================================

func enter_sector(sector_number: int) -> void:
	current_sector = sector_number
	nodes_visited_this_sector = 0
	combats_this_sector = 0
	EventBus.sector_entered.emit(sector_number)
	print("[GameState] Entered sector %d" % sector_number)

func complete_sector() -> void:
	sectors_completed += 1
	EventBus.sector_exited.emit()
	print("[GameState] Sector %d completed (Total: %d)" % [current_sector, sectors_completed])

func advance_to_next_sector() -> void:
	complete_sector()
	enter_sector(current_sector + 1)

# ============================================================
# FLEET MANAGEMENT
# ============================================================

func add_ship(ship_id: String) -> void:
	if not owned_ships.has(ship_id):
		owned_ships.append(ship_id)
		print("[GameState] Added ship to fleet: %s" % ship_id)
	else:
		print("[GameState] Ship already owned: %s" % ship_id)

func remove_ship(ship_id: String) -> void:
	if owned_ships.has(ship_id):
		owned_ships.erase(ship_id)
		# Remove from active loadout if present
		active_loadout.erase(ship_id)
		print("[GameState] Removed ship from fleet: %s" % ship_id)

func has_ship(ship_id: String) -> bool:
	return owned_ships.has(ship_id)

func get_fleet_size() -> int:
	return owned_ships.size()

# ============================================================
# LOADOUT MANAGEMENT
# ============================================================

func set_active_loadout(ship_ids: Array[String]) -> void:
	active_loadout = ship_ids.duplicate()
	EventBus.loadout_changed.emit(ship_ids)
	print("[GameState] Active loadout set: %s" % str(ship_ids))

func add_to_loadout(ship_id: String) -> bool:
	if not has_ship(ship_id):
		print("[GameState] Cannot add to loadout - ship not owned: %s" % ship_id)
		return false

	if active_loadout.has(ship_id):
		print("[GameState] Ship already in loadout: %s" % ship_id)
		return false

	active_loadout.append(ship_id)
	EventBus.loadout_changed.emit(active_loadout)
	print("[GameState] Added to loadout: %s" % ship_id)
	return true

func remove_from_loadout(ship_id: String) -> void:
	if active_loadout.has(ship_id):
		active_loadout.erase(ship_id)
		EventBus.loadout_changed.emit(active_loadout)
		print("[GameState] Removed from loadout: %s" % ship_id)

func clear_loadout() -> void:
	active_loadout.clear()
	EventBus.loadout_changed.emit(active_loadout)
	print("[GameState] Loadout cleared")

# ============================================================
# SHIP INSTANCE MANAGEMENT
# ============================================================

func load_starting_fleet(scenario_name: String) -> void:
	"""Load starting fleet from CSV configuration"""
	var fleet_data := DataManager.get_starting_fleet(scenario_name)

	if fleet_data.is_empty():
		push_error("[GameState] Starting fleet scenario '%s' not found!" % scenario_name)
		return

	# Clear existing fleet
	owned_ships.clear()
	ship_instances.clear()
	ship_instance_counter.clear()
	tier_1_inventory.clear()
	tier_2_inventory.clear()
	weapon_inventory.clear()

	# Parse ships (create unique instances)
	var ships_str: String = fleet_data.get("starting_ships", "")
	if not ships_str.is_empty():
		var ship_ids := ships_str.split("|")
		for ship_id in ship_ids:
			ship_id = ship_id.strip_edges()
			if not ship_id.is_empty():
				_create_ship_instance(ship_id)

	# Parse Tier 1 inventory
	var t1_str: String = fleet_data.get("tier1_inventory", "")
	if not t1_str.is_empty():
		for item_pair in t1_str.split("|"):
			var parts := item_pair.split(":")
			if parts.size() == 2:
				var item_id: String = parts[0].strip_edges()
				var quantity: int = parts[1].strip_edges().to_int()
				tier_1_inventory[item_id] = quantity

	# Parse Tier 2 inventory
	var t2_str: String = fleet_data.get("tier2_inventory", "")
	if not t2_str.is_empty():
		for item_pair in t2_str.split("|"):
			var parts := item_pair.split(":")
			if parts.size() == 2:
				var item_id: String = parts[0].strip_edges()
				var quantity: int = parts[1].strip_edges().to_int()
				tier_2_inventory[item_id] = quantity

	# Parse weapon inventory
	var weapon_str: String = fleet_data.get("weapon_inventory", "")
	if not weapon_str.is_empty():
		for item_pair in weapon_str.split("|"):
			var parts := item_pair.split(":")
			if parts.size() == 2:
				var weapon_id: String = parts[0].strip_edges()
				var quantity: int = parts[1].strip_edges().to_int()
				weapon_inventory[weapon_id] = quantity

	# Set starting resources
	var metal: int = int(fleet_data.get("starting_metal", 500))
	var crystals: int = int(fleet_data.get("starting_crystals", 200))
	var fuel: int = int(fleet_data.get("starting_fuel", 150))

	ResourceManager.set_resource("metal", metal)
	ResourceManager.set_resource("crystals", crystals)
	ResourceManager.set_resource("fuel", fuel)

	print("[GameState] Starting fleet '%s' loaded: %d ships, %d T1 items, %d T2 items, %d weapons" %
		[scenario_name, owned_ships.size(), _count_inventory(tier_1_inventory),
		_count_inventory(tier_2_inventory), _count_inventory(weapon_inventory)])

func _create_ship_instance(blueprint_id: String) -> String:
	"""Create a new ship instance from blueprint and add to fleet"""
	var instance_id := _generate_unique_ship_id(blueprint_id)

	# Get base stats from blueprint
	var ship_data := DataManager.get_ship(blueprint_id)
	if ship_data.is_empty():
		push_error("[GameState] Ship blueprint '%s' not found!" % blueprint_id)
		return ""

	# Calculate max HP (hull + shields)
	var max_hp := int(ship_data.get("hull_points", 0)) + int(ship_data.get("shield_points", 0))

	# Create instance
	ship_instances[instance_id] = {
		"blueprint_id": blueprint_id,
		"current_hp": max_hp,
		"max_hp": max_hp,
		"equipped_upgrades": [],
		"equipped_weapons": [],
		"deployment_position": null
	}

	owned_ships.append(instance_id)
	print("[GameState] Created ship instance: %s (from %s)" % [instance_id, blueprint_id])

	return instance_id

func _generate_unique_ship_id(blueprint_id: String) -> String:
	"""Generate unique instance ID for a ship blueprint"""
	if not ship_instance_counter.has(blueprint_id):
		ship_instance_counter[blueprint_id] = 0

	ship_instance_counter[blueprint_id] += 1
	var instance_num: int = ship_instance_counter[blueprint_id]

	return "%s_%03d" % [blueprint_id, instance_num]

func get_ship_instance(instance_id: String) -> Dictionary:
	"""Get ship instance data"""
	return ship_instances.get(instance_id, {})

func get_ship_blueprint_data(instance_id: String) -> Dictionary:
	"""Get blueprint data for a ship instance"""
	var instance := get_ship_instance(instance_id)
	if instance.is_empty():
		return {}

	var blueprint_id: String = instance.get("blueprint_id", "")
	return DataManager.get_ship(blueprint_id)

func get_ship_calculated_stats(instance_id: String) -> Dictionary:
	"""Get ship stats with all equipped item bonuses applied"""
	# Get base stats from blueprint
	var base_stats := get_ship_blueprint_data(instance_id)
	if base_stats.is_empty():
		return {}

	# Create calculated stats dict (start with base stats)
	var stats := base_stats.duplicate(true)

	# Get equipped upgrades
	var instance := get_ship_instance(instance_id)
	var equipped_upgrades: Array = instance.get("equipped_upgrades", [])

	# Accumulators for bonuses
	var flat_bonuses := {
		"hull_points": 0,
		"shield_points": 0,
		"armor": 0,
		"attack_damage": 0,
		"energy_points": 0,  # Maps from starting_energy
	}

	var percent_bonuses := {
		"attack_speed": 0.0,
		"amplitude": 0.0,
		"resilience": 0.0,
		"movement_speed": 0.0,
		"precision": 0.0,
	}

	var regen_stats := {
		"hull_regen_per_sec": 0.0,
		"energy_regen_per_sec": 0.0,
	}

	# Sum up bonuses from all equipped items
	for item_id in equipped_upgrades:
		if item_id.is_empty():
			continue

		var item_data := DataManager.get_relic_t1(item_id)
		if item_data.is_empty():
			continue

		# Flat bonuses
		flat_bonuses["hull_points"] += int(item_data.get("hull_points", 0))
		flat_bonuses["shield_points"] += int(item_data.get("shield_points", 0))
		flat_bonuses["armor"] += int(item_data.get("armor", 0))
		flat_bonuses["attack_damage"] += int(item_data.get("attack_damage", 0))
		flat_bonuses["energy_points"] += int(item_data.get("starting_energy", 0))  # Map starting_energy

		# Percentage bonuses (sum percentages)
		percent_bonuses["attack_speed"] += float(item_data.get("attack_speed_percent", 0))
		percent_bonuses["amplitude"] += float(item_data.get("amplitude_percent", 0))
		percent_bonuses["resilience"] += float(item_data.get("resilience_percent", 0))
		percent_bonuses["movement_speed"] += float(item_data.get("movement_speed_percent", 0))
		percent_bonuses["precision"] += float(item_data.get("precision_percent", 0))

		# Regen stats
		regen_stats["hull_regen_per_sec"] += float(item_data.get("hull_regen_per_sec", 0))
		regen_stats["energy_regen_per_sec"] += float(item_data.get("energy_regen_per_sec", 0))

	# Apply flat bonuses
	stats["hull_points"] = int(stats.get("hull_points", 0)) + flat_bonuses["hull_points"]
	stats["shield_points"] = int(stats.get("shield_points", 0)) + flat_bonuses["shield_points"]
	stats["armor"] = int(stats.get("armor", 0)) + flat_bonuses["armor"]
	stats["attack_damage"] = int(stats.get("attack_damage", 0)) + flat_bonuses["attack_damage"]
	stats["energy_points"] = int(stats.get("energy_points", 0)) + flat_bonuses["energy_points"]

	# Apply percentage bonuses (multiply base by (1 + percent/100))
	for stat_name in percent_bonuses.keys():
		var base_value: float = float(stats.get(stat_name, 0))
		var percent: float = percent_bonuses[stat_name]
		if percent > 0:
			stats[stat_name] = base_value * (1.0 + percent / 100.0)

	# Add regen stats (new stats not in base)
	stats["hull_regen_per_sec"] = regen_stats["hull_regen_per_sec"]
	stats["energy_regen_per_sec"] = regen_stats["energy_regen_per_sec"]

	# Store bonus totals for display
	stats["_flat_bonuses"] = flat_bonuses
	stats["_percent_bonuses"] = percent_bonuses
	stats["_regen_stats"] = regen_stats

	return stats

func equip_upgrade_to_ship(ship_instance_id: String, slot_index: int, item_id: String) -> bool:
	"""Equip a Tier 1 upgrade to a ship"""
	# Get ship instance
	var instance := get_ship_instance(ship_instance_id)
	if instance.is_empty():
		push_error("[GameState] Ship instance not found: %s" % ship_instance_id)
		return false

	# Check if player has the item
	if tier_1_inventory.get(item_id, 0) <= 0:
		push_error("[GameState] Player doesn't have item: %s" % item_id)
		return false

	# Get or create equipped_upgrades array
	var equipped_upgrades: Array = instance.get("equipped_upgrades", [])

	# Ensure array is large enough
	while equipped_upgrades.size() <= slot_index:
		equipped_upgrades.append("")

	# Check if slot is already occupied
	if not equipped_upgrades[slot_index].is_empty():
		push_error("[GameState] Slot %d already occupied on ship %s" % [slot_index, ship_instance_id])
		return false

	# Equip the item
	equipped_upgrades[slot_index] = item_id
	instance["equipped_upgrades"] = equipped_upgrades

	# Reduce inventory count
	tier_1_inventory[item_id] -= 1
	if tier_1_inventory[item_id] <= 0:
		tier_1_inventory.erase(item_id)

	print("[GameState] Equipped %s to ship %s slot %d" % [item_id, ship_instance_id, slot_index])
	return true

func unequip_upgrade_from_ship(ship_instance_id: String, slot_index: int) -> bool:
	"""Unequip a Tier 1 upgrade from a ship"""
	# Get ship instance
	var instance := get_ship_instance(ship_instance_id)
	if instance.is_empty():
		push_error("[GameState] Ship instance not found: %s" % ship_instance_id)
		return false

	# Get equipped_upgrades array
	var equipped_upgrades: Array = instance.get("equipped_upgrades", [])

	# Check if slot exists and has an item
	if slot_index >= equipped_upgrades.size() or equipped_upgrades[slot_index].is_empty():
		push_error("[GameState] No item in slot %d on ship %s" % [slot_index, ship_instance_id])
		return false

	# Get the item ID
	var item_id: String = equipped_upgrades[slot_index]

	# Unequip the item
	equipped_upgrades[slot_index] = ""
	instance["equipped_upgrades"] = equipped_upgrades

	# Return to inventory
	tier_1_inventory[item_id] = tier_1_inventory.get(item_id, 0) + 1

	print("[GameState] Unequipped %s from ship %s slot %d" % [item_id, ship_instance_id, slot_index])
	return true

func equip_weapon_to_ship(ship_instance_id: String, slot_index: int, weapon_id: String) -> bool:
	"""Equip a weapon to a ship"""
	# Get ship instance
	var instance := get_ship_instance(ship_instance_id)
	if instance.is_empty():
		push_error("[GameState] Ship instance not found: %s" % ship_instance_id)
		return false

	# Check if player has the weapon
	if weapon_inventory.get(weapon_id, 0) <= 0:
		push_error("[GameState] Player doesn't have weapon: %s" % weapon_id)
		return false

	# Get or create equipped_weapons array
	var equipped_weapons: Array = instance.get("equipped_weapons", [])

	# Ensure array is large enough
	while equipped_weapons.size() <= slot_index:
		equipped_weapons.append("")

	# Check if slot is already occupied
	if not equipped_weapons[slot_index].is_empty():
		push_error("[GameState] Weapon slot %d already occupied on ship %s" % [slot_index, ship_instance_id])
		return false

	# Equip the weapon
	equipped_weapons[slot_index] = weapon_id
	instance["equipped_weapons"] = equipped_weapons

	# Reduce inventory count
	weapon_inventory[weapon_id] -= 1
	if weapon_inventory[weapon_id] <= 0:
		weapon_inventory.erase(weapon_id)

	print("[GameState] Equipped weapon %s to ship %s slot %d" % [weapon_id, ship_instance_id, slot_index])
	return true

func unequip_weapon_from_ship(ship_instance_id: String, slot_index: int) -> bool:
	"""Unequip a weapon from a ship"""
	# Get ship instance
	var instance := get_ship_instance(ship_instance_id)
	if instance.is_empty():
		push_error("[GameState] Ship instance not found: %s" % ship_instance_id)
		return false

	# Get equipped weapons array
	var equipped_weapons: Array = instance.get("equipped_weapons", [])

	# Validate slot
	if slot_index < 0 or slot_index >= equipped_weapons.size():
		push_error("[GameState] Invalid weapon slot: %d" % slot_index)
		return false

	# Get weapon ID
	var weapon_id: String = equipped_weapons[slot_index]
	if weapon_id.is_empty():
		push_warning("[GameState] Weapon slot %d already empty on ship %s" % [slot_index, ship_instance_id])
		return false

	# Unequip
	equipped_weapons[slot_index] = ""
	instance["equipped_weapons"] = equipped_weapons

	# Return to inventory
	weapon_inventory[weapon_id] = weapon_inventory.get(weapon_id, 0) + 1

	print("[GameState] Unequipped weapon %s from ship %s slot %d" % [weapon_id, ship_instance_id, slot_index])
	return true

func _count_inventory(inventory: Dictionary) -> int:
	"""Count total items in inventory"""
	var total := 0
	for count in inventory.values():
		total += count
	return total

# ============================================================
# BLUEPRINT MANAGEMENT
# ============================================================

func unlock_blueprint(blueprint_id: String) -> void:
	if not unlocked_blueprints.has(blueprint_id):
		unlocked_blueprints.append(blueprint_id)
		print("[GameState] Blueprint unlocked: %s" % blueprint_id)

func has_blueprint(blueprint_id: String) -> bool:
	return unlocked_blueprints.has(blueprint_id)

# ============================================================
# STATISTICS
# ============================================================

func record_combat_victory() -> void:
	total_combats_won += 1
	combats_this_sector += 1
	print("[GameState] Combat victory recorded (Total: %d)" % total_combats_won)

func record_combat_defeat() -> void:
	total_combats_lost += 1
	combats_this_sector += 1
	print("[GameState] Combat defeat recorded (Total: %d)" % total_combats_lost)

func record_enemy_destroyed() -> void:
	total_enemies_destroyed += 1

func record_node_visited() -> void:
	total_nodes_visited += 1
	nodes_visited_this_sector += 1

func collect_tier_1_upgrade(item_id: String) -> void:
	"""Collect a Tier 1 upgrade item"""
	if tier_1_inventory.has(item_id):
		tier_1_inventory[item_id] += 1
	else:
		tier_1_inventory[item_id] = 1

	EventBus.tier_1_upgrade_collected.emit(item_id, tier_1_inventory[item_id])
	print("[GameState] Tier 1 upgrade collected: %s (Total: %d)" % [item_id, tier_1_inventory[item_id]])


func get_tier_1_count(item_id: String) -> int:
	"""Get count of specific Tier 1 upgrade"""
	return tier_1_inventory.get(item_id, 0)


func get_total_tier_1_count() -> int:
	"""Get total count of all Tier 1 upgrades"""
	var total = 0
	for count in tier_1_inventory.values():
		total += count
	return total

func record_enemy_trigger() -> void:
	enemy_triggers += 1
	print("[GameState] Enemy trigger recorded! Total: %d" % enemy_triggers)

func get_elapsed_time_formatted() -> String:
	"""Returns elapsed time formatted as MM:SS"""
	var total_seconds = int(elapsed_time)
	var minutes = total_seconds / 60
	var seconds = total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]

# ============================================================
# SCREEN MANAGEMENT
# ============================================================

func change_screen(new_screen: String) -> void:
	var old_screen := current_screen
	current_screen = new_screen
	EventBus.screen_changed.emit(old_screen, new_screen)
	print("[GameState] Screen changed: %s → %s" % [old_screen, new_screen])

# ============================================================
# PAUSE/RESUME
# ============================================================

func pause_game() -> void:
	if not is_paused:
		is_paused = true
		get_tree().paused = true
		EventBus.game_paused.emit()
		print("[GameState] Game paused")

func resume_game() -> void:
	if is_paused:
		is_paused = false
		get_tree().paused = false
		EventBus.game_resumed.emit()
		print("[GameState] Game resumed")

func toggle_pause() -> void:
	if is_paused:
		resume_game()
	else:
		pause_game()

# ============================================================
# SECTOR STATE
# ============================================================

func is_sector_active() -> bool:
	"""Check if sector exploration is currently active"""
	return sector_active

func start_sector_exploration() -> void:
	"""Mark sector exploration as active"""
	sector_active = true
	print("[GameState] Sector exploration started")

func end_sector_exploration() -> void:
	"""Mark sector exploration as inactive"""
	sector_active = false
	print("[GameState] Sector exploration ended")

# ============================================================
# DEBUG
# ============================================================

func print_state() -> void:
	print("=".repeat(60))
	print("GAME STATE")
	print("=".repeat(60))
	print("Game Started: %s" % game_started)
	print("Current Sector: %d" % current_sector)
	print("Current Screen: %s" % current_screen)
	print("Is Paused: %s" % is_paused)
	print("")
	print("Fleet Size: %d" % owned_ships.size())
	print("Owned Ships: %s" % str(owned_ships))
	print("Active Loadout: %s" % str(active_loadout))
	print("Unlocked Blueprints: %d" % unlocked_blueprints.size())
	print("")
	print("Sectors Completed: %d" % sectors_completed)
	print("Combats Won: %d" % total_combats_won)
	print("Combats Lost: %d" % total_combats_lost)
	print("Enemies Destroyed: %d" % total_enemies_destroyed)
	print("Nodes Visited: %d" % total_nodes_visited)
	print("=".repeat(60))

# ============================================================
# RESOURCE STREAK MANAGEMENT
# ============================================================

func collect_resource_node(resource_type: String) -> float:
	"""Update streak when collecting a resource, return streak multiplier"""
	# Items don't break streaks
	if resource_type == "item":
		return 1.0

	# Check if this continues or breaks the streak
	if current_streak_resource == "" or current_streak_resource == resource_type:
		# Continue or start new streak
		current_streak_resource = resource_type
		current_streak_count = min(current_streak_count + 1, 10)  # Cap at 10
		streak_time_remaining = 10.0  # Reset timer

		var streak_bonus = (current_streak_count - 1) * 0.10  # 0% to 90% bonus
		var multiplier = 1.0 + streak_bonus

		EventBus.resource_streak_updated.emit(current_streak_resource, current_streak_count, multiplier)
		print("[GameState] Streak: %s x%d (%.0f%% bonus, %.1f multiplier)" %
			[resource_type.capitalize(), current_streak_count, streak_bonus * 100, multiplier])

		return multiplier
	else:
		# Different resource breaks streak
		_break_streak()
		EventBus.resource_streak_broken.emit()

		# Start new streak
		current_streak_resource = resource_type
		current_streak_count = 1
		streak_time_remaining = 10.0

		EventBus.resource_streak_updated.emit(current_streak_resource, current_streak_count, 1.0)
		print("[GameState] New streak started: %s" % resource_type.capitalize())

		return 1.0


func _break_streak() -> void:
	"""Break the current streak"""
	if current_streak_count > 0:
		print("[GameState] Streak broken! (%s x%d)" % [current_streak_resource.capitalize(), current_streak_count])

	current_streak_resource = ""
	current_streak_count = 0
	streak_time_remaining = 0.0


func get_streak_display() -> String:
	"""Get formatted streak display string"""
	if current_streak_count == 0:
		return "No Streak"

	var bonus_percent = (current_streak_count - 1) * 10
	return "%s x%d (+%d%%)" % [current_streak_resource.capitalize(), current_streak_count, bonus_percent]


func reset_streak() -> void:
	"""Manually reset streak (for debugging or new sector)"""
	_break_streak()
	EventBus.resource_streak_broken.emit()
