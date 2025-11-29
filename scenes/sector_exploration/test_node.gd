extends Area2D

# Node configuration
var node_id: String = ""
var node_type: String = "test"
var spawn_distance: float = 0.0
var is_activated: bool = false

# CSV data
var node_data: Dictionary = {}
var node_radius: float = 100.0
var proximity_radius: float = 100.0
var has_gravity_assist: bool = false
var node_color: Color = Color(1.0, 0.5, 0.2, 0.8)

# Orbit tracking (for moons and other orbiters)
var is_orbiter: bool = false
var parent_node_id: String = ""
var orbit_radius: float = 0.0
var orbit_angle: float = 0.0

# Parent node tracking (for nodes that have orbiters)
var has_orbiters: bool = false
var orbiter_orbit_radius: float = 0.0

# Visual constants
const RING_COLOR: Color = Color(1.0, 0.8, 0.4, 0.6)  # Yellow ring
const RING_WIDTH: float = 4.0
const ORBIT_PATH_COLOR: Color = Color(0.5, 0.5, 0.5, 0.3)  # Gray orbit path
const ORBIT_PATH_WIDTH: float = 2.0


func _ready() -> void:
	# Configure collision for proximity detection
	collision_layer = 2  # Node layer
	collision_mask = 1   # Detect player layer

	# Connect proximity signals
	area_entered.connect(_on_proximity_entered)
	area_exited.connect(_on_proximity_exited)

	print("[TestNode] %s ready at %s" % [node_id, position])


func setup(id: String, type: String, data: Dictionary, spawn_dist: float) -> void:
	"""Initialize node with ID, type, CSV data, and spawn distance"""
	node_id = id
	node_type = type
	node_data = data
	spawn_distance = spawn_dist

	# Extract CSV parameters
	node_radius = float(data.get("size", 100)) / 2.0  # CSV size is diameter
	proximity_radius = float(data.get("proximity_radius", 100))
	has_gravity_assist = data.get("gravity_assist", "no") == "yes"

	# Parse color from CSV (hex format like "#FFEB3B")
	var color_str = data.get("color", "#FF8C3B")
	node_color = _parse_hex_color(color_str)

	# Set z-index to ensure visibility above grid
	z_index = 5

	# Create and configure collision shape for proximity detection
	# Use proximity_radius from CSV, not visual size
	var collision_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = proximity_radius
	collision_shape.shape = circle
	add_child(collision_shape)

	# Create debug label
	var label = Label.new()
	label.name = "DebugLabel"
	label.position = Vector2(-50, -node_radius - 30)
	label.text = "%s" % type.capitalize()
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	add_child(label)

	# Queue redraw to show visual
	queue_redraw()

	print("[SectorNode] %s (%s) - Size: %.0fpx, Proximity: %.0fpx, Gravity: %s" % [
		node_id, node_type, node_radius * 2, proximity_radius, has_gravity_assist
	])


func setup_orbit(parent_id: String, radius: float, initial_angle: float) -> void:
	"""Configure this node as an orbiter"""
	is_orbiter = true
	parent_node_id = parent_id
	orbit_radius = radius
	orbit_angle = initial_angle

	# Set z-index higher to ensure visibility above parent
	z_index = 10

	print("[SectorNode] %s configured as orbiter - Parent: %s, Radius: %.1fpx, Angle: %.1f°" % [
		node_id, parent_id, radius, rad_to_deg(initial_angle)
	])


func set_has_orbiters(radius: float) -> void:
	"""Mark this node as having orbiters and set orbit path radius"""
	has_orbiters = true
	orbiter_orbit_radius = radius
	queue_redraw()

	print("[SectorNode] %s marked as having orbiters - Orbit radius: %.1fpx" % [node_id, radius])


func _on_proximity_entered(area: Area2D) -> void:
	"""Called when player enters proximity"""
	if area.name == "PlayerProximityArea" and not is_activated:
		EventBus.node_proximity_entered.emit(node_id, node_type)
		modulate = Color(1.2, 1.2, 1.2)  # Brighten
		print("[TestNode] %s proximity entered" % node_id)


func _on_proximity_exited(area: Area2D) -> void:
	"""Called when player exits proximity"""
	if area.name == "PlayerProximityArea":
		modulate = Color(1.0, 1.0, 1.0)  # Reset


func activate() -> void:
	"""Mark node as activated (prevents re-triggering)"""
	is_activated = true
	modulate = Color(0.5, 1.0, 0.5)  # Turn green
	print("[TestNode] %s activated" % node_id)


func _draw() -> void:
	"""Draw the node's visual appearance"""
	# Draw orbit path if this node has orbiters
	if has_orbiters:
		draw_arc(
			Vector2.ZERO,
			orbiter_orbit_radius,
			0, TAU,
			64,
			ORBIT_PATH_COLOR,
			ORBIT_PATH_WIDTH
		)

	# Main colored circle
	draw_circle(Vector2.ZERO, node_radius, node_color)

	# Inner ring for contrast
	draw_arc(
		Vector2.ZERO,
		node_radius * 0.8,
		0, TAU,
		32,
		RING_COLOR,
		RING_WIDTH
	)


func _parse_hex_color(hex: String) -> Color:
	"""Parse hex color string like '#FFEB3B' to Color"""
	if hex.begins_with("#"):
		hex = hex.substr(1)

	if hex.length() == 6:
		var r = ("0x" + hex.substr(0, 2)).hex_to_int() / 255.0
		var g = ("0x" + hex.substr(2, 2)).hex_to_int() / 255.0
		var b = ("0x" + hex.substr(4, 2)).hex_to_int() / 255.0
		return Color(r, g, b, 0.8)  # 80% opacity

	# Fallback to orange
	return Color(1.0, 0.5, 0.2, 0.8)
