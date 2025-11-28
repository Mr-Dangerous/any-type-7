extends Node

# ============================================================
# ENVIRONMENT MANAGER
# ============================================================
# Purpose: Manage environmental band system for sector exploration
# Handles: Band transitions (structured/random), spawn weight mods,
#          special nodes, visual overlays, band-specific effects
# ============================================================

# ============================================================
# BAND STATE
# ============================================================

var current_band_id: String = "default"
var current_band_config: Dictionary = {}
var band_distance_traveled: float = 0.0
var next_band_transition_distance: float = 1000.0

# Band history for preventing repetition
var recent_bands: Array[String] = []
const MAX_RECENT_BANDS: int = 3

# ============================================================
# CONSTANTS
# ============================================================

const STRUCTURED_CHANCE: float = 0.7  # 70% structured, 30% random
const MIN_BAND_LENGTH: float = 1500.0  # Minimum pixels before transition
const MAX_BAND_LENGTH: float = 3000.0  # Maximum pixels before transition

# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
	print("[EnvironmentManager] Initialized")
	_load_band_config("default")
	print("[EnvironmentManager] Starting band: %s" % current_band_config.get("band_name", "Unknown"))

func _process(delta: float) -> void:
	if not GameState.is_sector_active():
		return

	# Track distance traveled in current band
	band_distance_traveled += SpeedVisionManager.get_forward_speed_pixels_per_second() * delta

	# Check for band transition
	if band_distance_traveled >= next_band_transition_distance:
		_transition_to_new_band()

# ============================================================
# BAND TRANSITION LOGIC
# ============================================================

func _transition_to_new_band() -> void:
	"""Transition to a new environmental band (procedural mix)"""
	var use_random := randf() < (1.0 - STRUCTURED_CHANCE)  # 30% random
	var new_band_id: String

	if use_random:
		new_band_id = _select_random_band()
		print("[EnvironmentManager] Random band transition")
	else:
		new_band_id = _select_structured_band()
		print("[EnvironmentManager] Structured band transition")

	_enter_band(new_band_id)

	# Reset distance tracking and randomize next transition
	band_distance_traveled = 0.0
	next_band_transition_distance = randf_range(MIN_BAND_LENGTH, MAX_BAND_LENGTH)

func _select_structured_band() -> String:
	"""Select band based on structured progression (distance-based)"""
	var total_distance := SectorManager.player_forward_position

	# Early sector (0-1000px): Calm space
	if total_distance < 1000:
		return "default"

	# Clear space phase (1000-2000px)
	elif total_distance < 2000:
		return "clear_space"

	# Light hazard phase (2000-3500px)
	elif total_distance < 3500:
		var options := ["nebula_light", "debris_field_light"]
		return options[randi() % options.size()]

	# Heavy hazard phase (3500-5000px)
	elif total_distance < 5000:
		var options := ["enemy_territory", "debris_field_heavy"]
		return options[randi() % options.size()]

	# Beyond 5000px: Full random with sector restrictions
	else:
		return _select_random_band()

func _select_random_band() -> String:
	"""Select band using weighted random selection"""
	var available_bands := DataManager.get_available_bands(GameState.current_sector)

	if available_bands.is_empty():
		return "default"

	# Filter out recent bands to avoid repetition
	var filtered_bands := []
	for band in available_bands:
		if band.get("band_id") not in recent_bands:
			filtered_bands.append(band)

	# If all bands are recent, use all available
	if filtered_bands.is_empty():
		filtered_bands = available_bands

	# Weighted random selection
	return _weighted_random_selection(filtered_bands)

func _weighted_random_selection(bands: Array) -> String:
	"""Weighted random selection from band array

	Args:
		bands: Array of band dictionaries with spawn_weight

	Returns:
		Selected band_id
	"""
	var total_weight := 0
	for band in bands:
		total_weight += band.get("spawn_weight", 1)

	var rand_value := randf() * total_weight
	var cumulative_weight := 0.0

	for band in bands:
		cumulative_weight += band.get("spawn_weight", 1)
		if rand_value <= cumulative_weight:
			return band.get("band_id", "default")

	# Fallback to first band
	return bands[0].get("band_id", "default")

func _enter_band(band_id: String) -> void:
	"""Enter a new environmental band

	Args:
		band_id: The band to enter
	"""
	var old_band := current_band_id
	current_band_id = band_id
	_load_band_config(band_id)

	# Add to recent history
	recent_bands.append(band_id)
	if recent_bands.size() > MAX_RECENT_BANDS:
		recent_bands.pop_front()

	print("[EnvironmentManager] Band transition: %s -> %s" % [old_band, band_id])
	print("[EnvironmentManager] Next transition in: %.0f px" % next_band_transition_distance)

	# Emit signals
	EventBus.band_exited.emit(old_band)
	EventBus.band_entered.emit(band_id, current_band_config.get("band_name", "Unknown"))

	# Update visual overlay
	var overlay_path: String = current_band_config.get("visual_overlay", "")
	var haze_effect: String = current_band_config.get("haze_effect", "none")
	if overlay_path != "" and overlay_path != "none":
		EventBus.band_overlay_changed.emit(overlay_path, haze_effect)

	# Log band effects
	_log_band_effects()

func _load_band_config(band_id: String) -> void:
	"""Load band configuration from DataManager"""
	current_band_config = DataManager.get_band_config(band_id)
	if current_band_config.is_empty():
		print("[EnvironmentManager] WARNING: Band '%s' not found, using default" % band_id)
		current_band_config = DataManager.get_band_config("default")

func _log_band_effects() -> void:
	"""Log band effects for debugging"""
	var effects := []

	if current_band_config.get("nebula_effect", false):
		effects.append("Nebula combat effects")
	if current_band_config.get("debris_field_effect", false):
		effects.append("Debris damage")

	var combat_mod: float = current_band_config.get("combat_modifier", 1.0)
	if combat_mod != 1.0:
		effects.append("Combat %.0f%%" % (combat_mod * 100.0))

	var visibility_mod: float = current_band_config.get("visibility_modifier", 1.0)
	if visibility_mod != 1.0:
		effects.append("Vision %.0f%%" % (visibility_mod * 100.0))

	if effects.is_empty():
		print("[EnvironmentManager] Band has no special effects")
	else:
		print("[EnvironmentManager] Band effects: %s" % ", ".join(effects))

# ============================================================
# SPAWN WEIGHT MODIFICATION
# ============================================================

func get_modified_node_spawn_weight(node_type: String) -> int:
	"""Get modified spawn weight for node type in current band

	Args:
		node_type: The node type to check

	Returns:
		Modified spawn weight
	"""
	var base_weight: int = DataManager.get_node_config(node_type).get("spawn_weight", 0)
	var modifier: float = DataManager.get_band_node_weight_modifier(current_band_id, node_type)
	var final_weight := int(base_weight * modifier)

	return maxi(final_weight, 0)

func can_spawn_special_node(node_type: String) -> bool:
	"""Check if a special node can spawn in current band

	Args:
		node_type: The special node type to check

	Returns:
		True if this special node is available in current band
	"""
	var special_nodes: String = current_band_config.get("special_spawn_nodes", "")
	if special_nodes == "none" or special_nodes == "":
		return false

	var node_list := special_nodes.split("|")
	return node_type in node_list

func get_available_special_nodes() -> Array[String]:
	"""Get list of special nodes available in current band

	Returns:
		Array of special node type names
	"""
	var special_nodes: String = current_band_config.get("special_spawn_nodes", "")
	if special_nodes == "none" or special_nodes == "":
		return []

	var nodes: Array[String] = []
	for node in special_nodes.split("|"):
		nodes.append(node)
	return nodes

# ============================================================
# BAND EFFECTS
# ============================================================

func get_visibility_modifier() -> float:
	"""Get current band's visibility modifier

	Returns:
		Visibility multiplier (1.0 = normal, 0.6 = reduced)
	"""
	return current_band_config.get("visibility_modifier", 1.0)

func get_combat_modifier() -> float:
	"""Get current band's combat difficulty modifier

	Returns:
		Combat multiplier (1.0 = normal, 1.3 = harder)
	"""
	return current_band_config.get("combat_modifier", 1.0)

func has_nebula_effect() -> bool:
	"""Check if current band has nebula combat effects"""
	return current_band_config.get("nebula_effect", false)

func has_debris_field_effect() -> bool:
	"""Check if current band has debris damage effects"""
	return current_band_config.get("debris_field_effect", false)

# ============================================================
# SECTOR CONTROL
# ============================================================

func start_sector() -> void:
	"""Initialize band system for new sector"""
	current_band_id = "default"
	_load_band_config("default")
	band_distance_traveled = 0.0
	next_band_transition_distance = randf_range(MIN_BAND_LENGTH, MAX_BAND_LENGTH)
	recent_bands.clear()
	print("[EnvironmentManager] Sector started - band system active")

func reset() -> void:
	"""Reset band system to defaults"""
	start_sector()

# ============================================================
# UTILITY FUNCTIONS
# ============================================================

func get_band_info() -> Dictionary:
	"""Get complete band system state for UI/debugging"""
	return {
		"current_band_id": current_band_id,
		"band_name": current_band_config.get("band_name", "Unknown"),
		"distance_traveled": band_distance_traveled,
		"next_transition": next_band_transition_distance,
		"visibility_modifier": get_visibility_modifier(),
		"combat_modifier": get_combat_modifier(),
		"has_nebula_effect": has_nebula_effect(),
		"has_debris_effect": has_debris_field_effect(),
		"special_nodes_available": get_available_special_nodes()
	}
