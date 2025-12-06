extends Node

## Debug UI System Module
## Handles runtime debug controls for spawn rates and tractor beam tuning
## This is development-only code and can be disabled in production builds

# References (set by parent)
var ui_overlay: Node = null  # Can be Control or CanvasLayer
var node_spawner: Node = null

# UI container
var debug_main: VBoxContainer = null


func initialize(overlay: Node, spawner: Node) -> void:
	"""Initialize with UI overlay and node spawner references"""
	ui_overlay = overlay
	node_spawner = spawner
	_create_debug_ui()
	print("[DebugUISystem] Initialized with debug controls")


func _create_debug_ui() -> void:
	"""Create debug control buttons for all spawn types and tractor beam settings"""
	# Main container (vertical layout)
	debug_main = VBoxContainer.new()
	debug_main.name = "DebugMain"
	debug_main.position = Vector2(20, 1900)  # Bottom left
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

	print("[DebugUISystem] Debug UI created with 9 controls (4 spawn + 5 tractor beam)")


func _add_spawn_control_row(parent: Control, label_text: String, spawn_type: String) -> void:
	"""Add a row of spawn rate controls"""
	var row = HBoxContainer.new()
	row.name = spawn_type.capitalize() + "Row"
	row.add_theme_constant_override("separation", 15)
	parent.add_child(row)

	# Label
	var label = Label.new()
	label.text = label_text + ":"
	label.custom_minimum_size = Vector2(130, 60)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	row.add_child(label)

	# Decrease button
	var dec_btn = Button.new()
	dec_btn.text = "-"
	dec_btn.custom_minimum_size = Vector2(80, 60)
	dec_btn.mouse_filter = Control.MOUSE_FILTER_STOP
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
	inc_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	inc_btn.pressed.connect(func(): _adjust_spawn_rate(spawn_type, true))
	row.add_child(inc_btn)


func _adjust_spawn_rate(spawn_type: String, increase: bool) -> void:
	"""Adjust spawn rate for a specific type"""
	match spawn_type:
		"planetary":
			if increase:
				node_spawner.increase_planetary_rate()
			else:
				node_spawner.decrease_planetary_rate()
		"debris":
			if increase:
				node_spawner.increase_debris_rate()
			else:
				node_spawner.decrease_debris_rate()
		"cluster":
			if increase:
				node_spawner.increase_debris_cluster_size()
			else:
				node_spawner.decrease_debris_cluster_size()
		"node":
			if increase:
				node_spawner.increase_node_rate()
			else:
				node_spawner.decrease_node_rate()
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

	update_displays()


func update_displays() -> void:
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
			var interval = node_spawner.get_planetary_interval()
			return "%.0f px" % interval
		"debris":
			var interval = node_spawner.get_debris_interval()
			return "%.0f px" % interval
		"cluster":
			var cluster_range = node_spawner.get_debris_cluster_range()
			return "%d-%d" % [cluster_range.x, cluster_range.y]
		"node":
			var interval = node_spawner.get_node_interval()
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
