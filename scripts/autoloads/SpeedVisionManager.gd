extends Node

# ============================================================
# SPEED & VISION MANAGER
# ============================================================
# Purpose: Manage player speed (1-10 scale) and vision systems
# Handles: Speed changes, gravity assists, vision multipliers,
#          mining restrictions, camera zoom, emergency wormhole
# ============================================================

# ============================================================
# SPEED SYSTEM (1-10 SCALE)
# ============================================================

var current_speed: int = 1  # 1-10 integer scale for display
var base_forward_speed: float = 100.0  # pixels/second at speed 1
var speed_per_level: float = 20.0  # +20 px/s per speed level
var emergency_wormhole_spawned: bool = false  # Track if speed 10 wormhole created

# ============================================================
# VISION SYSTEM
# ============================================================

var current_vision_multiplier: float = 1.0  # Calculated: speed + upgrades
var base_vision_radius: float = 400.0  # Base visibility radius in pixels
var vision_bonus_per_speed: float = 0.05  # +5% vision per speed level above 1
var vision_from_upgrades: float = 0.0  # Bonus from relic upgrades (additive)

# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
	print("[SpeedVisionManager] Initialized")
	print("[SpeedVisionManager] Speed: %d (%.1f px/s)" % [current_speed, get_forward_speed_pixels_per_second()])
	print("[SpeedVisionManager] Vision: %.2fx (%.1f px radius)" % [current_vision_multiplier, get_current_vision_radius()])
	_update_vision_from_speed()

# ============================================================
# SPEED SYSTEM FUNCTIONS
# ============================================================

func get_forward_speed_pixels_per_second() -> float:
	"""Calculate current forward speed in pixels per second"""
	return base_forward_speed + (current_speed - 1) * speed_per_level

func apply_gravity_assist(multiplier: float, increase: bool) -> bool:
	"""Apply gravity assist speed change (costs 1 fuel)

	Args:
		multiplier: Gravity assist strength from CSV (0.05 to 0.8)
		increase: True to speed up, False to slow down

	Returns:
		True if successful, False if insufficient fuel
	"""
	# Cost: 1 fuel
	if not ResourceManager.spend_resources({"fuel": 1}, "gravity_assist"):
		print("[SpeedVisionManager] Gravity assist blocked - insufficient fuel")
		return false

	# Calculate speed change based on multiplier
	# 0.05 = 1 speed level, 0.4 = 4 speed levels
	var speed_change := int(ceil(multiplier * 10.0))
	var old_speed := current_speed

	if increase:
		current_speed = mini(current_speed + speed_change, 10)
	else:
		current_speed = maxi(current_speed - speed_change, 1)

	if old_speed != current_speed:
		print("[SpeedVisionManager] Speed changed: %d -> %d (%.1f px/s)" % [old_speed, current_speed, get_forward_speed_pixels_per_second()])
		EventBus.speed_changed.emit(current_speed)
		_update_vision_from_speed()

		# Auto-spawn emergency wormhole at speed 10
		if current_speed == 10 and not emergency_wormhole_spawned:
			emergency_wormhole_spawned = true
			EventBus.emergency_wormhole_spawned.emit()
			print("[SpeedVisionManager] Speed 10 reached - emergency wormhole spawned!")

	return true

func increase_speed(amount: int = 1) -> void:
	"""Directly increase speed (for upgrades/relics)"""
	var old_speed := current_speed
	current_speed = mini(current_speed + amount, 10)

	if old_speed != current_speed:
		print("[SpeedVisionManager] Speed increased: %d -> %d" % [old_speed, current_speed])
		EventBus.speed_changed.emit(current_speed)
		_update_vision_from_speed()

		if current_speed == 10 and not emergency_wormhole_spawned:
			emergency_wormhole_spawned = true
			EventBus.emergency_wormhole_spawned.emit()

func decrease_speed(amount: int = 1) -> void:
	"""Directly decrease speed (for penalties/hazards)"""
	var old_speed := current_speed
	current_speed = maxi(current_speed - amount, 1)

	if old_speed != current_speed:
		print("[SpeedVisionManager] Speed decreased: %d -> %d" % [old_speed, current_speed])
		EventBus.speed_changed.emit(current_speed)
		_update_vision_from_speed()

func can_mine_at_current_speed(node_type: String) -> bool:
	"""Check if current speed allows mining this node type

	Speed Restrictions:
	- Speed 1-2: Can mine all nodes
	- Speed 3+: Cannot mine planets (rocky, icy, moons) - restriction = 2
	- Speed 5+: Cannot mine stellar bodies (stars) - restriction = 4
	- Speed any: Can mine asteroids, outposts - restriction = 0

	Args:
		node_type: The node type to check

	Returns:
		True if mining allowed at current speed
	"""
	var node_config := DataManager.get_node_config(node_type)
	var speed_restriction: int = node_config.get("speed_restriction_mining", 0)

	if speed_restriction == 0:
		return true  # No restriction

	return current_speed <= speed_restriction

func get_speed_restriction_reason(node_type: String) -> String:
	"""Get human-readable reason for mining restriction"""
	var node_config := DataManager.get_node_config(node_type)
	var speed_restriction: int = node_config.get("speed_restriction_mining", 0)

	if speed_restriction == 0:
		return ""

	if current_speed > speed_restriction:
		return "Speed too high to deploy miners (max speed: %d, current: %d)" % [speed_restriction, current_speed]

	return ""

func reset_speed() -> void:
	"""Reset speed to 1 (called when entering new sector)"""
	current_speed = 1
	emergency_wormhole_spawned = false
	EventBus.speed_changed.emit(current_speed)
	_update_vision_from_speed()
	print("[SpeedVisionManager] Speed reset to 1")

# ============================================================
# VISION SYSTEM FUNCTIONS
# ============================================================

func get_current_vision_radius() -> float:
	"""Get current vision radius in pixels"""
	return base_vision_radius * current_vision_multiplier

func _update_vision_from_speed() -> void:
	"""Recalculate vision multiplier from speed + upgrades"""
	var speed_bonus := (current_speed - 1) * vision_bonus_per_speed
	var old_vision := current_vision_multiplier
	current_vision_multiplier = 1.0 + speed_bonus + vision_from_upgrades

	if abs(old_vision - current_vision_multiplier) > 0.001:
		EventBus.vision_changed.emit(current_vision_multiplier)
		print("[SpeedVisionManager] Vision updated: %.2fx (%.1f px radius)" % [current_vision_multiplier, get_current_vision_radius()])

func apply_vision_upgrade(bonus_multiplier: float) -> void:
	"""Apply vision bonus from relic upgrade

	Args:
		bonus_multiplier: Additive vision bonus (e.g., 0.2 for +20%)
	"""
	vision_from_upgrades += bonus_multiplier
	_update_vision_from_speed()
	EventBus.vision_upgrade_applied.emit(bonus_multiplier)
	print("[SpeedVisionManager] Vision upgrade applied: +%.1f%%" % (bonus_multiplier * 100.0))

func get_camera_zoom_level() -> float:
	"""Calculate camera zoom level based on vision

	Camera zooms OUT as vision increases to show more area
	Formula: zoom = 1.0 - (vision - 1.0) * 0.3

	Returns:
		Zoom level (1.0 = normal, 0.5 = zoomed out 2x, showing 2x area)
	"""
	var zoom_out_factor := 1.0 - (current_vision_multiplier - 1.0) * 0.3
	return clamp(zoom_out_factor, 0.5, 1.0)

func reset_vision_upgrades() -> void:
	"""Reset vision upgrades to 0 (called when entering new sector or resetting run)"""
	vision_from_upgrades = 0.0
	_update_vision_from_speed()
	print("[SpeedVisionManager] Vision upgrades reset")

# ============================================================
# UTILITY FUNCTIONS
# ============================================================

func get_speed_info() -> Dictionary:
	"""Get complete speed system state for UI/debugging"""
	return {
		"current_speed": current_speed,
		"speed_pixels_per_second": get_forward_speed_pixels_per_second(),
		"can_mine_planets": current_speed <= 2,
		"can_mine_stars": current_speed <= 4,
		"emergency_wormhole_available": current_speed == 10
	}

func get_vision_info() -> Dictionary:
	"""Get complete vision system state for UI/debugging"""
	return {
		"vision_multiplier": current_vision_multiplier,
		"vision_radius_pixels": get_current_vision_radius(),
		"speed_bonus": (current_speed - 1) * vision_bonus_per_speed,
		"upgrade_bonus": vision_from_upgrades,
		"camera_zoom": get_camera_zoom_level()
	}
