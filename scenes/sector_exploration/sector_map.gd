extends Control

# Node references
@onready var player_ship = $WorldContainer/PlayerShip
@onready var grid_tiles = [$WorldContainer/GridTile1, $WorldContainer/GridTile2, $WorldContainer/GridTile3]
@onready var distance_label = $UIOverlay/DistanceLabel
@onready var node_popup = $UIOverlay/NodePopup

# Resource display labels
@onready var fuel_label = $UIOverlay/ResourceDisplay/HBoxContainer/FuelPanel/VBoxContainer/ValueLabel
@onready var metal_label = $UIOverlay/ResourceDisplay/HBoxContainer/MetalPanel/VBoxContainer/ValueLabel
@onready var crystals_label = $UIOverlay/ResourceDisplay/HBoxContainer/CrystalsPanel/VBoxContainer/ValueLabel
@onready var speed_label = $UIOverlay/ResourceDisplay/HBoxContainer/SpeedPanel/VBoxContainer/ValueLabel

# Player position and physics
var player_lateral_position: float = 540.0  # X position (0-1080)
var player_lateral_velocity: float = 0.0    # X velocity (px/s)
const PLAYER_Y_POSITION: float = 1950.0     # Fixed Y position

# Scrolling system
var scroll_distance: float = 0.0            # Total distance traveled
var base_scroll_speed: float = 100.0        # Base forward speed (px/s)
var current_speed_multiplier: float = 2.0   # Speed modifier (default 2.0x)
var current_scroll_speed: float = 200.0     # Actual scroll speed
const TILE_HEIGHT: float = 2340.0           # Height of each grid tile

# Heavy momentum physics constants
const BASE_ACCELERATION: float = 800.0      # Base lateral acceleration (px/s²)
const VELOCITY_DAMPING: float = 0.92        # Exponential decay per frame (8% loss)
const AUTO_CENTER_FORCE: float = 0.2        # Spring force toward center (reduced for edge access)
const MAX_LATERAL_VELOCITY: float = 400.0   # Speed cap
const MAX_TILT_ANGLE: float = 15.0          # Visual tilt in degrees

# Input tracking
var swipe_start_pos: Vector2 = Vector2.ZERO
var is_swiping: bool = false
var swipe_direction: float = 0.0  # -1 (left) to +1 (right)

# Gravity assist system
var control_locked: bool = false
var control_locking_node_id: String = ""  # Node that is locking control
var control_lock_timer: float = 0.0  # Dynamic timer based on multiplier
const LOCKOUT_TIME_PER_MULTIPLIER: float = 5.0  # 0.5 seconds per 0.1 multiplier (0.1 * 5.0 = 0.5s)

# Node spawning system
var active_nodes: Array[Dictionary] = []
var next_node_id: int = 0
var last_spawn_distance: float = 0.0

const SPAWN_INTERVAL: float = 800.0  # Spawn every 800px
const SPAWN_Y_OFFSET: float = -500.0  # Spawn above screen
const DESPAWN_Y_THRESHOLD: float = 2500.0  # Despawn below screen

# Spawn positions: left/right are near edges but mostly visible
const SPAWN_POS_LEFT: float = 30.0  # Near left edge, mostly visible
const SPAWN_POS_RIGHT: float = 1050.0  # Near right edge, mostly visible
# Center spawn range (avoid edges, keep 150px margin from edges)
const SPAWN_CENTER_MIN: float = 150.0
const SPAWN_CENTER_MAX: float = 930.0

# Preloaded scenes
var test_node_scene = preload("res://scenes/sector_exploration/test_node.tscn")

# Spawnable node cache (loaded from CSV)
var spawnable_nodes: Array[Dictionary] = []
var total_spawn_weight: int = 0


func _ready() -> void:
	# Load spawnable nodes from CSV
	_load_spawnable_nodes()

	# Initialize player ship position
	player_ship.position = Vector2(player_lateral_position, PLAYER_Y_POSITION)

	# Initialize grid tiles for infinite scrolling (3-tile system)
	grid_tiles[0].position.y = 0.0          # Tile 1: on screen
	grid_tiles[1].position.y = -2340.0      # Tile 2: above screen
	grid_tiles[2].position.y = -4680.0      # Tile 3: further above

	# Update distance display
	_update_distance_display()

	# Update resource displays
	_update_resource_display()

	# Connect to EventBus signals
	EventBus.node_proximity_entered.connect(_on_node_proximity_entered)
	EventBus.node_proximity_exited.connect(_on_node_proximity_exited)
	EventBus.node_activated.connect(_on_node_activated)
	EventBus.gravity_assist_applied.connect(_on_gravity_assist_applied)

	print("Sector Map initialized - Use A/D keys or swipe to move ship")


func _input(event: InputEvent) -> void:
	# Touch/mouse swipe detection
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			swipe_start_pos = event.position
			is_swiping = true
		else:
			is_swiping = false
			swipe_direction = 0.0  # Release stops input

	if event is InputEventScreenDrag or (event is InputEventMouseMotion and is_swiping):
		var current_pos = event.position
		var swipe_delta = current_pos.x - swipe_start_pos.x

		# Normalize to -1 to +1
		swipe_direction = clamp(swipe_delta / 200.0, -1.0, 1.0)

	# Speed control keys (W = faster, S = slower)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_W:
			current_speed_multiplier += 0.1
			print("[Speed] W pressed - Speed: %.1fx" % current_speed_multiplier)
		elif event.keycode == KEY_S:
			current_speed_multiplier -= 0.1
			current_speed_multiplier = max(0.1, current_speed_multiplier)  # Don't go below 0.1x
			print("[Speed] S pressed - Speed: %.1fx" % current_speed_multiplier)


func _process(delta: float) -> void:
	# === SCROLLING SYSTEM ===

	# Update scroll distance and speed
	current_scroll_speed = base_scroll_speed * current_speed_multiplier
	scroll_distance += current_scroll_speed * delta

	# Scroll all grid tiles downward
	for tile in grid_tiles:
		tile.position.y += current_scroll_speed * delta

		# Wrap tile to top when it goes off bottom (infinite scrolling)
		if tile.position.y > TILE_HEIGHT:
			tile.position.y -= TILE_HEIGHT * 3

	# Update distance display every frame
	_update_distance_display()

	# Update resource displays every frame (especially speed multiplier)
	_update_resource_display()

	# === NODE SPAWNING SYSTEM ===

	# Check if we should spawn new nodes
	_check_node_spawn()

	# Update node positions (scroll downward with grid)
	_update_node_positions(delta)

	# Check for nodes to despawn
	_check_node_despawn()

	# === GRAVITY ASSIST FAILSAFE ===

	# Update control lock failsafe timer
	if control_locked and control_lock_timer > 0.0:
		control_lock_timer -= delta
		if control_lock_timer <= 0.0:
			control_locked = false
			control_locking_node_id = ""
			print("[SectorMap] Lockout timer expired - Control unlocked")

	# === PLAYER LATERAL MOVEMENT ===

	# WASD input for testing (overrides swipe if keys pressed)
	# Only process input if control is not locked
	if not control_locked:
		if Input.is_key_pressed(KEY_A):
			swipe_direction = -1.0
		elif Input.is_key_pressed(KEY_D):
			swipe_direction = 1.0
		elif not is_swiping:
			swipe_direction = 0.0

	# === HEAVY MOMENTUM PHYSICS ===

	# 1. Apply acceleration from input
	var target_accel = BASE_ACCELERATION * swipe_direction
	player_lateral_velocity += target_accel * delta

	# 2. Apply exponential damping (creates drift feel)
	player_lateral_velocity *= VELOCITY_DAMPING

	# 3. Apply auto-centering spring force (pulls toward center)
	var center_offset = 540.0 - player_lateral_position
	var center_force = center_offset * AUTO_CENTER_FORCE
	player_lateral_velocity += center_force * delta

	# 4. Cap velocity
	player_lateral_velocity = clamp(
		player_lateral_velocity,
		-MAX_LATERAL_VELOCITY,
		MAX_LATERAL_VELOCITY
	)

	# 5. Update position
	player_lateral_position += player_lateral_velocity * delta

	# 6. Keep in bounds (0-1080 with margins matching node spawn positions)
	player_lateral_position = clamp(player_lateral_position, 30.0, 1050.0)

	# 7. Update ship visual position
	player_ship.position = Vector2(player_lateral_position, PLAYER_Y_POSITION)

	# 8. Apply visual tilt (ship leans toward movement)
	var tilt_angle = (player_lateral_velocity / MAX_LATERAL_VELOCITY) * MAX_TILT_ANGLE
	player_ship.rotation_degrees = -90 + tilt_angle  # -90 is base upward rotation


func _update_distance_display() -> void:
	# Update distance label (format: 1234 px or 1.2 km)
	if scroll_distance < 1000:
		distance_label.text = "Distance: %d px" % int(scroll_distance)
	else:
		distance_label.text = "Distance: %.1f km" % (scroll_distance / 1000.0)


func _update_resource_display() -> void:
	"""Update resource display labels with current values"""
	# For now, show placeholder values until ResourceManager is implemented
	# TODO: Replace with actual ResourceManager.get_resource() calls
	fuel_label.text = "100"  # Placeholder
	metal_label.text = "0"   # Placeholder
	crystals_label.text = "0"  # Placeholder

	# Speed multiplier is already tracked in this script
	speed_label.text = "%.1fx" % current_speed_multiplier


func _on_node_proximity_entered(node_id: String, node_type: String) -> void:
	"""Handle when player enters a node's proximity zone"""
	# Don't show popup if already visible (prevent stack overflow)
	if node_popup.visible:
		return

	# Find node data
	var node_position = Vector2.ZERO
	var has_gravity = false
	var gravity_multiplier = 0.0
	for node_data in active_nodes:
		if node_data.node_id == node_id:
			node_position = node_data.position
			var csv_data = node_data.get("csv_data", {})
			has_gravity = csv_data.get("gravity_assist", "no") == "yes"
			if has_gravity:
				gravity_multiplier = float(csv_data.get("gravity_assist_multiplier", 0.0))
			break

	# Show the popup with node position, gravity flag, and multiplier
	node_popup.show_popup(node_id, node_type, node_position, has_gravity, gravity_multiplier)

	print("[SectorMap] Player entered proximity of %s (%s) - Gravity: %s (%.1fx)" % [node_id, node_type, has_gravity, gravity_multiplier])


func _on_node_proximity_exited(node_id: String) -> void:
	"""Handle when player exits a node's proximity zone"""
	# Unlock control if this is the node that locked it
	if control_locked and control_locking_node_id == node_id:
		control_locked = false
		control_locking_node_id = ""
		print("[SectorMap] Exited proximity of %s - Control unlocked" % node_id)


func _on_node_activated(node_id: String) -> void:
	"""Handle when a node is activated (user clicked Continue)"""
	# Find the node in active_nodes and mark it as activated
	for node_data in active_nodes:
		if node_data.node_id == node_id:
			var node = node_data.node_ref as Area2D
			if node:
				# Mark as activated FIRST to prevent re-triggering
				node.is_activated = true
				node_data.is_activated = true
				# Change visual to green
				node.modulate = Color(0.5, 1.0, 0.5)
			break

	print("[SectorMap] Node %s activated" % node_id)


func _on_gravity_assist_applied(choice: String, node_position: Vector2, multiplier: float) -> void:
	"""Handle gravity assist choice from popup"""
	# Find which node triggered this gravity assist
	var triggering_node_id = ""
	for node_data in active_nodes:
		if node_data.position.distance_to(node_position) < 10.0:  # Close enough match
			triggering_node_id = node_data.node_id
			break

	match choice:
		"faster":
			# Increase speed by multiplier from CSV
			current_speed_multiplier += multiplier

			# Lock control - duration based on multiplier (0.5s per 0.1 multiplier)
			control_locked = true
			control_locking_node_id = triggering_node_id
			control_lock_timer = multiplier * LOCKOUT_TIME_PER_MULTIPLIER

			# Push ship toward node's X position
			var direction_to_node = sign(node_position.x - player_lateral_position)
			player_lateral_velocity += direction_to_node * 200.0  # Impulse toward node

			print("[SectorMap] Gravity Assist: FASTER (+%.1fx) - Speed: %.1fx, Locked for %.1fs" % [multiplier, current_speed_multiplier, control_lock_timer])

		"slower":
			# Decrease speed by multiplier from CSV
			current_speed_multiplier -= multiplier
			current_speed_multiplier = max(0.1, current_speed_multiplier)  # Don't go below 0.1x

			# Lock control - duration based on multiplier (0.5s per 0.1 multiplier)
			control_locked = true
			control_locking_node_id = triggering_node_id
			control_lock_timer = multiplier * LOCKOUT_TIME_PER_MULTIPLIER

			# Push ship away from node's X position
			var direction_from_node = -sign(node_position.x - player_lateral_position)
			player_lateral_velocity += direction_from_node * 200.0  # Impulse away from node

			print("[SectorMap] Gravity Assist: SLOWER (-%.1fx) - Speed: %.1fx, Locked for %.1fs" % [multiplier, current_speed_multiplier, control_lock_timer])

		"same":
			# No speed change, no control lock
			print("[SectorMap] Gravity Assist: SAME - Speed unchanged at %.1fx" % current_speed_multiplier)


# === NODE SPAWNING FUNCTIONS ===

func _load_spawnable_nodes() -> void:
	"""Load spawnable nodes from DataManager and calculate total spawn weight"""
	spawnable_nodes = DataManager.get_spawnable_nodes()
	total_spawn_weight = 0

	for node_data in spawnable_nodes:
		total_spawn_weight += int(node_data.get("spawn_weight", 0))

	print("[SectorMap] Loaded %d spawnable node types (total weight: %d)" % [spawnable_nodes.size(), total_spawn_weight])


func _select_random_node_type() -> Dictionary:
	"""Select a random node type based on spawn weights"""
	if spawnable_nodes.is_empty():
		return {}

	var roll = randi() % total_spawn_weight
	var current_weight = 0

	for node_data in spawnable_nodes:
		current_weight += int(node_data.get("spawn_weight", 0))
		if roll < current_weight:
			return node_data

	# Fallback (shouldn't reach here)
	return spawnable_nodes[0]


func _check_node_spawn() -> void:
	"""Check if we've traveled far enough to spawn next node"""
	if scroll_distance >= last_spawn_distance + SPAWN_INTERVAL:
		_spawn_single_node()
		last_spawn_distance = scroll_distance


func _spawn_single_node() -> void:
	"""Spawn a set of 1-3 nodes from CSV data in different positions"""
	# Randomly spawn 1-3 nodes
	var set_size = randi_range(1, 3)

	# Track used position types to avoid overlap
	var used_position_types = []

	for i in range(set_size):
		# Select random node type from CSV
		var csv_node_data = _select_random_node_type()
		if csv_node_data.is_empty():
			continue

		var node_type = csv_node_data.get("node_type", "unknown")

		# Get valid positions for this node from CSV spawn_case
		var spawn_case = csv_node_data.get("spawn_case", "center").strip_edges()
		var valid_positions = _parse_spawn_case(spawn_case)

		# Filter out used positions
		var available_positions = []
		for pos in valid_positions:
			if pos not in used_position_types:
				available_positions.append(pos)

		if available_positions.is_empty():
			continue  # No valid positions left

		# Pick random valid position
		var pos_type = available_positions[randi() % available_positions.size()]
		used_position_types.append(pos_type)

		# Get actual X coordinate based on position type
		var x_pos: float
		if pos_type == "left":
			x_pos = SPAWN_POS_LEFT
		elif pos_type == "right":
			x_pos = SPAWN_POS_RIGHT
		else:  # center
			x_pos = randf_range(SPAWN_CENTER_MIN, SPAWN_CENTER_MAX)

		# Create spawn position
		var spawn_pos = Vector2(x_pos, SPAWN_Y_OFFSET)

		# Create node instance
		var node = test_node_scene.instantiate()

		# Generate unique ID
		var node_id = "%s_%d" % [node_type, next_node_id]
		next_node_id += 1

		# Set up node with CSV data
		node.setup(node_id, node_type, csv_node_data, scroll_distance)
		node.position = spawn_pos

		# Add to scene (as child of WorldContainer)
		$WorldContainer.add_child(node)

		# Track in active nodes array
		var tracking_data = {
			"node_id": node_id,
			"node_ref": node,
			"position": spawn_pos,
			"spawn_distance": scroll_distance,
			"node_type": node_type,
			"csv_data": csv_node_data,
			"is_activated": false
		}
		active_nodes.append(tracking_data)

		# Emit signal
		EventBus.node_spawned.emit(node_id, node_type, spawn_pos)

		print("[Spawn] %s at %s (distance: %.1f)" % [node_id, spawn_pos, scroll_distance])


func _parse_spawn_case(spawn_case: String) -> Array:
	"""Parse CSV spawn_case into array of valid positions"""
	if spawn_case == "all":
		return ["left", "center", "right"]
	elif spawn_case == "center":
		return ["center"]
	elif "right" in spawn_case and "left" in spawn_case:
		return ["left", "right"]
	elif "special" in spawn_case:
		# Skip special nodes for now (moons, comets, etc.)
		return ["center"]  # Fallback to center
	else:
		return ["center"]  # Default fallback


func _update_node_positions(delta: float) -> void:
	"""Move all active nodes downward at scroll speed"""
	for node_data in active_nodes:
		var node = node_data.node_ref as Area2D
		if node:
			# Move downward at current scroll speed
			node.position.y += current_scroll_speed * delta
			# Update tracked position
			node_data.position = node.position


func _check_node_despawn() -> void:
	"""Remove nodes that have scrolled off the bottom"""
	# Collect indices to remove (reverse order to preserve indices)
	var to_remove = []

	for i in range(active_nodes.size() - 1, -1, -1):
		var node_data = active_nodes[i]
		var node = node_data.node_ref as Area2D

		# Check if below despawn threshold
		if node and node.position.y > DESPAWN_Y_THRESHOLD:
			to_remove.append(i)

	# Remove nodes
	for index in to_remove:
		var node_data = active_nodes[index]
		var node = node_data.node_ref as Area2D

		# Emit signal
		EventBus.node_despawned.emit(node_data.node_id)

		print("[Despawn] Removed %s at y=%.1f" % [node_data.node_id, node.position.y])

		# Remove from scene
		if node:
			node.queue_free()

		# Remove from tracking
		active_nodes.remove_at(index)
