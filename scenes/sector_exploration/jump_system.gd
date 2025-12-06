extends Node

## Jump System Module
## Handles charge-based lateral teleport with fuel cost and cooldown

# Jump state machine
enum JumpState { IDLE, WAITING_DIRECTION, ANIMATING, COOLDOWN }
var jump_state: JumpState = JumpState.IDLE

# Jump parameters
var jump_cooldown_timer: float = 0.0
var jump_target_position: float = 0.0
var jump_animation_timer: float = 0.0
var jump_charge_timer: float = 0.0
var speed_before_jump: float = 0.0
var jump_direction: int = 0  # -1 = left, 1 = right, 0 = undecided
var initial_fuel_spent: bool = false

# Constants
const JUMP_INITIAL_FUEL_COST: int = 3  # Cost when SPACE pressed
const JUMP_EXECUTION_FUEL_COST: int = 5  # Additional cost when jump executes
const JUMP_CHARGE_DURATION: float = 1.0  # Must hold for 1 second
const JUMP_DISTANCE: float = 300.0
const JUMP_ANIMATION_DURATION: float = 0.5
const JUMP_COOLDOWN_DURATION: float = 10.0
const SCREEN_CENTER: float = 540.0
const PLAYER_Y_POSITION: float = 1950.0

# Arrow UI for direction selection
var arrow_left: Node2D = null
var arrow_right: Node2D = null
var arrows_visible: bool = false

# References (set by parent)
var player_movement: Node = null
var scrolling_system: Node = null
var player_ship: Node2D = null


func _ready() -> void:
	print("[JumpSystem] Initialized")


func initialize(player_mv: Node, scroll_sys: Node, ship: Node2D) -> void:
	"""Initialize with system references"""
	player_movement = player_mv
	scrolling_system = scroll_sys
	player_ship = ship
	_create_arrow_ui()
	print("[JumpSystem] Linked to player movement and scrolling systems")


func handle_input(event: InputEvent) -> void:
	"""Handle jump input (SPACE key)"""
	if event is InputEventKey and event.keycode == KEY_SPACE:
		if event.pressed and not event.echo:
			_start_jump()
		elif not event.pressed:
			_cancel_jump_if_waiting()


func process_jump(delta: float) -> void:
	"""Process jump state machine"""
	match jump_state:
		JumpState.IDLE:
			# Update cooldown timer
			if jump_cooldown_timer > 0.0:
				jump_cooldown_timer -= delta

				# Update cooldown indicator progress
				var progress = 1.0 - (jump_cooldown_timer / JUMP_COOLDOWN_DURATION)
				IndicatorManager.update_cooldown_indicator(progress)

				if jump_cooldown_timer <= 0.0:
					print("[JumpSystem] Cooldown complete - Jump ready")
					IndicatorManager.hide_cooldown_indicator()

		JumpState.WAITING_DIRECTION:
			# Update charge timer
			jump_charge_timer += delta

			# Update arrow visual (pulse when ready)
			if jump_charge_timer >= JUMP_CHARGE_DURATION:
				_pulse_arrows()

			# Check for direction input (only after 1 second charge)
			if jump_charge_timer >= JUMP_CHARGE_DURATION:
				if Input.is_key_pressed(KEY_A):
					jump_direction = -1  # Left
					if ResourceManager.spend_resources({"fuel": JUMP_EXECUTION_FUEL_COST}, "jump_execution"):
						_begin_jump_animation()
					else:
						jump_state = JumpState.IDLE
						_hide_arrows()
						print("[JumpSystem] Not enough fuel to complete jump (need %d)" % JUMP_EXECUTION_FUEL_COST)
				elif Input.is_key_pressed(KEY_D):
					jump_direction = 1  # Right
					if ResourceManager.spend_resources({"fuel": JUMP_EXECUTION_FUEL_COST}, "jump_execution"):
						_begin_jump_animation()
					else:
						jump_state = JumpState.IDLE
						_hide_arrows()
						print("[JumpSystem] Not enough fuel to complete jump (need %d)" % JUMP_EXECUTION_FUEL_COST)

		JumpState.ANIMATING:
			# Update animation timer
			jump_animation_timer += delta

			# Rotate ship 360 degrees over duration
			var rotation_progress = jump_animation_timer / JUMP_ANIMATION_DURATION
			player_ship.rotation_degrees = -90 + (rotation_progress * 360.0)

			if jump_animation_timer >= JUMP_ANIMATION_DURATION:
				# Animation complete, execute jump
				_execute_jump()

		JumpState.COOLDOWN:
			# Cooldown handled in IDLE state
			pass


func _start_jump() -> void:
	"""Start a jump - spend 3 fuel and show arrows"""
	# Can only start if idle and not on cooldown
	if jump_state != JumpState.IDLE or jump_cooldown_timer > 0.0:
		return

	# Check fuel for initial cost
	if ResourceManager.get_resource("fuel") < JUMP_INITIAL_FUEL_COST:
		print("[JumpSystem] Not enough fuel to start jump (need %d)" % JUMP_INITIAL_FUEL_COST)
		return

	# Spend initial fuel immediately
	if not ResourceManager.spend_resources({"fuel": JUMP_INITIAL_FUEL_COST}, "jump_initial"):
		return

	# Start charging (must hold for 1 second)
	jump_state = JumpState.WAITING_DIRECTION
	jump_charge_timer = 0.0
	initial_fuel_spent = true

	# Always show arrows
	_show_arrows()

	print("[JumpSystem] Jump charging - Hold for %.1fs, press A/D for direction (-%d fuel)" % [JUMP_CHARGE_DURATION, JUMP_INITIAL_FUEL_COST])


func _cancel_jump_if_waiting() -> void:
	"""Cancel jump if waiting for direction (SPACE released)"""
	if jump_state == JumpState.WAITING_DIRECTION:
		jump_state = JumpState.IDLE
		_hide_arrows()
		print("[JumpSystem] Jump cancelled - SPACE released before direction chosen")


func _begin_jump_animation() -> void:
	"""Begin the jump animation"""
	# Calculate target position (fixed 300px distance)
	var current_pos = player_movement.get_position()
	jump_target_position = current_pos + (jump_direction * JUMP_DISTANCE)
	jump_target_position = clamp(jump_target_position, 30.0, 1050.0)

	# Start animation
	jump_state = JumpState.ANIMATING
	jump_animation_timer = 0.0
	speed_before_jump = scrolling_system.get_speed_multiplier()
	scrolling_system.set_speed_multiplier(0.0)  # Stop scrolling
	player_movement.set_control_locked(true)  # Lock controls during animation

	# Hide arrows if visible
	_hide_arrows()

	var dir_name = "RIGHT" if jump_direction > 0 else "LEFT"
	print("[JumpSystem] Jump animation started - Direction: %s, Target: %.1fpx" % [dir_name, jump_target_position])


func _execute_jump() -> void:
	"""Execute the jump - teleport to target position"""
	# Teleport player to target position
	player_movement.set_position(jump_target_position)

	# Reset ship rotation (player_movement will handle tilt)
	player_ship.rotation_degrees = -90

	# Restore speed
	scrolling_system.set_speed_multiplier(speed_before_jump)

	# Start cooldown
	jump_state = JumpState.COOLDOWN
	jump_cooldown_timer = JUMP_COOLDOWN_DURATION

	# Show cooldown indicator over the ship
	var ship_position = player_ship.global_position
	IndicatorManager.show_cooldown_indicator(ship_position)
	IndicatorManager.update_cooldown_indicator(0.0)  # Start at 0%

	# Unlock controls
	player_movement.set_control_locked(false)

	print("[JumpSystem] Jump executed - New position: %.1fpx, cooldown started" % jump_target_position)

	# After cooldown, return to IDLE
	await get_tree().create_timer(0.1).timeout
	jump_state = JumpState.IDLE


func _create_arrow_ui() -> void:
	"""Create arrow UI elements for direction selection"""
	# Left arrow
	arrow_left = Node2D.new()
	arrow_left.name = "JumpArrowLeft"
	var arrow_left_visual = _create_arrow_visual(-1)
	arrow_left.add_child(arrow_left_visual)
	arrow_left.position = Vector2(370, PLAYER_Y_POSITION - 150)
	arrow_left.visible = false
	add_child(arrow_left)

	# Right arrow
	arrow_right = Node2D.new()
	arrow_right.name = "JumpArrowRight"
	var arrow_right_visual = _create_arrow_visual(1)
	arrow_right.add_child(arrow_right_visual)
	arrow_right.position = Vector2(710, PLAYER_Y_POSITION - 150)
	arrow_right.visible = false
	add_child(arrow_right)


func _create_arrow_visual(direction: int) -> Node2D:
	"""Create a visual arrow pointing in the specified direction"""
	var arrow = Node2D.new()

	# Arrow body (triangle)
	var poly = Polygon2D.new()
	if direction < 0:  # Left arrow
		poly.polygon = PackedVector2Array([
			Vector2(0, 0),
			Vector2(-40, -30),
			Vector2(-40, 30)
		])
	else:  # Right arrow
		poly.polygon = PackedVector2Array([
			Vector2(0, 0),
			Vector2(40, -30),
			Vector2(40, 30)
		])

	poly.color = Color(1.0, 1.0, 0.0, 0.8)  # Yellow with some transparency
	arrow.add_child(poly)

	return arrow


func _show_arrows() -> void:
	"""Show direction selection arrows"""
	if arrow_left and arrow_right:
		arrow_left.visible = true
		arrow_right.visible = true
		arrows_visible = true


func _hide_arrows() -> void:
	"""Hide direction selection arrows"""
	if arrow_left and arrow_right:
		arrow_left.visible = false
		arrow_right.visible = false
		arrows_visible = false
		# Reset scale when hiding
		arrow_left.scale = Vector2(1.0, 1.0)
		arrow_right.scale = Vector2(1.0, 1.0)


func _pulse_arrows() -> void:
	"""Pulse the arrows to indicate jump is ready"""
	if arrow_left and arrow_right and arrows_visible:
		# Use sine wave for smooth pulsing effect (2 pulses per second)
		var pulse_scale = 1.0 + (sin(Time.get_ticks_msec() * 0.006) * 0.3)  # 0.7x to 1.3x scale
		arrow_left.scale = Vector2(pulse_scale, pulse_scale)
		arrow_right.scale = Vector2(pulse_scale, pulse_scale)


func is_on_cooldown() -> bool:
	"""Check if jump is on cooldown"""
	return jump_cooldown_timer > 0.0


func get_cooldown_remaining() -> float:
	"""Get remaining cooldown time"""
	return jump_cooldown_timer
