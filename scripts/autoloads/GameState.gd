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

# ============================================================
# FLEET STATE
# ============================================================

var owned_ships: Array[String] = []        # Ship IDs the player owns
var active_loadout: Array[String] = []     # Ships deployed in current combat
var unlocked_blueprints: Array[String] = []

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

# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
	print("[GameState] Initialized")
	_initialize_starter_fleet()

func _initialize_starter_fleet() -> void:
	# Give player starter ships (Phase 1 placeholder)
	owned_ships = [
		"basic_fighter",
		"basic_interceptor",
		"shadow_fighter"
	]
	print("[GameState] Starter fleet initialized: %s" % str(owned_ships))

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
	run_start_time = Time.get_unix_time_from_system()

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
