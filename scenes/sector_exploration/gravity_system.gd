extends Node

## Gravity Assist System Module
## Handles gravity zone detection, visual feedback, and boost multipliers

# Gravity node tracking
var gravity_nodes_in_proximity: Array[Dictionary] = []

# References (set by parent)
var player_movement: Node = null
var node_spawner: Node = null
var boost_system: Node = null

# Visual feedback
var draw_proximity_zones: bool = false


func _ready() -> void:
	print("[GravitySystem] Initialized")


func initialize(player_mv: Node, spawner: Node, boost_sys: Node) -> void:
	"""Initialize with system references"""
	player_movement = player_mv
	node_spawner = spawner
	boost_system = boost_sys
	print("[GravitySystem] Linked to player, spawner, and boost systems")


func process_gravity(delta: float) -> void:
	"""Update gravity system each frame"""
	# Check which gravity nodes player is inside
	_update_proximity_tracking()

	# Update visual feedback based on boost state
	draw_proximity_zones = boost_system.is_active()
	_update_visual_feedback()


func _update_proximity_tracking() -> void:
	"""Track which gravity nodes the player is inside"""
	gravity_nodes_in_proximity.clear()

	var player_x = player_movement.get_position()
	var active_nodes = node_spawner.get_active_nodes()

	for node_data in active_nodes:
		var csv_data = node_data.get("csv_data", {})
		var has_gravity = csv_data.get("gravity_assist", "no") == "yes"

		if not has_gravity:
			continue

		var node_pos = node_data.position
		var proximity_radius = float(csv_data.get("proximity_radius", 100))
		var gravity_multiplier = float(csv_data.get("gravity_assist_multiplier", 0.0))

		# Check if player is inside proximity radius (only check X distance for now)
		var distance = abs(player_x - node_pos.x)

		if distance <= proximity_radius:
			gravity_nodes_in_proximity.append({
				"node_id": node_data.node_id,
				"node_ref": node_data.node_ref,
				"position": node_pos,
				"proximity_radius": proximity_radius,
				"multiplier": gravity_multiplier
			})


func _update_visual_feedback() -> void:
	"""Update visual feedback on gravity nodes"""
	var active_nodes = node_spawner.get_active_nodes()

	for node_data in active_nodes:
		var node = node_data.node_ref as Area2D
		if not node:
			continue

		var csv_data = node_data.get("csv_data", {})
		var has_gravity = csv_data.get("gravity_assist", "no") == "yes"

		if has_gravity and node.has_method("set_show_gravity_zone"):
			# Show green outline when boosting
			node.set_show_gravity_zone(draw_proximity_zones)


func get_current_gravity_multiplier() -> float:
	"""Get the combined gravity multiplier for current position"""
	if gravity_nodes_in_proximity.is_empty():
		return 0.0

	# Use the strongest multiplier if multiple zones overlap
	var max_multiplier = 0.0
	for gravity_node in gravity_nodes_in_proximity:
		max_multiplier = max(max_multiplier, gravity_node.multiplier)

	return max_multiplier


func is_in_gravity_zone() -> bool:
	"""Check if player is currently in any gravity zone"""
	return not gravity_nodes_in_proximity.is_empty()


func get_gravity_zones_info() -> String:
	"""Get debug info about current gravity zones"""
	if gravity_nodes_in_proximity.is_empty():
		return "No gravity zones"

	var info = "Gravity zones: "
	for gravity_node in gravity_nodes_in_proximity:
		info += "%s (%.1fx) " % [gravity_node.node_id, gravity_node.multiplier]

	return info
