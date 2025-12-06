extends Control

## Sector Map - Main Coordinator
## Coordinates between scrolling, spawning, player movement, and UI systems
## Refactored to use UIManager, AnimationManager, CollectionManager

# Node references
@onready var player_ship = $WorldContainer/PlayerShip
@onready var grid_tiles = [$WorldContainer/GridTile1, $WorldContainer/GridTile2, $WorldContainer/GridTile3]
@onready var world_container = $WorldContainer

# Camera (created dynamically)
var camera: Camera2D = null

# UI references
@onready var distance_label = $UIOverlay/DistanceLabel
@onready var timer_label = $UIOverlay/TopStatsContainer/TimerLabel
@onready var node_popup = $UIOverlay/NodePopup
@onready var fuel_label = $UIOverlay/ResourceDisplay/HBoxContainer/FuelPanel/VBoxContainer/ValueLabel
@onready var metal_label = $UIOverlay/ResourceDisplay/HBoxContainer/MetalPanel/VBoxContainer/ValueLabel
@onready var crystals_label = $UIOverlay/ResourceDisplay/HBoxContainer/CrystalsPanel/VBoxContainer/ValueLabel
@onready var speed_label = $UIOverlay/ResourceDisplay/HBoxContainer/SpeedPanel/VBoxContainer/ValueLabel
@onready var ui_overlay = $UIOverlay

# Dynamically created UI
var streak_label: Label = null
var enemy_trigger_label: Label = null
var tier_1_container: HBoxContainer = null

# Tier 1 Upgrade Data (loaded from CSV)
var tier_1_data: Dictionary = {}  # item_id → {sprite_resource, item_name, etc.}

# System modules
var scrolling_system: Node
var node_spawner: Node
var player_movement: Node
var boost_system: Node
var brake_system: Node
var gravity_system: Node
var jump_system: Node
var camera_system: Node
var tractor_beam_system: Node
var enemy_sweep_system: Node
var debug_ui_system: Node


func _ready() -> void:
	# Load Tier 1 upgrade data
	_load_tier_1_data()

	# Create and initialize system modules
	_initialize_systems()

	# Connect EventBus signals
	EventBus.node_proximity_entered.connect(_on_node_proximity_entered)
	EventBus.node_proximity_exited.connect(_on_node_proximity_exited)
	EventBus.node_activated.connect(_on_node_activated)
	EventBus.screen_shake_requested.connect(_on_screen_shake_requested)
	EventBus.tier_1_upgrade_collected.connect(_on_tier_1_upgrade_collected)

	# Start game tracking (for timer and stats)
	if not GameState.game_started:
		GameState.start_new_game()

	# Mark sector exploration as active
	GameState.start_sector_exploration()

	# Create dynamic UI elements
	_create_dynamic_ui()

	# Register UI with UIManager
	_register_ui_elements()

	# Initialize CollectionManager counters
	CollectionManager.reset_counters()

	print("[SectorMap] Initialized - Use A/D keys or swipe to move")


func _initialize_systems() -> void:
	"""Create and initialize all system modules"""
	# Create camera
	camera = Camera2D.new()
	camera.position = Vector2(540, 1170)  # Center of screen (1080x2340)
	camera.zoom = Vector2(1.0, 1.0)
	world_container.add_child(camera)
	camera.make_current()

	# Camera system (with shake support)
	camera_system = load("res://scenes/sector_exploration/camera_system.gd").new()
	add_child(camera_system)
	camera_system.initialize(camera)

	# Scrolling system
	scrolling_system = load("res://scenes/sector_exploration/scrolling_system.gd").new()
	add_child(scrolling_system)
	scrolling_system.initialize(grid_tiles)

	# Node spawner
	node_spawner = load("res://scenes/sector_exploration/node_spawner.gd").new()
	add_child(node_spawner)
	node_spawner.initialize(world_container, scrolling_system)

	# Player movement
	player_movement = load("res://scenes/sector_exploration/player_movement.gd").new()
	add_child(player_movement)
	player_movement.initialize(player_ship)

	# Gravity system (create first, boost needs reference to it)
	gravity_system = load("res://scenes/sector_exploration/gravity_system.gd").new()
	add_child(gravity_system)

	# Boost system
	boost_system = load("res://scenes/sector_exploration/boost_system.gd").new()
	add_child(boost_system)
	boost_system.initialize(scrolling_system, gravity_system)

	# Brake system
	brake_system = load("res://scenes/sector_exploration/brake_system.gd").new()
	add_child(brake_system)
	brake_system.initialize(scrolling_system, gravity_system, camera_system)

	# Finish initializing gravity system
	gravity_system.initialize(player_movement, node_spawner, boost_system)

	# Jump system
	jump_system = load("res://scenes/sector_exploration/jump_system.gd").new()
	add_child(jump_system)
	jump_system.initialize(player_movement, scrolling_system, player_ship)

	# Tractor beam system
	tractor_beam_system = load("res://scenes/sector_exploration/tractor_beam_system.gd").new()
	add_child(tractor_beam_system)
	tractor_beam_system.initialize(player_ship, node_spawner)

	# Enemy sweep system
	enemy_sweep_system = load("res://scenes/sector_exploration/enemy_sweep_manager.gd").new()
	add_child(enemy_sweep_system)
	enemy_sweep_system.initialize(player_ship, world_container, ui_overlay, scrolling_system)

	# Debug UI system (disabled for production)
	# Uncomment to enable debug controls:
	# debug_ui_system = load("res://scenes/sector_exploration/debug_ui_system.gd").new()
	# add_child(debug_ui_system)
	# debug_ui_system.initialize(ui_overlay, node_spawner)

	print("[SectorMap] All systems initialized")


func _create_dynamic_ui() -> void:
	"""Create dynamically generated UI elements"""
	# Tier 1 Upgrades container (top-right, horizontal row of icons)
	tier_1_container = HBoxContainer.new()
	tier_1_container.name = "Tier1Container"
	tier_1_container.position = Vector2(700, 40)
	tier_1_container.custom_minimum_size = Vector2(350, 50)  # Space for ~8 icons
	tier_1_container.add_theme_constant_override("separation", 5)
	ui_overlay.add_child(tier_1_container)
	print("[SectorMap] Tier 1 container created at position %s" % tier_1_container.position)

	# Streak display UI
	streak_label = UIManager.create_label(
		ui_overlay,
		"StreakLabel",
		Vector2(40, 180),
		Vector2(1000, 60),
		40,
		Color(1.0, 0.6, 0.2, 1.0),  # Orange
		"No Streak"
	)

	# Enemy trigger display UI
	enemy_trigger_label = UIManager.create_label(
		ui_overlay,
		"EnemyTriggerLabel",
		Vector2(40, 100),
		Vector2(350, 60),
		36,
		Color(1.0, 0.2, 0.2, 1.0),  # Red
		"Enemy Hits: 0"
	)

	print("[SectorMap] Dynamic UI created via UIManager")


func _register_ui_elements() -> void:
	"""Register UI elements with UIManager"""
	# Get resource panels
	var fuel_panel = $UIOverlay/ResourceDisplay/HBoxContainer/FuelPanel
	var metal_panel = $UIOverlay/ResourceDisplay/HBoxContainer/MetalPanel
	var crystals_panel = $UIOverlay/ResourceDisplay/HBoxContainer/CrystalsPanel

	# Register with UIManager
	UIManager.register_sector_ui(
		distance_label, timer_label, tier_1_container,
		fuel_label, metal_label, crystals_label, speed_label,
		fuel_panel, metal_panel, crystals_panel
	)

	UIManager.register_sector_dynamic_ui(streak_label, enemy_trigger_label)

	print("[SectorMap] UI registered with UIManager")


func _unhandled_input(event: InputEvent) -> void:
	"""Route input to systems (only if not handled by UI)"""
	player_movement.handle_input(event)
	boost_system.handle_input(event)
	brake_system.handle_input(event)
	jump_system.handle_input(event)


func _process(delta: float) -> void:
	"""Main update loop - coordinate all systems"""
	# Update systems
	camera_system.process_camera(delta)
	scrolling_system.process_scrolling(delta)
	node_spawner.process_nodes(delta)
	player_movement.process_movement(delta)
	gravity_system.process_gravity(delta)
	boost_system.process_boost(delta)
	brake_system.process_brake(delta)
	jump_system.process_jump(delta)
	tractor_beam_system.process_tractor_beams(delta)

	# Update UI (via UIManager)
	UIManager.update_sector_ui(scrolling_system)


# ============================================================
# EVENT BUS HANDLERS
# ============================================================

func _on_node_proximity_entered(node_id: String, node_type: String) -> void:
	"""Handle proximity entered - automatically collect rewards (except tractor beam nodes)"""
	print("[SectorMap] Proximity entered: %s (%s)" % [node_id, node_type])

	# Find the node to get its resource data
	var node_ref: Area2D = null
	for node_data in node_spawner.get_active_nodes():
		if node_data.node_id == node_id:
			node_ref = node_data.node_ref as Area2D
			break

	if node_ref and not node_ref.is_activated:
		# Skip auto-collection for debris nodes (they use tractor beam)
		if node_ref.has_meta("is_debris") and node_ref.get_meta("is_debris"):
			print("[SectorMap] Debris node detected - handled by tractor beam system")
			return

		# Collect resources using CollectionManager (handles Tier 1 upgrades automatically)
		CollectionManager.collect_from_node(node_ref, ui_overlay)

		# Mark node as activated to prevent re-collection
		node_ref.activate()

	GameState.record_node_visited()


func _on_node_proximity_exited(node_id: String) -> void:
	"""Handle proximity exited"""
	print("[SectorMap] Proximity exited: %s" % node_id)


func _on_node_activated(node_id: String) -> void:
	"""Handle node activation - collect resources and mark as activated"""
	# Find and mark node as activated
	for node_data in node_spawner.get_active_nodes():
		if node_data.node_id == node_id:
			var node = node_data.node_ref as Area2D
			if node:
				# Collect resources from the node using CollectionManager
				if not node.is_activated:
					CollectionManager.collect_from_node(node, ui_overlay)

				# Mark as activated
				node.is_activated = true
				node_data.is_activated = true
				node.modulate = Color(0.5, 1.0, 0.5)
			break

	print("[SectorMap] Node activated: %s" % node_id)


func _on_screen_shake_requested(duration: float, intensity: float) -> void:
	"""Handle screen shake request - delegate to camera system"""
	camera_system.start_shake(duration, intensity)


# ============================================================
# TIER 1 UPGRADE SYSTEM
# ============================================================

# List of all Tier 1 upgrade IDs
const TIER_1_UPGRADES = [
	"chronometer", "amplifier", "aegis_plate", "reinforced_hull",
	"resonator", "dampener", "thruster_module", "precision_lens",
	"capacitor", "ablative_coating", "human_legacy", "alien_legacy",
	"machine_legacy", "toxic_legacy"
]

func _load_tier_1_data() -> void:
	"""Load Tier 1 upgrade data from CSV"""
	var file = FileAccess.open("res://data/item_relics_t1.csv", FileAccess.READ)
	if not file:
		print("[SectorMap] ERROR: Could not load item_relics_t1.csv")
		return

	# Skip header
	file.get_csv_line()

	# Parse CSV
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 4:
			continue

		var item_id = line[0]
		var item_name = line[1]
		var sprite_resource = line[3]

		tier_1_data[item_id] = {
			"item_name": item_name,
			"sprite_resource": sprite_resource
		}

	file.close()
	print("[SectorMap] Loaded %d Tier 1 upgrades from CSV" % tier_1_data.size())


func _on_tier_1_upgrade_collected(item_id: String, total_count: int) -> void:
	"""Handle Tier 1 upgrade collection - add icon to UI"""
	if not tier_1_data.has(item_id):
		print("[SectorMap] ERROR: Unknown item_id: %s" % item_id)
		return

	var item_data = tier_1_data[item_id]
	UIManager.add_tier_1_upgrade_icon(item_id, item_data.sprite_resource)
