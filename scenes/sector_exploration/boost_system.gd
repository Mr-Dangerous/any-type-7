extends Node

## Boost System Module
## Handles boost activation, fuel consumption, and speed accumulation

# Boost state
var is_boosting: bool = false
var boost_activated_this_frame: bool = false

# Speed accumulation
const SPEED_GAIN_PER_SECOND: float = 0.1

# Fuel costs
const ACTIVATION_FUEL_COST: int = 1
const FUEL_PER_SECOND: float = 1.0

# References (set by parent)
var scrolling_system: Node = null
var gravity_system: Node = null


func _ready() -> void:
	print("[BoostSystem] Initialized")


func initialize(scroll_sys: Node, grav_sys: Node) -> void:
	"""Initialize with system references"""
	scrolling_system = scroll_sys
	gravity_system = grav_sys
	print("[BoostSystem] Linked to scrolling and gravity systems")


func handle_input(event: InputEvent) -> void:
	"""Handle boost input (Shift key)"""
	if event is InputEventKey:
		# Check for Shift keys (left or right)
		if event.keycode == KEY_SHIFT or event.keycode == KEY_SHIFT:
			if event.pressed and not is_boosting:
				_start_boost()
			elif not event.pressed and is_boosting:
				_end_boost()


func process_boost(delta: float) -> void:
	"""Process boost each frame"""
	if not is_boosting:
		return

	# Consume fuel per second
	var fuel_cost = FUEL_PER_SECOND * delta
	var current_fuel = ResourceManager.get_resource("fuel")

	if current_fuel <= 0:
		print("[BoostSystem] Out of fuel - Boost cancelled")
		_end_boost()
		return

	# Spend fuel
	var fuel_to_spend = min(fuel_cost, current_fuel)
	ResourceManager.spend_resources({"fuel": fuel_to_spend}, "boost")

	# Calculate speed gain (base boost × gravity multiplier)
	var base_gain = SPEED_GAIN_PER_SECOND
	var gravity_multiplier = gravity_system.get_current_gravity_multiplier()

	# Apply multiplier if in gravity zone (minimum multiplier is 2)
	var effective_gain = base_gain
	if gravity_multiplier >= 2:
		effective_gain = base_gain * gravity_multiplier

	# Increase speed
	scrolling_system.adjust_speed_multiplier(effective_gain * delta)

	# Debug output every second (approximately)
	if int(Time.get_ticks_msec() / 1000.0) != int((Time.get_ticks_msec() - delta * 1000.0) / 1000.0):
		var in_gravity = gravity_multiplier >= 2
		var gain_rate = effective_gain
		print("[BoostSystem] Boosting - Speed: %.1fx, Gain: %.2fx/s, Gravity: %s, Fuel: %d" % [
			scrolling_system.get_speed_multiplier(),
			gain_rate,
			"%.0fx" % gravity_multiplier if in_gravity else "None",
			ResourceManager.get_resource("fuel")
		])


func _start_boost() -> void:
	"""Start boost (costs 1 fuel immediately)"""
	var current_fuel = ResourceManager.get_resource("fuel")

	if current_fuel < ACTIVATION_FUEL_COST:
		print("[BoostSystem] Not enough fuel to start boost (need %d)" % ACTIVATION_FUEL_COST)
		return

	# Spend activation fuel
	if not ResourceManager.spend_resources({"fuel": ACTIVATION_FUEL_COST}, "boost_start"):
		return

	is_boosting = true
	print("[BoostSystem] Boost started - Activation cost: %d fuel" % ACTIVATION_FUEL_COST)


func _end_boost() -> void:
	"""End boost"""
	if not is_boosting:
		return

	is_boosting = false
	print("[BoostSystem] Boost ended - Final speed: %.1fx" % scrolling_system.get_speed_multiplier())


func is_active() -> bool:
	"""Check if boost is currently active"""
	return is_boosting
