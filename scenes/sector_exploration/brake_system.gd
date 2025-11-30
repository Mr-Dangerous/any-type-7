extends Node

## Brake System Module
## Handles braking (speed decrease) with fuel consumption, free in gravity zones

# Brake state
var is_braking: bool = false
var brake_time: float = 0.0  # How long we've been braking

# Brake parameters
const SPEED_LOSS_FIRST_SECOND: float = 0.5  # Lose 0.5x speed in first second (IMPACTFUL)
const SPEED_LOSS_AFTER_FIRST: float = 0.2   # Lose 0.2x speed after first second
const FUEL_PER_SECOND: float = 0.5          # 0.5 fuel/sec (half of boost)

# Camera zoom parameters
const ZOOM_IN_AMOUNT: float = 1.3   # Zoom in to 1.3x
const ZOOM_DURATION: float = 1.0    # Zoom lasts 1 second

# References (set by parent)
var scrolling_system: Node = null
var gravity_system: Node = null
var camera_system: Node = null


func _ready() -> void:
	print("[BrakeSystem] Initialized")


func initialize(scroll_sys: Node, grav_sys: Node, cam_sys: Node = null) -> void:
	"""Initialize with system references"""
	scrolling_system = scroll_sys
	gravity_system = grav_sys
	camera_system = cam_sys
	print("[BrakeSystem] Linked to scrolling, gravity, and camera systems")


func handle_input(event: InputEvent) -> void:
	"""Handle brake input (S key)"""
	if event is InputEventKey and event.keycode == KEY_S:
		if event.pressed and not is_braking:
			_start_brake()
		elif not event.pressed and is_braking:
			_end_brake()


func process_brake(delta: float) -> void:
	"""Process braking each frame"""
	if not is_braking:
		return

	# Track brake time
	brake_time += delta

	# Check if in gravity zone (free braking)
	var in_gravity_zone = gravity_system.is_in_gravity_zone()

	# Consume fuel only if NOT in gravity zone
	if not in_gravity_zone:
		var fuel_cost = FUEL_PER_SECOND * delta
		var current_fuel = ResourceManager.get_resource("fuel")

		if current_fuel <= 0:
			print("[BrakeSystem] Out of fuel - Brake cancelled")
			_end_brake()
			return

		# Spend fuel
		var fuel_to_spend = min(fuel_cost, current_fuel)
		ResourceManager.spend_resources({"fuel": fuel_to_spend}, "brake")

	# Tiered speed loss: Impactful first second, then normal
	var speed_loss: float
	if brake_time < 1.0:
		speed_loss = SPEED_LOSS_FIRST_SECOND * delta  # -0.5x/sec in first second
	else:
		speed_loss = SPEED_LOSS_AFTER_FIRST * delta   # -0.2x/sec after

	scrolling_system.adjust_speed_multiplier(-speed_loss)

	# Check if we've hit minimum speed
	var current_speed = scrolling_system.get_speed_multiplier()
	if current_speed <= 1.0:
		# At minimum speed, stop braking
		_end_brake()

	# Debug output every second (approximately)
	if int(Time.get_ticks_msec() / 1000.0) != int((Time.get_ticks_msec() - delta * 1000.0) / 1000.0):
		var loss_rate = SPEED_LOSS_FIRST_SECOND if brake_time < 1.0 else SPEED_LOSS_AFTER_FIRST
		print("[BrakeSystem] Braking - Speed: %.1fx, Loss: %.2fx/s, Time: %.1fs, Gravity: %s, Fuel: %d" % [
			scrolling_system.get_speed_multiplier(),
			loss_rate,
			brake_time,
			"FREE" if in_gravity_zone else "Costing",
			ResourceManager.get_resource("fuel")
		])


func _start_brake() -> void:
	"""Start braking"""
	is_braking = true
	brake_time = 0.0

	# Trigger camera zoom
	if camera_system:
		camera_system.zoom_in(ZOOM_IN_AMOUNT, ZOOM_DURATION)

	print("[BrakeSystem] Brake started - IMPACTFUL first second (%.1fx/sec), then %.1fx/sec" % [
		SPEED_LOSS_FIRST_SECOND, SPEED_LOSS_AFTER_FIRST
	])


func _end_brake() -> void:
	"""End braking"""
	if not is_braking:
		return

	is_braking = false
	brake_time = 0.0
	print("[BrakeSystem] Brake ended - Current speed: %.1fx" % scrolling_system.get_speed_multiplier())


func is_active() -> bool:
	"""Check if brake is currently active"""
	return is_braking
