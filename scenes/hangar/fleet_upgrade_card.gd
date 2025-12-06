extends PanelContainer

# ============================================================
# FLEET UPGRADE CARD - VIEW-ONLY DISPLAY
# ============================================================
# Purpose: Display Tier 2 fleet upgrades (passive bonuses)
# No drag & drop - these are fleet-wide bonuses, not equipped to ships
# ============================================================

# ============================================================
# CONSTANTS
# ============================================================

const CARD_SIZE := Vector2(130, 180)

# ============================================================
# DATA
# ============================================================

var upgrade_id: String = ""
var upgrade_data: Dictionary = {}
var quantity: int = 0

# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
	custom_minimum_size = CARD_SIZE

# ============================================================
# PUBLIC API
# ============================================================

func set_upgrade_data(p_upgrade_id: String, p_upgrade_data: Dictionary, p_quantity: int) -> void:
	"""Set the upgrade data and build the UI

	Args:
		p_upgrade_id: Upgrade identifier
		p_upgrade_data: Upgrade data dictionary
		p_quantity: Quantity owned (for display)
	"""
	upgrade_id = p_upgrade_id
	upgrade_data = p_upgrade_data
	quantity = p_quantity

	_build_ui()

# ============================================================
# UI CONSTRUCTION
# ============================================================

func _build_ui() -> void:
	"""Build the fleet upgrade card UI"""
	# Clear existing children
	for child in get_children():
		child.queue_free()

	# Create main VBox
	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vbox)

	# Add sprite container
	var sprite_container := _create_sprite_container()
	vbox.add_child(sprite_container)

	# Add name label
	var name_label := _create_name_label()
	vbox.add_child(name_label)

func _create_sprite_container() -> Control:
	"""Create the sprite display area with quantity badge"""
	var container := Control.new()
	container.custom_minimum_size = Vector2(130, 120)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Add sprite (placeholder for now - Tier 2 items use same placeholder)
	var texture_rect := TextureRect.new()
	# Use placeholder - could load from sprite_resource if it exists in CSV
	var sprite_path: String = "res://assets/Icons/fleet_upgrades/place_boi.png"  # Placeholder
	if ResourceLoader.exists(sprite_path):
		texture_rect.texture = load(sprite_path)
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.custom_minimum_size = Vector2(100, 100)
	texture_rect.position = Vector2(15, 10)
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Color tint to distinguish Tier 2 (golden/yellow tint)
	texture_rect.modulate = Color(1.0, 0.9, 0.5, 1.0)

	container.add_child(texture_rect)

	# Add quantity badge (top left corner)
	var quantity_bg := PanelContainer.new()
	quantity_bg.position = Vector2(5, 5)
	quantity_bg.custom_minimum_size = Vector2(45, 35)
	quantity_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(quantity_bg)

	var quantity_label := Label.new()
	quantity_label.text = "x%d" % quantity
	quantity_label.add_theme_font_size_override("font_size", 20)
	quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quantity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	quantity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quantity_bg.add_child(quantity_label)

	return container

func _create_name_label() -> Label:
	"""Create the upgrade name label"""
	var label := Label.new()
	label.text = str(upgrade_data.get("item_name", upgrade_id))
	label.custom_minimum_size = Vector2(130, 60)
	label.add_theme_font_size_override("font_size", 16)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
