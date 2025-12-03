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

# Resource system
var rarity: String = "common"  # common, uncommon, rare, epic, legendary
var rarity_tier: int = 1  # 1-5 (determines base resources = tier * 10)
var resource_type: String = "none"  # metal, crystals, fuel, item, none
var base_resources: int = 10  # Base amount (rarity_tier * 10)
var upgrade_chance: int = 0  # Percent chance (0-100) to be an upgrade instead
var is_upgrade: bool = false  # True if this node rolled as an upgrade
var upgrade_item_id: String = ""  # Specific Tier 1 upgrade ID if is_upgrade == true

# Trader system
var is_trader: bool = false
var trade_cost_type: String = "crystals"  # metal, crystals, fuel
var trade_cost_amount: int = 30
var trade_reward_id: String = ""  # Tier 1 upgrade ID the trader sells

# Orbit tracking (for moons and other orbiters)
var is_orbiter: bool = false
var parent_node_id: String = ""
var orbit_radius: float = 0.0
var orbit_angle: float = 0.0
var is_elliptical_orbit: bool = false
var orbit_semi_major: float = 0.0
var orbit_semi_minor: float = 0.0

# Parent node tracking (for nodes that have orbiters)
var has_orbiters: bool = false
var orbiter_orbit_radius: float = 0.0
var orbiter_is_elliptical: bool = false
var orbiter_semi_major: float = 0.0
var orbiter_semi_minor: float = 0.0

# Gravity zone visual
var show_gravity_zone: bool = false

# Visual constants
const RING_COLOR: Color = Color(1.0, 0.8, 0.4, 0.6)  # Yellow ring
const RING_WIDTH: float = 4.0
const ORBIT_PATH_COLOR: Color = Color(1.0, 1.0, 1.0, 0.5)  # White orbit path
const ORBIT_PATH_WIDTH: float = 2.0
const GRAVITY_ZONE_COLOR: Color = Color(0.0, 1.0, 0.0, 0.4)  # Green outline
const GRAVITY_ZONE_WIDTH: float = 3.0

# Resource icon paths
const ICON_METAL: String = "res://assets/Icons/metal_small_icon.png"
const ICON_CRYSTALS: String = "res://assets/Icons/crystal_small_icon.png"
const ICON_FUEL: String = "res://assets/Icons/fuel_icon.png"

# Tier 1 upgrade IDs (must match item_relics_t1.csv)
const TIER_1_UPGRADES = [
	"chronometer", "amplifier", "aegis_plate", "reinforced_hull",
	"resonator", "dampener", "thruster_module", "precision_lens",
	"capacitor", "ablative_coating", "human_legacy", "alien_legacy",
	"machine_legacy", "toxic_legacy"
]

# Tier 1 upgrade icon paths (loaded from CSV via DataManager)
var tier_1_icon_paths: Dictionary = {}


func _ready() -> void:
	# Wait for DataManager to load if not already loaded
	if not DataManager.is_loaded:
		EventBus.all_data_loaded.connect(_on_data_loaded, CONNECT_ONE_SHOT)
	else:
		_load_tier_1_icons()
		# Now create the icon since paths are loaded
		_create_visual_elements()

	# Configure collision for proximity detection
	collision_layer = 2  # Node layer
	collision_mask = 1   # Detect player layer

	# Connect proximity signals
	area_entered.connect(_on_proximity_entered)
	area_exited.connect(_on_proximity_exited)


func _on_data_loaded() -> void:
	"""Called when DataManager finishes loading"""
	_load_tier_1_icons()
	_create_visual_elements()


func setup(id: String, type: String, data: Dictionary, spawn_dist: float) -> void:
	"""Initialize node with ID, type, CSV data, and spawn distance"""
	node_id = id
	node_type = type
	node_data = data
	spawn_distance = spawn_dist

	# Extract CSV parameters
	var size = float(data.get("size", 100))  # CSV size is diameter
	var csv_proximity = float(data.get("proximity_radius", 100))

	node_radius = size / 2.0  # Visual radius
	proximity_radius = size + csv_proximity  # Total activation distance (size + proximity)
	has_gravity_assist = data.get("gravity_assist", "no") == "yes"


	# Check if this is a trader node
	if type == "trader":
		is_trader = true
		# Traders sell a random Tier 1 upgrade for 30 crystals
		trade_cost_type = "crystals"
		trade_cost_amount = 30
		trade_reward_id = TIER_1_UPGRADES.pick_random()
		# Traders don't use the normal resource system
		resource_type = "none"
	else:
		# Get upgrade chance from CSV
		upgrade_chance = int(data.get("upgrade_chance", 0))

		# Roll for upgrade before assigning resources
		_roll_upgrade()

		# If not an upgrade, roll rarity and assign resources normally
		if not is_upgrade:
			_roll_rarity()
			_assign_resource_type()
		else:
			# Upgrades are treated as items (don't break streaks)
			resource_type = "item"

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

	# Note: Icons created in _ready() after tier_1_icon_paths is loaded

	# Queue redraw to show visual
	queue_redraw()


func setup_orbit(parent_id: String, radius: float, initial_angle: float,
				is_elliptical: bool = false, semi_major: float = 0.0, semi_minor: float = 0.0) -> void:
	"""Configure this node as an orbiter"""
	is_orbiter = true
	parent_node_id = parent_id
	orbit_radius = radius
	orbit_angle = initial_angle
	is_elliptical_orbit = is_elliptical
	orbit_semi_major = semi_major if semi_major > 0 else radius
	orbit_semi_minor = semi_minor if semi_minor > 0 else radius

	# Set z-index higher to ensure visibility above parent
	z_index = 10

	# Configured as orbiter


func set_has_orbiters(radius: float, is_elliptical: bool = false,
					semi_major: float = 0.0, semi_minor: float = 0.0) -> void:
	"""Mark this node as having orbiters and set orbit path parameters"""
	has_orbiters = true
	orbiter_orbit_radius = radius
	orbiter_is_elliptical = is_elliptical
	orbiter_semi_major = semi_major if semi_major > 0 else radius
	orbiter_semi_minor = semi_minor if semi_minor > 0 else radius
	queue_redraw()


func set_show_gravity_zone(show: bool) -> void:
	"""Toggle gravity zone visual feedback"""
	if show_gravity_zone != show:
		show_gravity_zone = show
		queue_redraw()


func _on_proximity_entered(area: Area2D) -> void:
	"""Called when player enters proximity"""
	if area.name == "PlayerProximityArea" and not is_activated:
		EventBus.node_proximity_entered.emit(node_id, node_type)
		modulate = Color(1.2, 1.2, 1.2)  # Brighten


func _on_proximity_exited(area: Area2D) -> void:
	"""Called when player exits proximity"""
	if area.name == "PlayerProximityArea":
		modulate = Color(1.0, 1.0, 1.0)  # Reset


func activate() -> void:
	"""Mark node as activated (prevents re-triggering)"""
	is_activated = true
	modulate = Color(0.5, 1.0, 0.5)  # Turn green

	# Hide the resource icon or trader UI
	var icon = get_node_or_null("ResourceIcon")
	if icon:
		icon.visible = false

	var trade_display = get_node_or_null("TradeDisplay")
	if trade_display:
		trade_display.visible = false


func _draw() -> void:
	"""Draw the node's visual appearance"""
	# Draw rarity glow (outermost layer)
	if resource_type != "none":
		var rarity_color = _get_rarity_color()
		var glow_radius = node_radius * 1.3
		# Outer glow
		draw_arc(
			Vector2.ZERO,
			glow_radius,
			0, TAU,
			64,
			rarity_color,
			6.0
		)
		# Inner glow (brighter)
		draw_arc(
			Vector2.ZERO,
			glow_radius - 3,
			0, TAU,
			64,
			Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.6),
			3.0
		)

	# Draw gravity zone outline (green) when boosting
	if show_gravity_zone and has_gravity_assist:
		draw_arc(
			Vector2.ZERO,
			proximity_radius,
			0, TAU,
			64,
			GRAVITY_ZONE_COLOR,
			GRAVITY_ZONE_WIDTH
		)

	# Draw orbit path if this node has orbiters
	if has_orbiters:
		if orbiter_is_elliptical:
			_draw_ellipse_outline(Vector2.ZERO, orbiter_semi_major, orbiter_semi_minor, ORBIT_PATH_COLOR, ORBIT_PATH_WIDTH)
		else:
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


func _draw_ellipse_outline(center: Vector2, semi_major: float, semi_minor: float, color: Color, width: float) -> void:
	"""Draw an ellipse outline using line segments"""
	var num_points = 64
	var points: PackedVector2Array = []

	for i in range(num_points + 1):
		var angle = (float(i) / num_points) * TAU
		var x = center.x + cos(angle - PI/2) * semi_major
		var y = center.y + sin(angle - PI/2) * semi_minor
		points.append(Vector2(x, y))

	# Draw lines between consecutive points
	for i in range(num_points):
		draw_line(points[i], points[i + 1], color, width)


func _roll_upgrade() -> void:
	"""Roll to see if this node is an upgrade instead of resources"""
	if upgrade_chance <= 0:
		is_upgrade = false
		return

	var roll = randi() % 100  # 0-99
	is_upgrade = roll < upgrade_chance  # If roll < chance, it's an upgrade

	# If upgraded, select which Tier 1 upgrade
	if is_upgrade:
		upgrade_item_id = TIER_1_UPGRADES.pick_random()
		resource_type = "item"  # Display as item node
		print("[SectorNode] ⭐ %s rolled UPGRADE: %s" % [node_type, upgrade_item_id])


func _roll_rarity() -> void:
	"""Roll rarity tier for this node (common through legendary)"""
	var roll = randf()  # 0.0 to 1.0

	# Rarity distribution (weighted toward lower tiers)
	# Common: 40%, Uncommon: 30%, Rare: 20%, Epic: 8%, Legendary: 2%
	if roll < 0.40:
		rarity = "common"
		rarity_tier = 1
	elif roll < 0.70:  # 40% + 30%
		rarity = "uncommon"
		rarity_tier = 2
	elif roll < 0.90:  # 70% + 20%
		rarity = "rare"
		rarity_tier = 3
	elif roll < 0.98:  # 90% + 8%
		rarity = "epic"
		rarity_tier = 4
	else:  # 98% + 2%
		rarity = "legendary"
		rarity_tier = 5

	base_resources = rarity_tier * 10


func _assign_resource_type() -> void:
	"""Assign resource type based on CSV resource_profile column"""
	# Non-mineable nodes that didn't roll as upgrade give nothing
	var mineable = node_data.get("mineable", "no")
	if mineable != "yes":
		resource_type = "none"
		return

	var resource_profile = node_data.get("resource_profile", "none")

	match resource_profile:
		"fuel_only":
			resource_type = "fuel"
		"crystals_only":
			resource_type = "crystals"
		"metal_crystals":
			# Give either metal OR crystals (50/50)
			resource_type = "metal" if randf() < 0.5 else "crystals"
		"metal_only":
			resource_type = "metal"
		"mixed":
			# Salvage/treasure nodes - random resource type
			var roll = randf()
			if roll < 0.33:
				resource_type = "metal"
			elif roll < 0.66:
				resource_type = "crystals"
			else:
				resource_type = "fuel"
		_:
			resource_type = "none"


func _create_trader_ui() -> void:
	"""Create trade cost/reward display for trader nodes"""
	# Create container for trade display
	var trade_container = Node2D.new()
	trade_container.name = "TradeDisplay"
	trade_container.position = Vector2(0, -node_radius - 40)
	add_child(trade_container)

	# Cost icon (what player pays)
	var cost_icon_path = ""
	match trade_cost_type:
		"metal":
			cost_icon_path = ICON_METAL
		"crystals":
			cost_icon_path = ICON_CRYSTALS
		"fuel":
			cost_icon_path = ICON_FUEL

	if cost_icon_path != "":
		var cost_icon = Sprite2D.new()
		cost_icon.texture = load(cost_icon_path)
		cost_icon.position = Vector2(-40, 0)
		cost_icon.scale = Vector2(0.8, 0.8)
		trade_container.add_child(cost_icon)

	# Cost amount label
	var cost_label = Label.new()
	cost_label.position = Vector2(-20, -15)
	cost_label.text = str(trade_cost_amount)
	cost_label.add_theme_font_size_override("font_size", 24)
	cost_label.add_theme_color_override("font_color", Color(1, 1, 1))
	trade_container.add_child(cost_label)

	# Arrow
	var arrow_label = Label.new()
	arrow_label.position = Vector2(10, -15)
	arrow_label.text = "→"
	arrow_label.add_theme_font_size_override("font_size", 28)
	arrow_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	trade_container.add_child(arrow_label)

	# Reward icon (what player gets)
	var reward_icon = Sprite2D.new()
	if trade_reward_id != "" and tier_1_icon_paths.has(trade_reward_id):
		var icon_path = tier_1_icon_paths[trade_reward_id]
		if FileAccess.file_exists(icon_path):
			reward_icon.texture = load(icon_path)
	reward_icon.position = Vector2(50, 0)
	reward_icon.scale = Vector2(0.8, 0.8)
	trade_container.add_child(reward_icon)


func _create_resource_icon() -> void:
	"""Create and display resource icon on the node"""
	if resource_type == "none":
		return

	var icon_path: String = ""
	match resource_type:
		"metal":
			icon_path = ICON_METAL
		"crystals":
			icon_path = ICON_CRYSTALS
		"fuel":
			icon_path = ICON_FUEL
		"item":
			# For upgrades, use the specific Tier 1 upgrade icon
			if upgrade_item_id != "" and tier_1_icon_paths.has(upgrade_item_id):
				icon_path = tier_1_icon_paths[upgrade_item_id]
			else:
				return

	if icon_path == "":
		return

	# Verify file exists before loading
	if not FileAccess.file_exists(icon_path):
		print("[ERROR] Icon file missing: %s" % icon_path)
		return

	# Create sprite for the icon
	var icon_sprite = Sprite2D.new()
	icon_sprite.name = "ResourceIcon"
	icon_sprite.texture = load(icon_path)
	icon_sprite.position = Vector2.ZERO  # Centered on the node

	# Uniform icon size (1.6x scale for all nodes - doubled)
	icon_sprite.scale = Vector2(1.6, 1.6)

	# Set z-index to render on top of the node
	icon_sprite.z_index = 1

	add_child(icon_sprite)

	if resource_type == "item" and upgrade_item_id != "":
		print("[Icon] ✓ Upgrade icon: %s on %s" % [upgrade_item_id, node_type])


func _load_tier_1_icons() -> void:
	"""Load Tier 1 upgrade icon paths from DataManager"""
	# Use DataManager instead of manually parsing CSV
	for item_id in TIER_1_UPGRADES:
		var relic_data = DataManager.get_relic_t1(item_id)
		if not relic_data.is_empty():
			var sprite_path = relic_data.get("sprite_resource", "")
			if sprite_path != "":
				tier_1_icon_paths[item_id] = sprite_path


func _create_visual_elements() -> void:
	"""Create icons/UI after tier_1_icon_paths is loaded"""
	if is_trader:
		_create_trader_ui()
	else:
		_create_resource_icon()


func _get_rarity_color() -> Color:
	"""Get the glow color based on rarity tier"""
	match rarity:
		"common":
			return Color(0.7, 0.7, 0.7, 0.4)  # Gray
		"uncommon":
			return Color(0.2, 1.0, 0.3, 0.5)  # Green
		"rare":
			return Color(0.2, 0.6, 1.0, 0.6)  # Blue
		"epic":
			return Color(0.8, 0.2, 1.0, 0.7)  # Purple
		"legendary":
			return Color(1.0, 0.8, 0.0, 0.9)  # Gold
		_:
			return Color(1.0, 1.0, 1.0, 0.3)  # White default


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
