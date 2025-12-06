extends PanelContainer

# ============================================================
# WEAPON CARD - REUSABLE WEAPON INVENTORY DISPLAY
# ============================================================
# Purpose: Self-contained weapon card with sprite, name, and quantity
# Handles drag initiation for drag-and-drop
# Used in hangar weapon inventory
# ============================================================

# ============================================================
# SIGNALS
# ============================================================

signal drag_requested(weapon_id: String, weapon_data: Dictionary, texture: Texture2D, card_size: Vector2)

# ============================================================
# CONSTANTS
# ============================================================

const CARD_SIZE := Vector2(130, 180)

# ============================================================
# DATA
# ============================================================

var weapon_id: String = ""
var weapon_data: Dictionary = {}
var quantity: int = 0
var has_weapon: bool = false

# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
	custom_minimum_size = CARD_SIZE

# ============================================================
# PUBLIC API
# ============================================================

func set_weapon_data(p_weapon_id: String, p_weapon_data: Dictionary, p_quantity: int) -> void:
	"""Set the weapon data and build the UI

	Args:
		p_weapon_id: Weapon identifier
		p_weapon_data: Weapon data dictionary
		p_quantity: Quantity player owns
	"""
	weapon_id = p_weapon_id
	weapon_data = p_weapon_data
	quantity = p_quantity
	has_weapon = quantity > 0

	# Enable drag if player has this weapon
	if has_weapon:
		mouse_filter = Control.MOUSE_FILTER_STOP
		gui_input.connect(_on_gui_input)
	else:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	_build_ui()

# ============================================================
# UI CONSTRUCTION
# ============================================================

func _build_ui() -> void:
	"""Build the weapon card UI"""
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

	# Add sprite
	var sprite_path: String = weapon_data.get("sprite_path", "")
	if not sprite_path.is_empty() and ResourceLoader.exists(sprite_path):
		var texture_rect := TextureRect.new()
		texture_rect.texture = load(sprite_path)
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.custom_minimum_size = Vector2(100, 100)
		texture_rect.position = Vector2(15, 10)
		texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# Grey out if player doesn't have this weapon
		if not has_weapon:
			texture_rect.modulate = Color(0.3, 0.3, 0.3, 0.5)

		container.add_child(texture_rect)

	# Add quantity badge (top left corner)
	if has_weapon:
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
	"""Create the weapon name label"""
	var label := Label.new()
	label.text = str(weapon_data.get("system_name", weapon_id))
	label.custom_minimum_size = Vector2(130, 60)
	label.add_theme_font_size_override("font_size", 16)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if not has_weapon:
		label.modulate = Color(0.5, 0.5, 0.5, 0.7)

	return label

# ============================================================
# INPUT HANDLING
# ============================================================

func _on_gui_input(event: InputEvent) -> void:
	"""Handle mouse input for drag start"""
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Get sprite texture for drag preview
			var sprite_path: String = weapon_data.get("sprite_path", "")
			var texture: Texture2D = null

			if not sprite_path.is_empty() and ResourceLoader.exists(sprite_path):
				texture = load(sprite_path)

			# Emit signal to request drag start
			drag_requested.emit(weapon_id, weapon_data, texture, custom_minimum_size)
