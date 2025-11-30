extends Control

## Sector Map - Main Coordinator
## Coordinates between scrolling, spawning, player movement, and UI systems

# Node references
@onready var player_ship = $WorldContainer/PlayerShip
@onready var grid_tiles = [$WorldContainer/GridTile1, $WorldContainer/GridTile2, $WorldContainer/GridTile3]
@onready var world_container = $WorldContainer

# Camera (created dynamically)
var camera: Camera2D = null

# UI references
@onready var distance_label = $UIOverlay/DistanceLabel
@onready var timer_label = $UIOverlay/TopStatsContainer/TimerLabel
@onready var place_boi_label = $UIOverlay/TopStatsContainer/PlaceBoiLabel
@onready var node_popup = $UIOverlay/NodePopup
@onready var fuel_label = $UIOverlay/ResourceDisplay/HBoxContainer/FuelPanel/VBoxContainer/ValueLabel
@onready var metal_label = $UIOverlay/ResourceDisplay/HBoxContainer/MetalPanel/VBoxContainer/ValueLabel
@onready var crystals_label = $UIOverlay/ResourceDisplay/HBoxContainer/CrystalsPanel/VBoxContainer/ValueLabel
@onready var speed_label = $UIOverlay/ResourceDisplay/HBoxContainer/SpeedPanel/VBoxContainer/ValueLabel
@onready var ui_overlay = $UIOverlay

# Dynamically created UI
var streak_label: Label = null

# Animation tracking
var resource_counters: Dictionary = {
	"metal": 0,
	"crystals": 0,
	"fuel": 0
}

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


func _ready() -> void:
	# Create and initialize system modules
	_initialize_systems()

	# Connect EventBus signals
	EventBus.node_proximity_entered.connect(_on_node_proximity_entered)
	EventBus.node_proximity_exited.connect(_on_node_proximity_exited)
	EventBus.node_activated.connect(_on_node_activated)

	# Start game tracking (for timer and stats)
	if not GameState.game_started:
		GameState.start_new_game()

	# Mark sector exploration as active
	GameState.start_sector_exploration()

	# Create streak display UI
	_create_streak_ui()

	# Create debug UI
	_create_debug_ui()

	# Initialize resource counters
	resource_counters["metal"] = ResourceManager.get_metal()
	resource_counters["crystals"] = ResourceManager.get_crystals()
	resource_counters["fuel"] = ResourceManager.get_fuel()

	# Initial UI update
	_update_ui()

	print("[SectorMap] Initialized - Use A/D keys or swipe to move")


func _initialize_systems() -> void:
	"""Create and initialize all system modules"""
	# Create camera
	camera = Camera2D.new()
	camera.position = Vector2(540, 1170)  # Center of screen (1080x2340)
	camera.zoom = Vector2(1.0, 1.0)
	world_container.add_child(camera)
	camera.make_current()

	# Camera system
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

	print("[SectorMap] All systems initialized")


func _unhandled_input(event: InputEvent) -> void:
	"""Route input to systems (only if not handled by UI)"""
	player_movement.handle_input(event)
	boost_system.handle_input(event)
	brake_system.handle_input(event)
	jump_system.handle_input(event)

	# Manual speed control (W key for testing only)



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

	# Update UI
	_update_ui()


func _create_streak_ui() -> void:
	"""Create the streak display label"""
	streak_label = Label.new()
	streak_label.name = "StreakLabel"
	streak_label.position = Vector2(40, 180)
	streak_label.size = Vector2(1000, 60)
	streak_label.add_theme_font_size_override("font_size", 40)
	streak_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2, 1.0))  # Orange
	streak_label.text = "No Streak"
	ui_overlay.add_child(streak_label)
	print("[SectorMap] Streak UI created")


func _create_debug_ui() -> void:
	"""Create debug control buttons for all three spawn types"""
	# Main container (vertical layout)
	var debug_main = VBoxContainer.new()
	debug_main.name = "DebugMain"
	debug_main.position = Vector2(20, 1900)  # Moved leftward from 40 to 20
	debug_main.add_theme_constant_override("separation", 10)
	ui_overlay.add_child(debug_main)

	# Planetary spawn controls
	_add_spawn_control_row(debug_main, "Planetary", "planetary")

	# Debris spawn controls
	_add_spawn_control_row(debug_main, "Debris", "debris")
	_add_spawn_control_row(debug_main, "Cluster", "cluster")

	# Node spawn controls
	_add_spawn_control_row(debug_main, "Nodes", "node")

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	debug_main.add_child(spacer)

	# Tractor beam controls
	_add_spawn_control_row(debug_main, "Attr Range", "attract_range")
	_add_spawn_control_row(debug_main, "Attr Speed", "attract_speed")
	_add_spawn_control_row(debug_main, "Beam Range", "beam_range")
	_add_spawn_control_row(debug_main, "Beam Time", "beam_duration")
	_add_spawn_control_row(debug_main, "Max Beams", "beam_count")

	print("[SectorMap] Debug UI created with 9 controls (4 spawn + 5 tractor beam)")


func _add_spawn_control_row(parent: Control, label_text: String, spawn_type: String) -> void:
	"""Add a row of spawn rate controls"""
	var row = HBoxContainer.new()
	row.name = spawn_type.capitalize() + "Row"  # Name the row for easier lookup
	row.add_theme_constant_override("separation", 15)
	parent.add_child(row)

	# Label
	var label = Label.new()
	label.text = label_text + ":"
	label.custom_minimum_size = Vector2(130, 60)  # Reduced from 150 to fit better
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	row.add_child(label)

	# Decrease button
	var dec_btn = Button.new()
	dec_btn.text = "-"
	dec_btn.custom_minimum_size = Vector2(80, 60)
	dec_btn.mouse_filter = Control.MOUSE_FILTER_STOP  # Ensure button captures mouse events
	dec_btn.pressed.connect(func(): _adjust_spawn_rate(spawn_type, false))
	row.add_child(dec_btn)

	# Display
	var display = Label.new()
	display.name = spawn_type.capitalize() + "Display"
	display.custom_minimum_size = Vector2(180, 60)
	display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	display.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	display.add_theme_font_size_override("font_size", 26)
	display.text = _get_interval_text(spawn_type)
	row.add_child(display)

	# Increase button
	var inc_btn = Button.new()
	inc_btn.text = "+"
	inc_btn.custom_minimum_size = Vector2(80, 60)
	inc_btn.mouse_filter = Control.MOUSE_FILTER_STOP  # Ensure button captures mouse events
	inc_btn.pressed.connect(func(): _adjust_spawn_rate(spawn_type, true))
	row.add_child(inc_btn)


func _adjust_spawn_rate(spawn_type: String, increase: bool) -> void:
	"""Adjust spawn rate for a specific type"""
	match spawn_type:
		"planetary":
			if increase:
				DebugManager.increase_planetary_rate()
			else:
				DebugManager.decrease_planetary_rate()
		"debris":
			if increase:
				DebugManager.increase_debris_rate()
			else:
				DebugManager.decrease_debris_rate()
		"cluster":
			if increase:
				DebugManager.increase_debris_cluster_size()
			else:
				DebugManager.decrease_debris_cluster_size()
		"node":
			if increase:
				DebugManager.increase_node_rate()
			else:
				DebugManager.decrease_node_rate()
		"attract_range":
			if increase:
				DebugManager.increase_attraction_range()
			else:
				DebugManager.decrease_attraction_range()
		"attract_speed":
			if increase:
				DebugManager.increase_attraction_speed()
			else:
				DebugManager.decrease_attraction_speed()
		"beam_range":
			if increase:
				DebugManager.increase_beam_range()
			else:
				DebugManager.decrease_beam_range()
		"beam_duration":
			if increase:
				DebugManager.increase_beam_duration()
			else:
				DebugManager.decrease_beam_duration()
		"beam_count":
			if increase:
				DebugManager.increase_beam_count()
			else:
				DebugManager.decrease_beam_count()

	_update_spawn_displays()


func _update_spawn_displays() -> void:
	"""Update all spawn rate displays"""
	var planetary_display = ui_overlay.get_node_or_null("DebugMain/PlanetaryRow/PlanetaryDisplay")
	if planetary_display:
		planetary_display.text = _get_interval_text("planetary")

	var debris_display = ui_overlay.get_node_or_null("DebugMain/DebrisRow/DebrisDisplay")
	if debris_display:
		debris_display.text = _get_interval_text("debris")

	var cluster_display = ui_overlay.get_node_or_null("DebugMain/ClusterRow/ClusterDisplay")
	if cluster_display:
		cluster_display.text = _get_interval_text("cluster")

	var node_display = ui_overlay.get_node_or_null("DebugMain/NodeRow/NodeDisplay")
	if node_display:
		node_display.text = _get_interval_text("node")

	# Tractor beam displays
	var attract_range_display = ui_overlay.get_node_or_null("DebugMain/Attract_rangeRow/Attract_rangeDisplay")
	if attract_range_display:
		attract_range_display.text = _get_interval_text("attract_range")

	var attract_speed_display = ui_overlay.get_node_or_null("DebugMain/Attract_speedRow/Attract_speedDisplay")
	if attract_speed_display:
		attract_speed_display.text = _get_interval_text("attract_speed")

	var beam_range_display = ui_overlay.get_node_or_null("DebugMain/Beam_rangeRow/Beam_rangeDisplay")
	if beam_range_display:
		beam_range_display.text = _get_interval_text("beam_range")

	var beam_duration_display = ui_overlay.get_node_or_null("DebugMain/Beam_durationRow/Beam_durationDisplay")
	if beam_duration_display:
		beam_duration_display.text = _get_interval_text("beam_duration")

	var beam_count_display = ui_overlay.get_node_or_null("DebugMain/Beam_countRow/Beam_countDisplay")
	if beam_count_display:
		beam_count_display.text = _get_interval_text("beam_count")


func _get_interval_text(spawn_type: String) -> String:
	"""Get formatted interval text for a spawn type"""
	match spawn_type:
		"planetary":
			var interval = DebugManager.get_planetary_interval()
			return "%.0f px" % interval
		"debris":
			var interval = DebugManager.get_debris_interval()
			return "%.0f px" % interval
		"cluster":
			var cluster_range = DebugManager.get_debris_cluster_range()
			return "%d-%d" % [cluster_range.x, cluster_range.y]
		"node":
			var interval = DebugManager.get_node_interval()
			return "%.0f px" % interval
		"attract_range":
			return "%.0f px" % DebugManager.get_attraction_range()
		"attract_speed":
			return "%.0f/s" % DebugManager.get_attraction_speed()
		"beam_range":
			return "%.0f px" % DebugManager.get_beam_range()
		"beam_duration":
			return "%.1fs" % DebugManager.get_beam_duration()
		"beam_count":
			return "%d" % DebugManager.get_beam_count()

	return "N/A"




func _update_ui() -> void:
	"""Update all UI elements"""
	# Distance display
	distance_label.text = scrolling_system.get_distance_display()

	# Timer display
	timer_label.text = GameState.get_elapsed_time_formatted()

	# place_boi counter
	place_boi_label.text = "place_boi: %d" % GameState.place_bois_collected

	# Resource display (live from ResourceManager)
	fuel_label.text = str(ResourceManager.get_resource("fuel"))
	metal_label.text = str(ResourceManager.get_resource("metal"))
	crystals_label.text = str(ResourceManager.get_resource("crystals"))
	speed_label.text = "%.1fx" % scrolling_system.get_speed_multiplier()

	# Streak display
	if streak_label:
		streak_label.text = GameState.get_streak_display()


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

		# Collect resources for non-debris nodes
		_collect_node_resources(node_ref)

		# Mark node as activated to prevent re-collection
		node_ref.activate()

	# Automatically collect place_boi reward
	GameState.collect_place_boi(1)
	GameState.record_node_visited()


func _collect_node_resources(node: Area2D) -> void:
	"""Collect resources from a node with rarity and streak system, or handle trader purchases"""
	# Handle trader nodes
	if node.is_trader:
		_handle_trader_purchase(node)
		return

	var resource_type = node.resource_type
	var base_resources = node.base_resources
	var rarity = node.rarity

	# Skip if no resources
	if resource_type == "none" or base_resources == 0:
		return

	# Get streak multiplier from GameState
	var streak_multiplier = GameState.collect_resource_node(resource_type)

	# Calculate final resources
	var final_amount = int(base_resources * streak_multiplier)

	# Award resources
	if resource_type != "item":
		ResourceManager.add_resource(resource_type, final_amount, "node_collection")

		# Trigger collection animation
		_animate_resource_collection(resource_type, final_amount, node.global_position)

		# Visual feedback (console for now, can add floating text later)
		print("[SectorMap] Collected %d %s from %s %s (base: %d, streak: %.1fx)" %
			[final_amount, resource_type.capitalize(), rarity.capitalize(), node.node_type, base_resources, streak_multiplier])
	else:
		# Items don't use resource system, handle differently
		print("[SectorMap] Collected item from %s %s" % [rarity.capitalize(), node.node_type])


func _animate_resource_collection(resource_type: String, amount: int, from_position: Vector2) -> void:
	"""Animate resource icon flying to UI and counting up"""
	if resource_type == "item":
		return  # Items don't have UI animations yet

	# Get target UI panel
	var target_panel = null
	var icon_path = ""
	match resource_type:
		"metal":
			target_panel = $UIOverlay/ResourceDisplay/HBoxContainer/MetalPanel
			icon_path = "res://assets/Icons/metal_small_icon.png"
		"crystals":
			target_panel = $UIOverlay/ResourceDisplay/HBoxContainer/CrystalsPanel
			icon_path = "res://assets/Icons/crystal_small_icon.png"
		"fuel":
			target_panel = $UIOverlay/ResourceDisplay/HBoxContainer/FuelPanel
			icon_path = "res://assets/Icons/fuel_icon.png"

	if not target_panel:
		return

	# Create flying icon
	var flying_icon = Sprite2D.new()
	flying_icon.texture = load(icon_path)
	flying_icon.scale = Vector2(0.6, 0.6)
	flying_icon.z_index = 200  # Above everything
	flying_icon.global_position = from_position
	ui_overlay.add_child(flying_icon)

	# Calculate target position (center of the panel)
	var target_pos = target_panel.global_position + target_panel.size / 2

	# Animate icon flying to UI
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(flying_icon, "global_position", target_pos, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(flying_icon, "scale", Vector2(0.3, 0.3), 0.5).set_trans(Tween.TRANS_CUBIC)
	tween.chain().tween_callback(func():
		flying_icon.queue_free()
		_animate_number_count(resource_type, amount)
		_animate_panel_pulse(target_panel)
	)


func _animate_number_count(resource_type: String, amount: int) -> void:
	"""Animate counter counting up to new value"""
	var label = null
	match resource_type:
		"metal":
			label = metal_label
		"crystals":
			label = crystals_label
		"fuel":
			label = fuel_label

	if not label:
		return

	var old_value = resource_counters[resource_type]
	var new_value = ResourceManager.get_resource(resource_type)
	resource_counters[resource_type] = new_value

	# Animate counting from old to new
	var tween = create_tween()
	tween.tween_method(func(val): label.text = str(int(val)), old_value, new_value, 0.3)


func _animate_panel_pulse(panel: Control) -> void:
	"""Scale pulse animation for UI panel"""
	var tween = create_tween()
	tween.set_parallel(false)
	tween.tween_property(panel, "scale", Vector2(1.15, 1.15), 0.1).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_CUBIC)


func _handle_trader_purchase(node: Area2D) -> void:
	"""Handle purchasing from a trader node"""
	var cost_type = node.trade_cost_type
	var cost_amount = node.trade_cost_amount
	var reward = node.trade_reward

	# Check if player can afford it
	if not ResourceManager.can_afford_individual(cost_type, cost_amount):
		print("[SectorMap] Cannot afford trader! Need %d %s (Have: %d)" %
			[cost_amount, cost_type.capitalize(), ResourceManager.get_resource(cost_type)])
		return

	# Spend resources
	if ResourceManager.spend_resource(cost_type, cost_amount, "trader_purchase"):
		# Give reward (for now, place_boi)
		GameState.collect_place_boi(1)
		print("[SectorMap] Trade completed! Spent %d %s, received %s" %
			[cost_amount, cost_type.capitalize(), reward])


func _on_node_proximity_exited(node_id: String) -> void:
	"""Handle proximity exited"""
	print("[SectorMap] Proximity exited: %s" % node_id)


func _on_node_activated(node_id: String) -> void:
	"""Handle node activation"""
	# Find and mark node as activated
	for node_data in node_spawner.get_active_nodes():
		if node_data.node_id == node_id:
			var node = node_data.node_ref as Area2D
			if node:
				node.is_activated = true
				node_data.is_activated = true
				node.modulate = Color(0.5, 1.0, 0.5)
			break

	print("[SectorMap] Node activated: %s" % node_id)
