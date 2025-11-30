extends Node

## Node Spawner Module
## Handles procedural node spawning, orbiters, and despawning

# Node tracking
var active_nodes: Array[Dictionary] = []
var next_node_id: int = 0

# Separate spawn tracking for each type
var last_planetary_distance: float = -500.0
var last_debris_distance: float = -50.0
var last_node_distance: float = -300.0

# Spawnable node caches by type (loaded from CSV)
var planetary_bodies: Array[Dictionary] = []
var debris_field_nodes: Array[Dictionary] = []
var regular_nodes: Array[Dictionary] = []
var orbiterable_nodes: Array[Dictionary] = []

# Spawn weights
var planetary_total_weight: int = 0
var debris_total_weight: int = 0
var node_total_weight: int = 0

# World container reference (set by parent)
var world_container: Node2D = null

# Scrolling system reference (for distance and speed)
var scrolling_system: Node = null

# Constants
const SPAWN_Y_OFFSET: float = -500.0
const DESPAWN_Y_THRESHOLD: float = 2500.0

# Edge spawn ranges (with bias toward edges)
const SPAWN_LEFT_MIN: float = 0.0
const SPAWN_LEFT_MAX: float = 180.0
const SPAWN_RIGHT_MIN: float = 900.0
const SPAWN_RIGHT_MAX: float = 1080.0
const SPAWN_CENTER_MIN: float = 200.0
const SPAWN_CENTER_MAX: float = 880.0

# Y-coordinate staggering for grouped nodes
const Y_STAGGER_RANGE: float = 80.0

# Orbit settings
const ELLIPTICAL_ORBIT_CHANCE: float = 0.6  # 60% chance of elliptical orbit
const ELLIPSE_VERTICAL_RATIO: float = 0.55  # Vertical axis is 55% of horizontal (narrower)

# Preloaded scenes
var test_node_scene = preload("res://scenes/sector_exploration/test_node.tscn")


func _ready() -> void:
	print("[NodeSpawner] Initialized")


func initialize(container: Node2D, scroll_sys: Node) -> void:
	"""Initialize with references"""
	world_container = container
	scrolling_system = scroll_sys
	_load_spawnable_nodes()
	print("[NodeSpawner] Initialized with world container and scrolling system")


func process_nodes(delta: float) -> void:
	"""Update nodes each frame"""
	_check_node_spawn()
	_update_node_positions(delta)
	_check_node_despawn()


func _load_spawnable_nodes() -> void:
	"""Load spawnable nodes from DataManager, categorized by spawn_type"""
	var all_nodes = DataManager.get_spawnable_nodes()

	planetary_bodies.clear()
	debris_field_nodes.clear()
	regular_nodes.clear()
	orbiterable_nodes.clear()

	planetary_total_weight = 0
	debris_total_weight = 0
	node_total_weight = 0

	for node_data in all_nodes:
		var spawn_type = node_data.get("spawn_type", "").strip_edges()
		var spawn_case = node_data.get("spawn_case", "").strip_edges()
		var can_orbit = node_data.get("orbit", false)
		var spawn_weight = int(node_data.get("spawn_weight", 0))
		var enabled = node_data.get("enabled", "no")

		# Skip disabled nodes
		if enabled != "yes":
			continue

		# Categorize by spawn_type
		match spawn_type:
			"planetary_body":
				planetary_bodies.append(node_data)
				planetary_total_weight += spawn_weight
			"debris_field":
				debris_field_nodes.append(node_data)
				debris_total_weight += spawn_weight
			"node":
				regular_nodes.append(node_data)
				node_total_weight += spawn_weight
			"orbiter":
				# Orbiters spawn with planetary bodies, not independently
				orbiterable_nodes.append(node_data)

		# Also cache nodes that can orbit for planetary bodies
		if can_orbit and spawn_type != "orbiter":
			orbiterable_nodes.append(node_data)

	print("[NodeSpawner] Loaded spawnable node types:")
	print("  Planetary Bodies: %d (weight: %d)" % [planetary_bodies.size(), planetary_total_weight])
	print("  Debris Fields: %d (weight: %d)" % [debris_field_nodes.size(), debris_total_weight])
	print("  Regular Nodes: %d (weight: %d)" % [regular_nodes.size(), node_total_weight])
	print("  Orbiters: %d" % orbiterable_nodes.size())


func _check_node_spawn() -> void:
	"""Check if we should spawn new nodes based on three separate timers"""
	var current_distance = scrolling_system.get_distance()

	# Check planetary body spawning
	var planetary_interval = DebugManager.get_planetary_interval()
	if current_distance >= last_planetary_distance + planetary_interval:
		_spawn_planetary_body()
		last_planetary_distance = current_distance

	# Check debris field spawning
	var debris_interval = DebugManager.get_debris_interval()
	if current_distance >= last_debris_distance + debris_interval:
		_spawn_debris_cluster()
		last_debris_distance = current_distance

	# Check regular node spawning
	var node_interval = DebugManager.get_node_interval()
	if current_distance >= last_node_distance + node_interval:
		_spawn_regular_node()
		last_node_distance = current_distance


func _spawn_planetary_body() -> void:
	"""Spawn ONE planetary body on left or right edge with orbiters"""
	if planetary_bodies.is_empty():
		return

	# Pick random planetary body based on spawn weight
	var selected_node = _weighted_random_select(planetary_bodies, planetary_total_weight)
	if not selected_node:
		return

	# Spawn on left or right edge randomly
	var spawn_on_right = randf() < 0.5
	var spawn_x = SPAWN_RIGHT_MIN + randf() * (SPAWN_RIGHT_MAX - SPAWN_RIGHT_MIN) if spawn_on_right \
				  else SPAWN_LEFT_MIN + randf() * (SPAWN_LEFT_MAX - SPAWN_LEFT_MIN)

	var spawn_pos = Vector2(spawn_x, SPAWN_Y_OFFSET)

	# Create the planetary body
	var node_id = "node_%d" % next_node_id
	next_node_id += 1

	var node_instance = _create_node_instance(node_id, selected_node, spawn_pos)
	if node_instance:
		# Check if this planet can have orbiters
		var spawn_side = "right" if spawn_on_right else "left"
		_check_and_spawn_orbiters(node_id, node_instance, selected_node, spawn_pos, spawn_side)

		print("[NodeSpawner] Spawned planetary_body: %s at (%.0f, %.0f)" % [selected_node.get("node_type"), spawn_x, SPAWN_Y_OFFSET])


func _spawn_debris_cluster() -> void:
	"""Spawn debris nodes clustered together, not on edges"""
	if debris_field_nodes.is_empty():
		return

	var cluster_range = DebugManager.get_debris_cluster_range()
	var cluster_size = randi_range(cluster_range.x, cluster_range.y)
	var base_x = SPAWN_CENTER_MIN + randf() * (SPAWN_CENTER_MAX - SPAWN_CENTER_MIN)
	var base_y = SPAWN_Y_OFFSET + randf_range(-Y_STAGGER_RANGE, Y_STAGGER_RANGE)

	for i in range(cluster_size):
		var selected_node = _weighted_random_select(debris_field_nodes, debris_total_weight)
		if not selected_node:
			continue

		# Cluster debris close together (within 150px radius)
		var offset_x = randf_range(-150, 150)
		var offset_y = randf_range(-150, 150)
		var spawn_pos = Vector2(base_x + offset_x, base_y + offset_y)

		# Clamp to non-edge area
		spawn_pos.x = clamp(spawn_pos.x, SPAWN_CENTER_MIN, SPAWN_CENTER_MAX)

		var node_id = "debris_%d" % next_node_id
		next_node_id += 1

		var node_instance = _create_node_instance(node_id, selected_node, spawn_pos)
		if node_instance:
			# Mark as debris for despawn behavior
			node_instance.set_meta("is_debris", true)

	print("[NodeSpawner] Spawned debris cluster: %d nodes at (%.0f, %.0f)" % [cluster_size, base_x, base_y])


func _spawn_regular_node() -> void:
	"""Spawn regular nodes (traders, outposts, etc.)"""
	if regular_nodes.is_empty():
		return

	var selected_node = _weighted_random_select(regular_nodes, node_total_weight)
	if not selected_node:
		return

	# Regular nodes can spawn in center area
	var spawn_x = SPAWN_CENTER_MIN + randf() * (SPAWN_CENTER_MAX - SPAWN_CENTER_MIN)
	var spawn_pos = Vector2(spawn_x, SPAWN_Y_OFFSET)

	var node_id = "node_%d" % next_node_id
	next_node_id += 1

	_create_node_instance(node_id, selected_node, spawn_pos)
	print("[NodeSpawner] Spawned regular node: %s at (%.0f, %.0f)" % [selected_node.get("node_type"), spawn_x, SPAWN_Y_OFFSET])


func _weighted_random_select(node_array: Array, total_weight: int) -> Dictionary:
	"""Select a node from array based on spawn weights"""
	if node_array.is_empty() or total_weight == 0:
		return {}

	var roll = randi() % total_weight
	var cumulative = 0

	for node_data in node_array:
		cumulative += int(node_data.get("spawn_weight", 0))
		if roll < cumulative:
			return node_data

	return node_array[0]  # Fallback


func _create_node_instance(node_id: String, node_data: Dictionary, position: Vector2) -> Area2D:
	"""Create and configure a node instance"""
	var node_instance = test_node_scene.instantiate()
	var node_type = node_data.get("node_type", "unknown")

	node_instance.setup(node_id, node_type, node_data, scrolling_system.get_distance())
	node_instance.global_position = position

	world_container.add_child(node_instance)

	# Track node
	active_nodes.append({
		"node_id": node_id,
		"node_ref": node_instance,
		"node_type": node_type,
		"is_activated": false
	})

	EventBus.node_spawned.emit(node_id, node_type, position)
	return node_instance


func _select_random_orbiterable_node() -> Dictionary:
	"""Select random orbiterable node"""
	if orbiterable_nodes.is_empty():
		return {}
	return orbiterable_nodes[randi() % orbiterable_nodes.size()]


func _check_and_spawn_orbiters(parent_id: String, parent_node: Area2D, parent_csv: Dictionary, parent_pos: Vector2, parent_spawn_pos: String) -> void:
	"""Check if node can have orbiters and spawn them"""
	if not parent_csv.get("can_have_orbiters", false):
		return

	var moon_chance = float(parent_csv.get("moon_chance", 0))
	var max_orbiters = int(parent_csv.get("max_moons", 0))

	if moon_chance <= 0 or max_orbiters <= 0:
		return

	if randf() * 100.0 >= moon_chance:
		return

	var num_orbiters = randi_range(1, max_orbiters)
	var parent_radius = float(parent_csv.get("size", 100)) / 2.0
	var orbit_radius = parent_radius + 100.0

	# Determine if this orbital system will be elliptical
	var is_elliptical = randf() < ELLIPTICAL_ORBIT_CHANCE
	var semi_major_axis = orbit_radius
	var semi_minor_axis = orbit_radius * ELLIPSE_VERTICAL_RATIO if is_elliptical else orbit_radius

	parent_node.set_has_orbiters(orbit_radius, is_elliptical, semi_major_axis, semi_minor_axis)

	for i in range(num_orbiters):
		_spawn_orbiter(parent_id, parent_node, parent_csv, parent_pos, i, num_orbiters, orbit_radius, parent_spawn_pos, is_elliptical, semi_major_axis, semi_minor_axis)


func _spawn_orbiter(parent_id: String, parent_node: Area2D, parent_csv: Dictionary, parent_pos: Vector2,
					index: int, total: int, orbit_radius: float, parent_spawn_pos: String,
					is_elliptical: bool, semi_major_axis: float, semi_minor_axis: float) -> void:
	"""Spawn single orbiter"""
	var orbiter_csv = _select_random_orbiterable_node()
	if orbiter_csv.is_empty():
		return

	var orbiter_type = orbiter_csv.get("node_type", "unknown")

	# Calculate initial angle
	var angle_range_start: float
	var angle_range_end: float

	if parent_spawn_pos == "right":
		angle_range_start = deg_to_rad(140.0)
		angle_range_end = deg_to_rad(160.0)
	else:
		angle_range_start = 0.0
		angle_range_end = PI / 3.0

	var angle_step = (angle_range_end - angle_range_start) / max(total, 1)
	var initial_angle = angle_range_start + (angle_step * index)

	# Base orbit speed (will be modulated during update)
	var base_orbit_speed = randf_range(0.2, 0.6)

	# Calculate initial position
	var offset = Vector2(
		cos(initial_angle - PI/2) * semi_major_axis,
		sin(initial_angle - PI/2) * semi_minor_axis
	)
	var orbiter_pos = parent_pos + offset

	var orbiter_node = test_node_scene.instantiate()
	var orbiter_id = "%s_%d" % [orbiter_type, next_node_id]
	next_node_id += 1

	orbiter_node.setup(orbiter_id, orbiter_type, orbiter_csv, scrolling_system.get_distance())
	orbiter_node.position = orbiter_pos
	orbiter_node.setup_orbit(parent_id, orbit_radius, initial_angle, is_elliptical, semi_major_axis, semi_minor_axis)
	world_container.add_child(orbiter_node)

	var tracking_data = {
		"node_id": orbiter_id,
		"node_ref": orbiter_node,
		"position": orbiter_pos,
		"spawn_distance": scrolling_system.get_distance(),
		"node_type": orbiter_type,
		"csv_data": orbiter_csv,
		"is_activated": false,
		"is_orbiter": true,
		"parent_id": parent_id,
		"orbit_radius": orbit_radius,
		"orbit_angle": initial_angle,
		"orbit_speed": base_orbit_speed,
		"is_elliptical": is_elliptical,
		"semi_major_axis": semi_major_axis,
		"semi_minor_axis": semi_minor_axis
	}
	active_nodes.append(tracking_data)

	EventBus.node_spawned.emit(orbiter_id, orbiter_type, orbiter_pos)


func _update_node_positions(delta: float) -> void:
	"""Update all node positions"""
	var scroll_speed = scrolling_system.get_scroll_speed()

	for node_data in active_nodes:
		# Validate node reference before casting
		if not node_data.has("node_ref") or not is_instance_valid(node_data.node_ref):
			continue

		var node = node_data.node_ref as Area2D
		if not node:
			continue

		# Skip scrolling for nodes locked by tractor beam
		if node.has_meta("tractor_locked") and node.get_meta("tractor_locked"):
			node_data.position = node.position
			continue

		# Skip scrolling for nodes being attracted (but not locked)
		if node.has_meta("tractor_attracting") and node.get_meta("tractor_attracting"):
			# Attracting nodes handle their own movement, don't scroll them
			node_data.position = node.position
			continue

		if node_data.get("is_orbiter", false):
			# Orbiting node
			var parent_id = node_data.get("parent_id", "")
			var parent_data = _find_node_data(parent_id)

			if parent_data.is_empty():
				node.position.y += scroll_speed * delta
			else:
				var base_orbit_speed = node_data.get("orbit_speed", 0.3)
				var is_elliptical = node_data.get("is_elliptical", false)
				var angle = node_data.orbit_angle

				# Variable speed for elliptical orbits (slower at narrow parts)
				var speed_multiplier = 1.0
				if is_elliptical:
					# Slower at top/bottom (narrow parts), faster at sides
					# Use cosine of vertical component to modulate speed
					var vertical_factor = abs(sin(angle - PI/2))  # 0 at sides, 1 at top/bottom
					speed_multiplier = 1.0 + (1.0 - vertical_factor) * 0.8  # Range: 1.0 to 1.8x

				node_data.orbit_angle += base_orbit_speed * speed_multiplier * delta

				var parent_node = parent_data.node_ref as Area2D
				if parent_node:
					var semi_major = node_data.get("semi_major_axis", 100.0)
					var semi_minor = node_data.get("semi_minor_axis", 100.0)
					angle = node_data.orbit_angle

					# Calculate elliptical position
					var offset = Vector2(
						cos(angle - PI/2) * semi_major,
						sin(angle - PI/2) * semi_minor
					)
					node.position = parent_node.position + offset
		else:
			# Regular node
			node.position.y += scroll_speed * delta

		node_data.position = node.position


func _find_node_data(node_id: String) -> Dictionary:
	"""Find node data by ID"""
	for node_data in active_nodes:
		if node_data.node_id == node_id:
			return node_data
	return {}


func _check_node_despawn() -> void:
	"""Remove nodes below threshold"""
	var to_remove = []

	for i in range(active_nodes.size() - 1, -1, -1):
		var node_data = active_nodes[i]

		# Skip if node reference is invalid or already freed
		if not node_data.has("node_ref") or not is_instance_valid(node_data.node_ref):
			to_remove.append(i)
			continue

		var node = node_data.node_ref as Area2D
		if node and node.position.y > DESPAWN_Y_THRESHOLD:
			to_remove.append(i)

	for index in to_remove:
		var node_data = active_nodes[index]

		# Validate before emitting signal and freeing
		if node_data.has("node_ref") and is_instance_valid(node_data.node_ref):
			var node = node_data.node_ref as Area2D
			EventBus.node_despawned.emit(node_data.node_id)

			if node:
				node.queue_free()

		active_nodes.remove_at(index)


func remove_node(node_id: String) -> void:
	"""Remove a node from tracking (called when node is collected/destroyed externally)"""
	for i in range(active_nodes.size() - 1, -1, -1):
		var node_data = active_nodes[i]
		if node_data.node_id == node_id:
			active_nodes.remove_at(i)
			print("[NodeSpawner] Removed node from tracking: %s" % node_id)
			return


func get_active_nodes() -> Array[Dictionary]:
	"""Get array of active nodes"""
	return active_nodes
