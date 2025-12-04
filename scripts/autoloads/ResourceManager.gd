extends Node

# ============================================================
# RESOURCE MANAGER - ECONOMY SYSTEM
# ============================================================
# Purpose: Track Metal, Crystals, Fuel
# Handles resource spending, validation, and EventBus integration
# ============================================================

# ============================================================
# RESOURCE AMOUNTS
# ============================================================

var metal: int = 100       # Starting metal
var crystals: int = 50     # Starting crystals
var fuel: int = 100        # Starting fuel

# ============================================================
# RESOURCE CAPS (Optional - for future balancing)
# ============================================================

var max_metal: int = 9999
var max_crystals: int = 9999
var max_fuel: int = 999

# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
	print("[ResourceManager] Initialized - Metal: %d, Crystals: %d, Fuel: %d" % [metal, crystals, fuel])

# ============================================================
# GETTERS
# ============================================================

func get_metal() -> int:
	return metal

func get_crystals() -> int:
	return crystals

func get_fuel() -> int:
	return fuel

func get_resource(resource_type: String) -> int:
	match resource_type.to_lower():
		"metal":
			return metal
		"crystals":
			return crystals
		"fuel":
			return fuel
		_:
			push_error("[ResourceManager] Unknown resource type: " + resource_type)
			return 0

# ============================================================
# RESOURCE MODIFICATION (INDIVIDUAL)
# ============================================================

func add_metal(amount: int, source: String = "") -> void:
	var old := metal
	metal = min(metal + amount, max_metal)
	var actual_gained := metal - old

	EventBus.resource_changed.emit("metal", old, metal)
	EventBus.resource_gained.emit("metal", actual_gained, source)

	if actual_gained > 0:
		print("[ResourceManager] +%d Metal from %s (Total: %d)" % [actual_gained, source, metal])

func add_crystals(amount: int, source: String = "") -> void:
	var old := crystals
	crystals = min(crystals + amount, max_crystals)
	var actual_gained := crystals - old

	EventBus.resource_changed.emit("crystals", old, crystals)
	EventBus.resource_gained.emit("crystals", actual_gained, source)

	if actual_gained > 0:
		print("[ResourceManager] +%d Crystals from %s (Total: %d)" % [actual_gained, source, crystals])

func add_fuel(amount: int, source: String = "") -> void:
	var old := fuel
	fuel = min(fuel + amount, max_fuel)
	var actual_gained := fuel - old

	EventBus.resource_changed.emit("fuel", old, fuel)
	EventBus.resource_gained.emit("fuel", actual_gained, source)

	if actual_gained > 0:
		print("[ResourceManager] +%d Fuel from %s (Total: %d)" % [actual_gained, source, fuel])

func add_resource(resource_type: String, amount: int, source: String = "") -> void:
	match resource_type.to_lower():
		"metal":
			add_metal(amount, source)
		"crystals":
			add_crystals(amount, source)
		"fuel":
			add_fuel(amount, source)
		_:
			push_error("[ResourceManager] Cannot add unknown resource type: " + resource_type)

# ============================================================
# RESOURCE SPENDING (VALIDATION)
# ============================================================

func can_afford(cost: Dictionary) -> bool:
	var required_metal: int = cost.get("metal", 0)
	var required_crystals: int = cost.get("crystals", 0)
	var required_fuel: int = cost.get("fuel", 0)

	return metal >= required_metal and crystals >= required_crystals and fuel >= required_fuel

func can_afford_individual(resource_type: String, amount: int) -> bool:
	match resource_type.to_lower():
		"metal":
			return metal >= amount
		"crystals":
			return crystals >= amount
		"fuel":
			return fuel >= amount
		_:
			push_error("[ResourceManager] Unknown resource type: " + resource_type)
			return false

func spend_resources(cost: Dictionary, reason: String = "") -> bool:
	if not can_afford(cost):
		print("[ResourceManager] Cannot afford: %s (Reason: %s)" % [str(cost), reason])
		return false

	var spent_metal: int = cost.get("metal", 0)
	var spent_crystals: int = cost.get("crystals", 0)
	var spent_fuel: int = cost.get("fuel", 0)

	if spent_metal > 0:
		var old := metal
		metal -= spent_metal
		EventBus.resource_changed.emit("metal", old, metal)
		EventBus.resource_spent.emit("metal", spent_metal, reason)

	if spent_crystals > 0:
		var old := crystals
		crystals -= spent_crystals
		EventBus.resource_changed.emit("crystals", old, crystals)
		EventBus.resource_spent.emit("crystals", spent_crystals, reason)

	if spent_fuel > 0:
		var old := fuel
		fuel -= spent_fuel
		EventBus.resource_changed.emit("fuel", old, fuel)
		EventBus.resource_spent.emit("fuel", spent_fuel, reason)

	print("[ResourceManager] Spent %s for %s (M:%d C:%d F:%d)" % [str(cost), reason, metal, crystals, fuel])
	return true

func spend_resource(resource_type: String, amount: int, reason: String = "") -> bool:
	if not can_afford_individual(resource_type, amount):
		print("[ResourceManager] Cannot afford %d %s (Reason: %s)" % [amount, resource_type, reason])
		return false

	match resource_type.to_lower():
		"metal":
			var old := metal
			metal -= amount
			EventBus.resource_changed.emit("metal", old, metal)
			EventBus.resource_spent.emit("metal", amount, reason)
			print("[ResourceManager] Spent %d Metal for %s (Remaining: %d)" % [amount, reason, metal])
			return true

		"crystals":
			var old := crystals
			crystals -= amount
			EventBus.resource_changed.emit("crystals", old, crystals)
			EventBus.resource_spent.emit("crystals", amount, reason)
			print("[ResourceManager] Spent %d Crystals for %s (Remaining: %d)" % [amount, reason, crystals])
			return true

		"fuel":
			var old := fuel
			fuel -= amount
			EventBus.resource_changed.emit("fuel", old, fuel)
			EventBus.resource_spent.emit("fuel", amount, reason)
			print("[ResourceManager] Spent %d Fuel for %s (Remaining: %d)" % [amount, reason, fuel])
			return true

		_:
			push_error("[ResourceManager] Cannot spend unknown resource type: " + resource_type)
			return false

# ============================================================
# BULK OPERATIONS
# ============================================================

func add_multiple(resources: Dictionary, source: String = "") -> void:
	for resource_type in resources.keys():
		var amount: int = resources[resource_type]
		add_resource(resource_type, amount, source)

func reset_resources(starting_metal: int = 100, starting_crystals: int = 50, starting_fuel: int = 100) -> void:
	metal = starting_metal
	crystals = starting_crystals
	fuel = starting_fuel
	print("[ResourceManager] Resources reset - M:%d C:%d F:%d" % [metal, crystals, fuel])

func set_resource(resource_type: String, amount: int) -> void:
	"""Set a resource to a specific amount (for loading saves/starting scenarios)"""
	var old_amount := get_resource(resource_type)

	match resource_type.to_lower():
		"metal":
			metal = clamp(amount, 0, max_metal)
			EventBus.resource_changed.emit("metal", old_amount, metal)
		"crystals":
			crystals = clamp(amount, 0, max_crystals)
			EventBus.resource_changed.emit("crystals", old_amount, crystals)
		"fuel":
			fuel = clamp(amount, 0, max_fuel)
			EventBus.resource_changed.emit("fuel", old_amount, fuel)
		_:
			push_error("[ResourceManager] Cannot set unknown resource type: " + resource_type)
			return

	print("[ResourceManager] Set %s to %d" % [resource_type, amount])

# ============================================================
# DEBUG
# ============================================================

func print_resources() -> void:
	print("=".repeat(60))
	print("RESOURCE MANAGER")
	print("=".repeat(60))
	print("Metal: %d / %d" % [metal, max_metal])
	print("Crystals: %d / %d" % [crystals, max_crystals])
	print("Fuel: %d / %d" % [fuel, max_fuel])
	print("=".repeat(60))

func cheat_add_resources(metal_amount: int = 1000, crystals_amount: int = 1000, fuel_amount: int = 100) -> void:
	add_metal(metal_amount, "CHEAT")
	add_crystals(crystals_amount, "CHEAT")
	add_fuel(fuel_amount, "CHEAT")
	print("[ResourceManager] CHEAT: Added resources!")
