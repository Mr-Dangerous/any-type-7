extends Node

# ============================================================
# EVENT BUS - CENTRALIZED SIGNAL HUB
# ============================================================
# Purpose: Decoupled cross-system communication via signals
# All systems emit and listen to signals through this singleton
# This prevents direct script dependencies and spaghetti code
# ============================================================

# ============================================================
# CORE GAME SIGNALS
# ============================================================

signal game_started()
signal game_paused()
signal game_resumed()
signal game_quit()

# ============================================================
# RESOURCE SIGNALS
# ============================================================

signal resource_changed(resource_type: String, old_amount: int, new_amount: int)
signal resource_spent(resource_type: String, amount: int, reason: String)
signal resource_gained(resource_type: String, amount: int, source: String)

# Resource streak system
signal resource_streak_updated(resource_type: String, streak_count: int, multiplier: float)
signal resource_streak_broken()

# ============================================================
# DATA LOADING SIGNALS
# ============================================================

signal data_load_started(database_name: String)
signal data_load_completed(database_name: String, record_count: int)
signal data_load_failed(database_name: String, error: String)
signal all_data_loaded()

# ============================================================
# COMBAT SIGNALS (Phase 3)
# ============================================================

signal combat_started(scenario_id: String)
signal combat_phase_changed(old_phase: String, new_phase: String)
signal combat_wave_spawned(wave_number: int)
signal combat_wave_completed(wave_number: int)
signal combat_ended(victory: bool, rewards: Dictionary)

signal ship_deployed(ship_id: String, lane: int)
signal ship_destroyed(ship_id: String, is_player: bool)
signal ship_damaged(ship_id: String, damage: float, remaining_hp: float)

# ============================================================
# SECTOR EXPLORATION SIGNALS (Phase 2)
# ============================================================

signal sector_entered(sector_number: int)
signal sector_exited()
signal node_discovered(node_id: String, node_type: String)
signal node_activated(node_id: String)

# Node spawning/despawning
signal node_spawned(node_id: String, node_type: String, position: Vector2)
signal node_despawned(node_id: String)

# Node proximity detection
signal node_proximity_entered(node_id: String, node_type: String)
signal node_proximity_exited(node_id: String)

# Gravity assist
signal gravity_assist_applied(choice: String, node_position: Vector2, multiplier: float)

# Node tagging and collection
signal place_boi_collected(total_count: int)

# ============================================================
# SPEED & VISION SYSTEM SIGNALS
# ============================================================

signal speed_changed(new_speed: int)
signal vision_changed(vision_multiplier: float)
signal vision_upgrade_applied(bonus_multiplier: float)
signal mining_blocked_speed_too_high(node_type: String, max_speed: int)
signal emergency_wormhole_spawned()

# ============================================================
# ENVIRONMENTAL BAND SIGNALS
# ============================================================

signal band_entered(band_id: String, band_name: String)
signal band_exited(band_id: String)
signal band_overlay_changed(overlay_path: String, haze_effect: String)
signal special_node_available(node_type: String)

# ============================================================
# RESOURCE ASSIGNMENT SIGNALS
# ============================================================

signal node_resources_assigned(node_id: String, resource_profile: String)
signal gas_giant_rings_detected(node_id: String, has_rings: bool)

# ============================================================
# HANGAR SIGNALS (Phase 4)
# ============================================================

signal ship_equipped(ship_id: String, equipment_id: String, slot: String)
signal ship_unequipped(ship_id: String, slot: String)
signal loadout_changed(ship_ids: Array)

# ============================================================
# UI SIGNALS
# ============================================================

signal screen_changed(old_screen: String, new_screen: String)
signal notification_shown(message: String, type: String)
signal button_pressed(button_id: String)

# ============================================================
# SAVE/LOAD SIGNALS
# ============================================================

signal save_started()
signal save_completed(save_path: String)
signal save_failed(error: String)
signal load_started(save_path: String)
signal load_completed()
signal load_failed(error: String)

# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
	print("[EventBus] Initialized - Signal hub ready")
	print("[EventBus] %d signals available for cross-system communication" % _count_signals())

# ============================================================
# HELPER FUNCTIONS
# ============================================================

func _count_signals() -> int:
	var signal_list := get_signal_list()
	return signal_list.size()

func print_all_signals() -> void:
	print("=".repeat(60))
	print("EVENTBUS - AVAILABLE SIGNALS")
	print("=".repeat(60))
	var signal_list := get_signal_list()
	for sig in signal_list:
		print("  - %s" % sig.name)
	print("=".repeat(60))
