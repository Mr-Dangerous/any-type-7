extends Node
# ============================================================
# SECTOR STATE
# ============================================================
var current_sector: int = 1
var sector_start_time: float = 0.0
var mothership_arrival_time: float = 300.0
var current_background: String = ""
# ============================================================
# MAP CONFIGURATION
# ============================================================
const MAP_WIDTH: int = 1080
const MAP_HEIGHT: int = 5000
const MAP_LOOPS_VERTICALLY: bool = true
const BACKGROUNDS: Array[String] = [
	"res://assets/Backgrounds/starfield_background.png",
	"res://assets/Backgrounds/red_starfield_background.png",
	"res://assets/Backgrounds/light_stream_background.png"
]
# ============================================================
# NODE TRACKING
# ============================================================
var all_nodes: Array[Dictionary] = []
var revealed_nodes: Array[String] = []
var activated_nodes: Array[String] = []
var exit_node_id: String = ""
# ============================================================
# PLAYER POSITION & FORWARD MOVEMENT
# ============================================================
var player_position: Vector2 = Vector2(540, 2500)
var current_speed_multiplier: float = 1.0
var player_forward_position: float = 0.0  # Infinite scrolling distance

# ============================================================
# RESOURCE ASSIGNMENT (PER NODE INSTANCE)
# ============================================================
var node_resource_assignments: Dictionary = {}  # node_id -> resource_profile
var node_ring_status: Dictionary = {}  # node_id -> bool (gas giants only)
# ============================================================
# INITIALIZATION
# ============================================================
func _ready() -> void:
	print("[SectorManager] Initialized")
func start_sector(sector_number: int) -> void:
	current_sector = sector_number
	sector_start_time = Time.get_ticks_msec() / 1000.0
	mothership_arrival_time = _calculate_mothership_time(sector_number)
	current_background = BACKGROUNDS[randi() % BACKGROUNDS.size()]
	_generate_sector_nodes()
	_reveal_starting_area()
	EventBus.sector_entered.emit(sector_number)
	print("[SectorManager] Sector %d started - Mothership arrives in %.1fs" % [sector_number, mothership_arrival_time])
	print("[SectorManager] Background: %s" % current_background)
# ============================================================
# NODE GENERATION
# ============================================================
func _generate_sector_nodes() -> void:
	all_nodes.clear()
	revealed_nodes.clear()
	activated_nodes.clear()
	var node_count := randi_range(30, 50)
	for i in range(node_count):
		var node_data := _create_random_node(i)
		all_nodes.append(node_data)
	var exit_node := _create_exit_node(node_count)
	all_nodes.append(exit_node)
	exit_node_id = exit_node.node_id
	print("[SectorManager] Generated %d nodes (including exit)" % all_nodes.size())
func _create_random_node(index: int) -> Dictionary:
	var node_types := ["mining", "outpost", "asteroid", "graveyard", "trader", "colony", "vault"]
	var weights := [30, 25, 20, 10, 8, 5, 2]
	var node_type := _weighted_random(node_types, weights)
	var position := Vector2(randf_range(100, MAP_WIDTH - 100), randf_range(100, MAP_HEIGHT - 100))
	var node_id := "node_%d" % index

	# Assign resources for this node instance
	_assign_node_resources(node_id, node_type)

	return {
		"node_id": node_id,
		"node_type": node_type,
		"position": position,
		"is_revealed": false,
		"is_activated": false
	}
func _create_exit_node(index: int) -> Dictionary:
	var position := Vector2(randf_range(200, MAP_WIDTH - 200), randf_range(1000, MAP_HEIGHT - 1000))
	return {
		"node_id": "exit_node",
		"node_type": "exit",
		"position": position,
		"is_revealed": false,
		"is_activated": false
	}
func _weighted_random(options: Array, weights: Array) -> String:
	var total_weight := 0
	for w in weights:
		total_weight += w
	var rand := randf() * total_weight
	var cumulative := 0
	for i in range(options.size()):
		cumulative += weights[i]
		if rand <= cumulative:
			return options[i]
	return options[0]
# ============================================================
# FOG OF WAR
# ============================================================
func _reveal_starting_area() -> void:
	var reveal_radius := 300.0
	for node in all_nodes:
		var distance := player_position.distance_to(node.position)
		if distance <= reveal_radius:
			reveal_node(node.node_id)
func reveal_node(node_id: String) -> void:
	if not revealed_nodes.has(node_id):
		revealed_nodes.append(node_id)
		var node := get_node_data(node_id)
		EventBus.node_discovered.emit(node_id, node.get("node_type", "unknown"))
func reveal_area_around(position: Vector2, radius: float) -> void:
	for node in all_nodes:
		var distance := position.distance_to(node.position)
		if distance <= radius:
			reveal_node(node.node_id)
# ============================================================
# NODE QUERIES
# ============================================================
func get_node_data(node_id: String) -> Dictionary:
	for node in all_nodes:
		if node.node_id == node_id:
			return node
	return {}
func get_revealed_nodes() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for node_id in revealed_nodes:
		results.append(get_node_data(node_id))
	return results
func is_node_revealed(node_id: String) -> bool:
	return revealed_nodes.has(node_id)
func activate_node(node_id: String) -> void:
	if not activated_nodes.has(node_id):
		activated_nodes.append(node_id)
		EventBus.node_activated.emit(node_id)
# ============================================================
# PLAYER MOVEMENT
# ============================================================
func move_player_to(target_position: Vector2) -> void:
	player_position = target_position
	reveal_area_around(player_position, 300.0)
func jump_to_position(target_position: Vector2) -> bool:
	var fuel_cost := 10
	if not ResourceManager.spend_resources({"fuel": fuel_cost}, "jump"):
		return false
	player_position = target_position
	current_speed_multiplier = 1.0
	reveal_area_around(player_position, 400.0)
	print("[SectorManager] Jumped to %s - Fuel spent: %d" % [target_position, fuel_cost])
	return true
func apply_gravity_assist() -> bool:
	var fuel_cost := 1
	if not ResourceManager.spend_resources({"fuel": fuel_cost}, "gravity_assist"):
		return false
	current_speed_multiplier += 0.2
	print("[SectorManager] Gravity assist applied - Speed: %.1fx" % current_speed_multiplier)
	return true
# ============================================================
# MOTHERSHIP TIMER
# ============================================================
func _calculate_mothership_time(sector_num: int) -> float:
	var base_time := 300.0
	var reduction_per_sector := 15.0
	var minimum_time := 60.0
	return max(base_time - (sector_num * reduction_per_sector), minimum_time)
func get_time_until_mothership() -> float:
	var current_time := Time.get_ticks_msec() / 1000.0
	var elapsed := current_time - sector_start_time
	return max(mothership_arrival_time - elapsed, 0.0)
func is_mothership_arrived() -> bool:
	return get_time_until_mothership() <= 0.0

# ============================================================
# RESOURCE ASSIGNMENT FUNCTIONS
# ============================================================

func _assign_node_resources(node_id: String, node_type: String) -> void:
	"""Assign resource profile to node instance

	Handles gas giant rings (50% chance) and varied profiles (random per instance)

	Args:
		node_id: The node's unique identifier
		node_type: The node type
	"""
	var node_config := DataManager.get_node_config(node_type)
	var resource_profile: String = node_config.get("resource_profile", "mixed")

	# Gas giants: check ring chance (50%)
	if node_type == "gas_giant":
		var ring_chance: float = node_config.get("gas_giant_ring_chance", 0.5)
		var has_rings := randf() < ring_chance
		node_ring_status[node_id] = has_rings
		resource_profile = "fuel_crystals" if has_rings else "fuel_only"
		EventBus.gas_giant_rings_detected.emit(node_id, has_rings)
		print("[SectorManager] Gas giant %s: rings=%s, profile=%s" % [node_id, has_rings, resource_profile])

	# Varied profiles: random assignment per instance
	elif resource_profile == "varied":
		resource_profile = _assign_varied_resource_profile(node_type)

	node_resource_assignments[node_id] = resource_profile
	EventBus.node_resources_assigned.emit(node_id, resource_profile)

func _assign_varied_resource_profile(node_type: String) -> String:
	"""Randomly assign resource profile for 'varied' nodes

	Args:
		node_type: The node type

	Returns:
		Resource profile string
	"""
	match node_type:
		"rocky_planet", "ice_planet":
			# Random: metal OR fuel OR crystals
			var profiles := ["metal_only", "fuel_only", "crystals_only"]
			return profiles[randi() % profiles.size()]
		"moon":
			# Random: metal OR crystals (NO fuel)
			var profiles := ["metal_only", "crystals_only"]
			return profiles[randi() % profiles.size()]
		_:
			return "mixed"

func get_node_resources(node_id: String) -> Dictionary:
	"""Get resources for a node based on its assigned profile

	Args:
		node_id: The node's unique identifier

	Returns:
		Dictionary with metal, crystals, fuel amounts
	"""
	var profile: String = node_resource_assignments.get(node_id, "mixed")
	var node := get_node_data(node_id)
	if node.is_empty():
		return {"metal": 0, "crystals": 0, "fuel": 0}

	var node_config := DataManager.get_node_config(node.node_type)
	var min_res: int = node_config.get("min_resources", 0)
	var max_res: int = node_config.get("max_resources", 0)
	var total_amount := randi_range(min_res, max_res)

	match profile:
		"fuel_only":
			return {"metal": 0, "crystals": 0, "fuel": total_amount}
		"metal_only":
			return {"metal": total_amount, "crystals": 0, "fuel": 0}
		"crystals_only":
			return {"metal": 0, "crystals": total_amount, "fuel": 0}
		"metal_crystals":
			var metal := int(total_amount * 0.6)
			var crystals := total_amount - metal
			return {"metal": metal, "crystals": crystals, "fuel": 0}
		"fuel_crystals":
			var fuel := int(total_amount * 0.6)
			var crystals := total_amount - fuel
			return {"metal": 0, "crystals": crystals, "fuel": fuel}
		"none":
			return {"metal": 0, "crystals": 0, "fuel": 0}
		_:  # "mixed"
			var metal := int(total_amount * 0.4)
			var crystals := int(total_amount * 0.3)
			var fuel := total_amount - metal - crystals
			return {"metal": metal, "crystals": crystals, "fuel": fuel}

func can_interact_with_node(node_id: String) -> Dictionary:
	"""Check if player can interact with node (mining restrictions)

	Args:
		node_id: The node's unique identifier

	Returns:
		Dictionary with "allowed" (bool) and "reason" (String)
	"""
	var node := get_node_data(node_id)
	if node.is_empty():
		return {"allowed": false, "reason": "Node not found"}

	var node_config := DataManager.get_node_config(node.node_type)

	# Check if mineable
	var is_mineable: bool = node_config.get("mineable", false)
	if not is_mineable:
		return {"allowed": true, "reason": ""}  # Non-mineable nodes always allowed

	# Check speed restriction
	if not SpeedVisionManager.can_mine_at_current_speed(node.node_type):
		var reason := SpeedVisionManager.get_speed_restriction_reason(node.node_type)
		EventBus.mining_blocked_speed_too_high.emit(node.node_type, node_config.get("speed_restriction_mining", 0))
		return {"allowed": false, "reason": reason}

	return {"allowed": true, "reason": ""}
