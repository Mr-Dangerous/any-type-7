extends PanelContainer

# ============================================================
# ITEM CARD - REUSABLE INVENTORY ITEM DISPLAY
# ============================================================
# Purpose: Self-contained item card with sprite, name, and quantity
# Handles drag initiation for drag-and-drop
# Used in hangar inventory, shops, loot screens
# ============================================================

# ============================================================
# SIGNALS
# ============================================================

signal drag_requested(item_id: String, item_data: Dictionary, texture: Texture2D, card_size: Vector2)

# ============================================================
# CONSTANTS
# ============================================================

const CARD_SIZE := Vector2(130, 180)

# ============================================================
# DATA
# ============================================================

var item_id: String = ""
var item_data: Dictionary = {}
var quantity: int = 0
var has_item: bool = false

# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
	custom_minimum_size = CARD_SIZE

# ============================================================
# PUBLIC API
# ============================================================

func set_item_data(p_item_id: String, p_item_data: Dictionary, p_quantity: int) -> void:
	"""Set the item data and build the UI

	Args:
		p_item_id: Item identifier
		p_item_data: Item data dictionary
		p_quantity: Quantity player owns
	"""
	item_id = p_item_id
	item_data = p_item_data
	quantity = p_quantity
	has_item = quantity > 0

	# Enable drag if player has this item
	if has_item:
		mouse_filter = Control.MOUSE_FILTER_STOP
		gui_input.connect(_on_gui_input)
	else:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	_build_ui()

# ============================================================
# UI CONSTRUCTION
# ============================================================

func _build_ui() -> void:
	"""Build the item card UI"""
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
	var sprite_path: String = item_data.get("sprite_resource", "")
	if not sprite_path.is_empty() and ResourceLoader.exists(sprite_path):
		var texture_rect := TextureRect.new()
		texture_rect.texture = load(sprite_path)
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.custom_minimum_size = Vector2(100, 100)
		texture_rect.position = Vector2(15, 10)
		texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# Grey out if player doesn't have this item
		if not has_item:
			texture_rect.modulate = Color(0.3, 0.3, 0.3, 0.5)

		container.add_child(texture_rect)

	# Add quantity badge (top left corner)
	if has_item:
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
	"""Create the item name label"""
	var label := Label.new()
	label.text = str(item_data.get("item_name", item_id))
	label.custom_minimum_size = Vector2(130, 60)
	label.add_theme_font_size_override("font_size", 16)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if not has_item:
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
			var sprite_path: String = item_data.get("sprite_resource", "")
			var texture: Texture2D = null

			if not sprite_path.is_empty() and ResourceLoader.exists(sprite_path):
				texture = load(sprite_path)

			# Emit signal to request drag start
			drag_requested.emit(item_id, item_data, texture, custom_minimum_size)
