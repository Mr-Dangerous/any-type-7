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

# Boost system
var is_boosting: bool = false
var base_speed_before_boost: float = 0.0
var boost_input_detected: bool = false      # Track if W key or forward swipe active
const BOOST_SPEED_INCREASE: float = 2.0     # +2.0x speed when boosting
const BOOST_FUEL_PER_SECOND: float = 1.0    # Fuel consumption rate
const BOOST_ACCELERATION: float = 4.0       # How fast we accelerate to boost speed (per second)
const BOOST_DECELERATION: float = 3.0       # How fast we decelerate from boost (per second)

# Heavy momentum physics constants
const BASE_ACCELERATION: float = 400.0      # Base lateral acceleration (px/s²)
const VELOCITY_DAMPING: float = 0.96        # Exponential decay per frame (8% loss)
const AUTO_CENTER_FORCE: float = 0.3        # Spring force toward center (reduced for edge access)
const MAX_LATERAL_VELOCITY: float = 400.0   # Speed cap
const MAX_TILT_ANGLE: float = 35.0          # Visual tilt in degrees

# Bow swing rotation animation constants
const ROTATION_OVERSHOOT_MULTIPLIER: float = 2.0  # How much extra rotation during direction change (2.5x = 150% overshoot)
const ROTATION_SPRING_STIFFNESS: float = 12.0      # How fast rotation snaps back to target (higher = faster)
const ROTATION_DAMPING: float = 0.85              # Damping for rotation velocity (lower = more oscillation)

# Direction change resistance (bow swing feel)
var ship_responsiveness: float = 1.0 # 0.0 = instant response, 1.0 = maximum resistance (modifiable by relics)
const MIN_RESPONSIVENESS: float = 0.0  # No resistance (instant direction change)
const MAX_RESPONSIVENESS: float = 1.0  # Maximum resistance (heavy sluggish feel)

# Bow swing rotation animation variables
var current_rotation_angle: float = 0.0        # Current visual tilt angle (independent of velocity)
var rotation_velocity: float = 0.0             # Angular velocity for spring physics
var target_rotation_angle: float = 0.0         # Target angle based on velocity
var last_velocity_sign: float = 0.0            # Track direction changes for overshoot detection

# Input tracking
var swipe_start_pos: Vector2 = Vector2.ZERO
var is_swiping: bool = false
var swipe_direction: float = 0.0  # -1 (left) to +1 (right)

# Gravity assist system
var control_locked: bool = false
var control_locking_node_id: String = ""  # Node that is locking control
var control_lock_timer: float = 0.0  # Dynamic timer based on multiplier
const LOCKOUT_TIME_PER_MULTIPLIER: float = 5.0  # 0.5 seconds per 0.1 multiplier (0.1 * 5.0 = 0.5s)

# Jump system
enum JumpState { IDLE, CHARGING, ANIMATING, COOLDOWN }
var jump_state: JumpState = JumpState.IDLE
var jump_charge_time: float = 0.0
var jump_cooldown_timer: float = 0.0
var jump_target_position: float = 0.0
var jump_animation_timer: float = 0.0
var speed_before_jump: float = 0.0
var jump_direction_locked: bool = false  # true = jump right, false = jump left
# Note: jump_indicator removed - now using global IndicatorManager

const JUMP_START_FUEL_COST: int = 3
const JUMP_FUEL_PER_SECOND: int = 1
const JUMP_MIN_DISTANCE: float = 100.0
const JUMP_BASE_DISTANCE: float = 200.0  # Distance at 1 second (deprecated)
const JUMP_DISTANCE_PER_SECOND: float = 200.0  # Indicator moves 200px per second
const JUMP_ANIMATION_DURATION: float = 0.5
const JUMP_COOLDOWN_DURATION: float = 10.0
const JUMP_INDICATOR_SHOW_DELAY: float = 0.5
const SCREEN_CENTER: float = 540.0

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

# Orbiterable nodes cache (nodes with orbit=TRUE)
var orbiterable_nodes: Array[Dictionary] = []


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

	# Note: Jump indicator now managed by global IndicatorManager (no local creation needed)

	print("Sector Map initialized - Use A/D keys or swipe to move ship, SPACE to jump")


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

	# Boost control (W key or forward swipe)
	if event is InputEventKey and event.keycode == KEY_W:
		if event.pressed:
			boost_input_detected = true
		else:
			boost_input_detected = false

	# Manual speed control with S key (for testing/debugging)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_S:
			current_speed_multiplier -= 0.1
			current_speed_multiplier = max(0.1, current_speed_multiplier)
			print("[Speed] S pressed - Speed: %.1fx" % current_speed_multiplier)

	# Jump system (SPACE key)
	if event is InputEventKey and event.keycode == KEY_SPACE:
		if event.pressed and not event.echo:
			_start_jump_charge()
		elif not event.pressed:
			_release_jump()


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

	# === BOOST SYSTEM ===

	# Process boost
	_process_boost(delta)

	# === JUMP SYSTEM ===

	# Process jump states
	_process_jump(delta)

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

	# 1. Apply acceleration from input (with direction change resistance)
	var target_accel = BASE_ACCELERATION * swipe_direction

	# Apply direction change penalty (bow swing feel)
	if swipe_direction != 0:
		# Check if input opposes current velocity (direction change)
		var velocity_sign = sign(player_lateral_velocity)
		var input_sign = sign(swipe_direction)

		if velocity_sign != 0 and velocity_sign != input_sign:
			# Changing direction - apply velocity damping + reduced acceleration
			# This creates "bow swing" feel while maintaining responsiveness

			# Apply extra damping when fighting against momentum
			var direction_change_damping = 0.85  # Additional 15% velocity loss when reversing
			player_lateral_velocity *= direction_change_damping

			# Scale acceleration based on responsiveness (clamped to prevent total lockout)
			# Higher responsiveness = slower direction change, but always some response
			var resistance_factor = lerp(1.0, 0.3, ship_responsiveness)  # 30% minimum acceleration
			target_accel *= resistance_factor

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

	# 8. Apply visual tilt with bow swing physics (overshoot + spring-back)
	_update_bow_swing_rotation(delta)


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


func _update_bow_swing_rotation(delta: float) -> void:
	"""
	Enhanced rotation animation with overshoot and spring-back physics.
	Creates a dynamic "bow swing" effect where the ship overshoots when changing
	direction, then smoothly springs back to align with actual travel direction.

	Physics model:
	1. Calculate target rotation based on lateral velocity
	2. Detect direction changes and apply overshoot multiplier
	3. Use damped spring physics to smoothly approach target angle
	4. Apply rotation to ship sprite
	"""

	# Calculate base target angle from velocity (normal 1:1 relationship)
	var velocity_based_angle = (player_lateral_velocity / MAX_LATERAL_VELOCITY) * MAX_TILT_ANGLE

	# Detect direction change for overshoot effect
	var current_velocity_sign = sign(player_lateral_velocity)
	var is_direction_changing = false

	# Direction change occurs when:
	# 1. Velocity sign changed (crossing zero)
	# 2. Both old and new signs are non-zero (not just starting to move)
	if last_velocity_sign != 0.0 and current_velocity_sign != 0.0:
		if last_velocity_sign != current_velocity_sign:
			is_direction_changing = true

	# Update target angle with overshoot on direction change
	if is_direction_changing:
		# Apply overshoot: push target angle BEYOND velocity-based angle
		# This creates the visual "swing out" when changing direction
		target_rotation_angle = velocity_based_angle * ROTATION_OVERSHOOT_MULTIPLIER

		# Also give rotation velocity a kick to make overshoot more pronounced
		# The kick direction matches the new direction
		var overshoot_kick = sign(velocity_based_angle) * MAX_TILT_ANGLE * 2.0
		rotation_velocity += overshoot_kick
	else:
		# Normal operation: target angle matches velocity
		target_rotation_angle = velocity_based_angle

	# Store current velocity sign for next frame's direction change detection
	last_velocity_sign = current_velocity_sign

	# === DAMPED SPRING PHYSICS ===
	# Spring force pulls rotation toward target angle
	var angle_error = target_rotation_angle - current_rotation_angle
	var spring_force = angle_error * ROTATION_SPRING_STIFFNESS

	# Apply spring force to rotation velocity
	rotation_velocity += spring_force * delta

	# Apply damping to rotation velocity (prevents endless oscillation)
	rotation_velocity *= ROTATION_DAMPING

	# Update current rotation angle based on velocity
	current_rotation_angle += rotation_velocity * delta

	# Clamp rotation to reasonable bounds (prevent wild spins)
	# Allow overshoot beyond MAX_TILT_ANGLE, but cap at 3x for safety
	var max_overshoot = MAX_TILT_ANGLE * 3.0
	current_rotation_angle = clamp(current_rotation_angle, -max_overshoot, max_overshoot)

	# Apply rotation to ship sprite
	player_ship.rotation_degrees = -90 + current_rotation_angle  # -90 is base upward rotation


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
	var all_nodes = DataManager.get_spawnable_nodes()
	spawnable_nodes.clear()
	orbiterable_nodes.clear()
	total_spawn_weight = 0

	for node_data in all_nodes:
		var spawn_case = node_data.get("spawn_case", "").strip_edges()
		var can_orbit = node_data.get("orbit", false)

		# Filter out "special" spawn case nodes from regular spawning
		if spawn_case != "special":
			spawnable_nodes.append(node_data)
			total_spawn_weight += int(node_data.get("spawn_weight", 0))

		# Cache orbiterable nodes (orbit=TRUE)
		if can_orbit:
			orbiterable_nodes.append(node_data)

	print("[SectorMap] Loaded %d spawnable node types (total weight: %d)" % [spawnable_nodes.size(), total_spawn_weight])
	print("[SectorMap] Found %d orbiterable node types" % orbiterable_nodes.size())


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


func _select_random_orbiterable_node() -> Dictionary:
	"""Select a random node type that can orbit (orbit=TRUE)"""
	if orbiterable_nodes.is_empty():
		return {}

	# Random selection from orbiterable nodes (equal weight for all)
	var index = randi() % orbiterable_nodes.size()
	return orbiterable_nodes[index]


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
			"is_activated": false,
			"spawn_position_type": pos_type  # Track left/right/center
		}
		active_nodes.append(tracking_data)

		# Emit signal
		EventBus.node_spawned.emit(node_id, node_type, spawn_pos)

		print("[Spawn] %s at %s (distance: %.1f)" % [node_id, spawn_pos, scroll_distance])

		# Check if this node can have orbiters
		_check_and_spawn_orbiters(node_id, node, csv_node_data, spawn_pos, pos_type)


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
	"""Move all active nodes downward at scroll speed and handle orbital motion"""
	for node_data in active_nodes:
		var node = node_data.node_ref as Area2D
		if not node:
			continue

		# Check if this is an orbiting node
		if node_data.get("is_orbiter", false):
			# Find parent node
			var parent_id = node_data.get("parent_id", "")
			var parent_data = _find_node_data(parent_id)

			if parent_data.is_empty():
				# Parent despawned, treat as regular node
				node.position.y += current_scroll_speed * delta
			else:
				# Update orbit angle (rotate around parent) - use per-orbiter speed
				var orbit_speed = node_data.get("orbit_speed", 0.3)  # Use stored speed
				node_data.orbit_angle += orbit_speed * delta

				# Calculate new position relative to parent
				var parent_node = parent_data.node_ref as Area2D
				if parent_node:
					var orbit_radius = node_data.get("orbit_radius", 100.0)
					var angle = node_data.orbit_angle
					var offset = Vector2(
						cos(angle - PI/2) * orbit_radius,
						sin(angle - PI/2) * orbit_radius
					)
					node.position = parent_node.position + offset

		else:
			# Regular node: move downward
			node.position.y += current_scroll_speed * delta

		# Update tracked position
		node_data.position = node.position


func _find_node_data(node_id: String) -> Dictionary:
	"""Find node data by ID in active_nodes array"""
	for node_data in active_nodes:
		if node_data.node_id == node_id:
			return node_data
	return {}


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


func _check_and_spawn_orbiters(parent_id: String, parent_node: Area2D, parent_csv_data: Dictionary, parent_pos: Vector2, parent_spawn_pos: String) -> void:
	"""Check if node can have orbiters and spawn them if conditions are met"""
	# Check if this node type can have orbiters
	var can_have_orbiters = parent_csv_data.get("can_have_orbiters", false)
	if not can_have_orbiters:
		return

	# Get moon chance and max orbiters
	var moon_chance = float(parent_csv_data.get("moon_chance", 0))
	var max_orbiters = int(parent_csv_data.get("max_moons", 0))

	if moon_chance <= 0 or max_orbiters <= 0:
		return

	# Roll for moon spawn
	var roll = randf() * 100.0
	if roll >= moon_chance:
		return  # No moon this time

	# Determine how many orbiters to spawn (1 to max_orbiters)
	var num_orbiters = randi_range(1, max_orbiters)

	# Calculate orbit radius for visualization
	var parent_radius = float(parent_csv_data.get("size", 100)) / 2.0
	var orbit_radius = parent_radius + 100.0

	# Mark parent node as having orbiters (for orbit path visualization)
	parent_node.set_has_orbiters(orbit_radius)

	# Spawn each orbiter
	for i in range(num_orbiters):
		_spawn_orbiter(parent_id, parent_node, parent_csv_data, parent_pos, i, num_orbiters, orbit_radius, parent_spawn_pos)


func _spawn_orbiter(parent_id: String, parent_node: Area2D, parent_csv_data: Dictionary, parent_pos: Vector2, index: int, total_orbiters: int, orbit_radius: float, parent_spawn_pos: String) -> void:
	"""Spawn an orbiting node around the parent node"""
	# Select random orbiterable node type (any node with orbit=TRUE)
	var orbiter_csv_data = _select_random_orbiterable_node()
	if orbiter_csv_data.is_empty():
		print("[Orbiter] Warning: no orbiterable nodes available")
		return

	var orbiter_type = orbiter_csv_data.get("node_type", "unknown")

	# Calculate initial angle based on parent spawn position
	var angle_range_start: float
	var angle_range_end: float

	if parent_spawn_pos == "right":
		# Right side nodes: spawn at 5:00 position (150°)
		# Use a narrow range around 5:00 for multiple orbiters
		angle_range_start = deg_to_rad(140.0)  # Slightly before 5:00
		angle_range_end = deg_to_rad(160.0)    # Slightly after 5:00
	else:
		# Left/center nodes: 12-2 o'clock range (0° to 60°)
		angle_range_start = 0.0  # 12 o'clock (top)
		angle_range_end = PI / 3.0  # 60° (2 o'clock)

	var angle_step = (angle_range_end - angle_range_start) / max(total_orbiters, 1)
	var initial_angle = angle_range_start + (angle_step * index)

	# Generate random orbital speed (0.2 to 0.6 radians/sec = 3x factor)
	var min_orbit_speed = 0.2
	var max_orbit_speed = 0.6  # 3x faster than min
	var orbit_speed = randf_range(min_orbit_speed, max_orbit_speed)

	# Calculate orbiter spawn position relative to parent
	var offset = Vector2(
		cos(initial_angle - PI/2) * orbit_radius,  # -PI/2 to rotate coordinate system (0° = top)
		sin(initial_angle - PI/2) * orbit_radius
	)
	var orbiter_pos = parent_pos + offset

	# Create orbiter node instance
	var orbiter_node = test_node_scene.instantiate()

	# Generate unique ID
	var orbiter_id = "%s_%d" % [orbiter_type, next_node_id]
	next_node_id += 1

	# Set up orbiter with CSV data
	orbiter_node.setup(orbiter_id, orbiter_type, orbiter_csv_data, scroll_distance)
	orbiter_node.position = orbiter_pos

	# Configure orbit parameters
	orbiter_node.setup_orbit(parent_id, orbit_radius, initial_angle)

	# Add to scene
	$WorldContainer.add_child(orbiter_node)

	# Track in active nodes array
	var tracking_data = {
		"node_id": orbiter_id,
		"node_ref": orbiter_node,
		"position": orbiter_pos,
		"spawn_distance": scroll_distance,
		"node_type": orbiter_type,
		"csv_data": orbiter_csv_data,
		"is_activated": false,
		"is_orbiter": true,
		"parent_id": parent_id,
		"orbit_radius": orbit_radius,
		"orbit_angle": initial_angle,
		"orbit_speed": orbit_speed  # Store individual orbit speed
	}
	active_nodes.append(tracking_data)

	# Emit signal
	EventBus.node_spawned.emit(orbiter_id, orbiter_type, orbiter_pos)

	print("[Orbiter] Spawned %s (%s) orbiting %s at radius %.1fpx, angle %.1f°, speed %.2f rad/s" % [orbiter_id, orbiter_type, parent_id, orbit_radius, rad_to_deg(initial_angle), orbit_speed])


# ============================================================
# JUMP SYSTEM
# ============================================================
# Note: _create_jump_indicator() removed - now using global IndicatorManager


func _start_jump_charge() -> void:
	"""Start charging a jump"""
	# Can only start if idle and not on cooldown
	if jump_state != JumpState.IDLE:
		return

	# Check fuel for initial cost
	if ResourceManager.get_resource("fuel") < JUMP_START_FUEL_COST:
		print("[Jump] Not enough fuel to start jump (need %d)" % JUMP_START_FUEL_COST)
		return

	# Spend initial fuel
	if not ResourceManager.spend_resources({"fuel": JUMP_START_FUEL_COST}, "jump_start"):
		return

	# Start charging
	jump_state = JumpState.CHARGING
	jump_charge_time = 0.0
	# Note: Controls NOT locked during charge - player can still move laterally

	# Lock jump direction based on current position (won't change if player crosses center)
	if player_lateral_position < SCREEN_CENTER:
		jump_direction_locked = true  # Jump right
	elif player_lateral_position > SCREEN_CENTER:
		jump_direction_locked = false  # Jump left
	else:
		jump_direction_locked = false  # Default to left at exact center

	var direction_name = "RIGHT" if jump_direction_locked else "LEFT"
	print("[Jump] Jump charging started - Direction locked: %s - Initial fuel cost: %d" % [direction_name, JUMP_START_FUEL_COST])


func _release_jump() -> void:
	"""Release the jump and execute it"""
	if jump_state != JumpState.CHARGING:
		return

	# Calculate final jump target using locked direction
	var jump_distance = _calculate_jump_distance()
	jump_target_position = _calculate_jump_target(jump_distance, jump_direction_locked)

	# Start jump animation
	jump_state = JumpState.ANIMATING
	jump_animation_timer = 0.0
	speed_before_jump = current_speed_multiplier
	current_speed_multiplier = 0.0  # Stop scrolling
	control_locked = true  # Lock controls during animation

	# Hide indicator (using global IndicatorManager)
	IndicatorManager.hide_jump_indicator()

	print("[Jump] Jump released - Distance: %.1fpx, Target: %.1fpx" % [jump_distance, jump_target_position])


func _process_jump(delta: float) -> void:
	"""Process jump state machine"""
	match jump_state:
		JumpState.IDLE:
			# Update cooldown timer
			if jump_cooldown_timer > 0.0:
				jump_cooldown_timer -= delta
				if jump_cooldown_timer <= 0.0:
					print("[Jump] Cooldown complete - Jump ready")

		JumpState.CHARGING:
			# Update charge time
			jump_charge_time += delta

			# Consume fuel per second
			var fuel_cost_this_frame = JUMP_FUEL_PER_SECOND * delta
			var current_fuel = ResourceManager.get_resource("fuel")

			if current_fuel <= 0:
				# Out of fuel, cancel jump
				print("[Jump] Out of fuel - Jump cancelled")
				_cancel_jump()
				return

			# Spend fuel (try to spend, if not enough, spend what's left)
			var fuel_to_spend = min(fuel_cost_this_frame, current_fuel)
			ResourceManager.spend_resources({"fuel": fuel_to_spend}, "jump_charge")

			# Update jump indicator
			_update_jump_indicator()

		JumpState.ANIMATING:
			# Update animation timer
			jump_animation_timer += delta

			# Rotate ship 360 degrees over JUMP_ANIMATION_DURATION
			var rotation_progress = jump_animation_timer / JUMP_ANIMATION_DURATION
			player_ship.rotation_degrees = -90 + (rotation_progress * 360.0)

			if jump_animation_timer >= JUMP_ANIMATION_DURATION:
				# Animation complete, execute jump
				_execute_jump()

		JumpState.COOLDOWN:
			# Cooldown is handled in IDLE state
			pass


func _calculate_jump_distance() -> float:
	"""Calculate jump distance based on charge time"""
	# 0s = 100px, 1s = 200px, 2s = 300px, etc.
	var distance = JUMP_MIN_DISTANCE + (jump_charge_time * JUMP_DISTANCE_PER_SECOND)
	return distance


func _calculate_jump_target(distance: float, jump_right: bool) -> float:
	"""Calculate target position based on current position, distance, and locked direction"""
	var current_pos = player_lateral_position

	# Calculate target position using locked direction
	var target_pos: float
	if jump_right:
		target_pos = current_pos + distance
	else:
		target_pos = current_pos - distance

	# Clamp to screen bounds
	target_pos = clamp(target_pos, 30.0, 1050.0)

	return target_pos


func _update_jump_indicator() -> void:
	"""Update the visual jump indicator position using global IndicatorManager"""
	# Show indicator after delay
	if jump_charge_time >= JUMP_INDICATOR_SHOW_DELAY:
		# Calculate current jump target using locked direction
		var jump_distance = _calculate_jump_distance()
		var target_pos = _calculate_jump_target(jump_distance, jump_direction_locked)

		# Update indicator position (using global IndicatorManager)
		IndicatorManager.show_jump_indicator(Vector2(target_pos, PLAYER_Y_POSITION))
	else:
		# Hide indicator during initial charge delay
		IndicatorManager.hide_jump_indicator()


func _execute_jump() -> void:
	"""Execute the jump - teleport to target position"""
	# Move player to target position
	player_lateral_position = jump_target_position
	player_ship.position = Vector2(jump_target_position, PLAYER_Y_POSITION)

	# Reset ship rotation and rotation animation variables
	player_ship.rotation_degrees = -90
	current_rotation_angle = 0.0
	rotation_velocity = 0.0
	target_rotation_angle = 0.0
	last_velocity_sign = 0.0

	# Restore speed
	current_speed_multiplier = speed_before_jump

	# Start cooldown
	jump_state = JumpState.COOLDOWN
	jump_cooldown_timer = JUMP_COOLDOWN_DURATION

	# Unlock controls
	control_locked = false

	print("[Jump] Jump executed - New position: %.1fpx, cooldown started" % jump_target_position)

	# After cooldown, return to IDLE
	await get_tree().create_timer(0.1).timeout
	jump_state = JumpState.IDLE


func _cancel_jump() -> void:
	"""Cancel jump (out of fuel)"""
	jump_state = JumpState.IDLE
	jump_charge_time = 0.0
	IndicatorManager.hide_jump_indicator()  # Using global IndicatorManager
	control_locked = false


# ============================================================
# BOOST SYSTEM
# ============================================================

func _process_boost(delta: float) -> void:
	"""Process boost activation, fuel consumption, and speed changes"""
	# Check if boost should be active
	var should_boost = boost_input_detected and ResourceManager.get_resource("fuel") > 0

	# Start boost
	if should_boost and not is_boosting:
		_start_boost()

	# End boost
	elif not should_boost and is_boosting:
		_end_boost()

	# Process active boost
	if is_boosting:
		# Consume fuel
		var fuel_cost = BOOST_FUEL_PER_SECOND * delta
		var current_fuel = ResourceManager.get_resource("fuel")

		if current_fuel <= 0:
			# Out of fuel, cancel boost
			print("[Boost] Out of fuel - Boost cancelled")
			_end_boost()
			return

		# Spend fuel
		ResourceManager.spend_resources({"fuel": fuel_cost}, "boost")

		# Accelerate to boosted speed
		var target_speed = base_speed_before_boost + BOOST_SPEED_INCREASE
		if current_speed_multiplier < target_speed:
			current_speed_multiplier += BOOST_ACCELERATION * delta
			current_speed_multiplier = min(current_speed_multiplier, target_speed)

	# Process boost deceleration (when boost ended)
	elif base_speed_before_boost > 0.0:
		# Decelerate back to base speed
		if current_speed_multiplier > base_speed_before_boost:
			current_speed_multiplier -= BOOST_DECELERATION * delta
			current_speed_multiplier = max(current_speed_multiplier, base_speed_before_boost)

		# Reset once we've reached base speed
		if abs(current_speed_multiplier - base_speed_before_boost) < 0.01:
			base_speed_before_boost = 0.0


func _start_boost() -> void:
	"""Start boost"""
	is_boosting = true
	base_speed_before_boost = current_speed_multiplier
	print("[Boost] Boost started - Base speed: %.1fx, Target: %.1fx" % [base_speed_before_boost, base_speed_before_boost + BOOST_SPEED_INCREASE])


func _end_boost() -> void:
	"""End boost"""
	is_boosting = false
	print("[Boost] Boost ended - Decelerating from %.1fx to %.1fx" % [current_speed_multiplier, base_speed_before_boost])
