extends Node

## Player Movement Module
## Handles player ship lateral movement, input, and physics
## SIMPLIFIED - No complex bow swing, momentum overshoot, or resistance

# Player ship reference (set by parent)
var player_ship: Node2D = null

# Position and physics
var player_lateral_position: float = 540.0
var player_lateral_velocity: float = 0.0
const PLAYER_Y_POSITION: float = 1950.0

# Visual rotation (decoupled from actual velocity)
var visual_rotation_angle: float = 0.0  # Current visual tilt angle

# Simple physics constantsa
const BASE_ACCELERATION: float = 800.0
const VELOCITY_DAMPING: float = 0.92
const MAX_LATERAL_VELOCITY: float = 400.0
const MAX_TILT_ANGLE: float = 25.0

# Direction change momentum (makes turns feel less snappy)
const DIRECTION_CHANGE_DECEL: float = 0.78  # Extra deceleration when opposing current velocity (22% per frame)
const DIRECTION_CHANGE_ACCEL_MULT: float = 0.05  # Reduced acceleration when fighting momentum (5% of normal)

# Visual rotation (decoupled from actual movement)
const VISUAL_ROTATION_SPEED: float = 45.0  # Degrees per second rotation speed (slow swing)
const VISUAL_ROTATION_EXAGGERATION: float = 1.25  # 25% more rotation than actual velocity would suggest

# Input tracking
var swipe_start_pos: Vector2 = Vector2.ZERO
var is_swiping: bool = false
var swipe_direction: float = 0.0  # -1 to +1

# Control lock (for gravity, future systems)
var control_locked: bool = false


func _ready() -> void:
	print("[PlayerMovement] Initialized")


func initialize(ship: Node2D) -> void:
	"""Initialize with player ship reference"""
	player_ship = ship
	player_ship.position = Vector2(player_lateral_position, PLAYER_Y_POSITION)
	print("[PlayerMovement] Player ship initialized at x=%.1f" % player_lateral_position)


func handle_input(event: InputEvent) -> void:
	"""Process input events"""
	# Touch/mouse swipe detection
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			swipe_start_pos = event.position
			is_swiping = true
		else:
			is_swiping = false
			swipe_direction = 0.0

	if event is InputEventScreenDrag or (event is InputEventMouseMotion and is_swiping):
		var current_pos = event.position
		var swipe_delta = current_pos.x - swipe_start_pos.x
		swipe_direction = clamp(swipe_delta / 200.0, -1.0, 1.0)


func process_movement(delta: float) -> void:
	"""Update player movement each frame"""
	if control_locked:
		return

	# WASD input (for testing, overrides swipe)
	if Input.is_key_pressed(KEY_A):
		swipe_direction = -1.0
	elif Input.is_key_pressed(KEY_D):
		swipe_direction = 1.0
	elif not is_swiping:
		swipe_direction = 0.0

	# Detect direction change (input opposing current velocity)
	var is_changing_direction = false
	if swipe_direction != 0.0:
		# Check if input direction opposes velocity direction
		var velocity_sign = sign(player_lateral_velocity)
		var input_sign = sign(swipe_direction)
		if velocity_sign != 0.0 and velocity_sign != input_sign:
			is_changing_direction = true

	# Apply physics with momentum consideration
	if is_changing_direction:
		# Fighting momentum - apply extra deceleration and reduced acceleration
		player_lateral_velocity *= DIRECTION_CHANGE_DECEL
		var reduced_accel = BASE_ACCELERATION * swipe_direction * DIRECTION_CHANGE_ACCEL_MULT
		player_lateral_velocity += reduced_accel * delta
	else:
		# Normal acceleration and damping
		var target_accel = BASE_ACCELERATION * swipe_direction
		player_lateral_velocity += target_accel * delta
		player_lateral_velocity *= VELOCITY_DAMPING

	# Cap velocity
	player_lateral_velocity = clamp(
		player_lateral_velocity,
		-MAX_LATERAL_VELOCITY,
		MAX_LATERAL_VELOCITY
	)

	# Update position
	player_lateral_position += player_lateral_velocity * delta

	# Clamp to screen bounds
	player_lateral_position = clamp(player_lateral_position, 30.0, 1050.0)

	# Update ship visual position
	player_ship.position = Vector2(player_lateral_position, PLAYER_Y_POSITION)

	# Simple visual tilt
	_update_simple_tilt()


func _update_simple_tilt() -> void:
	"""Apply decoupled visual tilt based on input direction"""
	# Calculate target rotation based on input direction with exaggeration
	var target_angle = swipe_direction * MAX_TILT_ANGLE * VISUAL_ROTATION_EXAGGERATION

	# Smoothly rotate toward target angle
	var angle_diff = target_angle - visual_rotation_angle
	var max_rotation_this_frame = VISUAL_ROTATION_SPEED * get_process_delta_time()

	if abs(angle_diff) < max_rotation_this_frame:
		visual_rotation_angle = target_angle
	else:
		visual_rotation_angle += sign(angle_diff) * max_rotation_this_frame

	# Apply visual rotation (decoupled from actual velocity)
	player_ship.rotation_degrees = -90 + visual_rotation_angle  # -90 is base upward rotation


func get_position() -> float:
	"""Get current lateral position"""
	return player_lateral_position


func get_velocity() -> float:
	"""Get current lateral velocity"""
	return player_lateral_velocity


func set_control_locked(locked: bool) -> void:
	"""Lock/unlock player controls"""
	control_locked = locked
	if locked:
		swipe_direction = 0.0


func add_impulse(impulse: float) -> void:
	"""Add velocity impulse (for gravity, etc.)"""
	player_lateral_velocity += impulse


func set_position(x_pos: float) -> void:
	"""Set player position directly (for jump system)"""
	player_lateral_position = clamp(x_pos, 30.0, 1050.0)
	player_ship.position = Vector2(player_lateral_position, PLAYER_Y_POSITION)
	# Reset velocity when teleporting
	player_lateral_velocity = 0.0
