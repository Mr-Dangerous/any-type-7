extends Node

## Jump System Module
## Handles charge-based lateral teleport with fuel cost and cooldown

# Jump state machine
enum JumpState { IDLE, CHARGING, ANIMATING, COOLDOWN }
var jump_state: JumpState = JumpState.IDLE

# Jump parameters
var jump_charge_time: float = 0.0
var jump_cooldown_timer: float = 0.0
var jump_target_position: float = 0.0
var jump_animation_timer: float = 0.0
var speed_before_jump: float = 0.0
var jump_direction_locked: bool = false  # true = right, false = left

# Constants
const JUMP_START_FUEL_COST: int = 3
const JUMP_FUEL_PER_SECOND: int = 1
const JUMP_MIN_DISTANCE: float = 100.0
const JUMP_DISTANCE_PER_SECOND: float = 200.0
const JUMP_ANIMATION_DURATION: float = 0.5
const JUMP_COOLDOWN_DURATION: float = 10.0
const JUMP_INDICATOR_SHOW_DELAY: float = 0.5
const SCREEN_CENTER: float = 540.0
const PLAYER_Y_POSITION: float = 1950.0

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
	print("[JumpSystem] Linked to player movement and scrolling systems")


func handle_input(event: InputEvent) -> void:
	"""Handle jump input (SPACE key)"""
	if event is InputEventKey and event.keycode == KEY_SPACE:
		if event.pressed and not event.echo:
			_start_jump_charge()
		elif not event.pressed:
			_release_jump()


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

		JumpState.CHARGING:
			# Update charge time
			jump_charge_time += delta

			# Consume fuel per second
			var fuel_cost_this_frame = JUMP_FUEL_PER_SECOND * delta
			var current_fuel = ResourceManager.get_resource("fuel")

			if current_fuel <= 0:
				print("[JumpSystem] Out of fuel - Jump cancelled")
				_cancel_jump()
				return

			# Spend fuel
			var fuel_to_spend = min(fuel_cost_this_frame, current_fuel)
			ResourceManager.spend_resources({"fuel": fuel_to_spend}, "jump_charge")

			# Update jump indicator
			_update_jump_indicator()

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


func _start_jump_charge() -> void:
	"""Start charging a jump"""
	# Can only start if idle and not on cooldown
	if jump_state != JumpState.IDLE or jump_cooldown_timer > 0.0:
		return

	# Check fuel for initial cost
	if ResourceManager.get_resource("fuel") < JUMP_START_FUEL_COST:
		print("[JumpSystem] Not enough fuel to start jump (need %d)" % JUMP_START_FUEL_COST)
		return

	# Spend initial fuel
	if not ResourceManager.spend_resources({"fuel": JUMP_START_FUEL_COST}, "jump_start"):
		return

	# Start charging
	jump_state = JumpState.CHARGING
	jump_charge_time = 0.0

	# Lock jump direction based on current position
	var player_x = player_movement.get_position()
	if player_x < SCREEN_CENTER:
		jump_direction_locked = true  # Jump right
	elif player_x > SCREEN_CENTER:
		jump_direction_locked = false  # Jump left
	else:
		jump_direction_locked = false  # Default to left at exact center

	var direction_name = "RIGHT" if jump_direction_locked else "LEFT"
	print("[JumpSystem] Jump charging started - Direction locked: %s - Initial fuel cost: %d" % [direction_name, JUMP_START_FUEL_COST])


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
	speed_before_jump = scrolling_system.get_speed_multiplier()
	scrolling_system.set_speed_multiplier(0.0)  # Stop scrolling
	player_movement.set_control_locked(true)  # Lock controls during animation

	# Hide indicator
	IndicatorManager.hide_jump_indicator()

	print("[JumpSystem] Jump released - Distance: %.1fpx, Target: %.1fpx" % [jump_distance, jump_target_position])


func _calculate_jump_distance() -> float:
	"""Calculate jump distance based on charge time"""
	var distance = JUMP_MIN_DISTANCE + (jump_charge_time * JUMP_DISTANCE_PER_SECOND)
	return distance


func _calculate_jump_target(distance: float, jump_right: bool) -> float:
	"""Calculate target position based on current position, distance, and locked direction"""
	var current_pos = player_movement.get_position()

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
	"""Update the visual jump indicator position"""
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


func _cancel_jump() -> void:
	"""Cancel jump (out of fuel)"""
	jump_state = JumpState.IDLE
	jump_charge_time = 0.0
	IndicatorManager.hide_jump_indicator()
	player_movement.set_control_locked(false)


func is_on_cooldown() -> bool:
	"""Check if jump is on cooldown"""
	return jump_cooldown_timer > 0.0


func get_cooldown_remaining() -> float:
	"""Get remaining cooldown time"""
	return jump_cooldown_timer
