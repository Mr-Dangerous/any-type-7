extends Button

# ============================================================
# SHIP CARD - REUSABLE SHIP DISPLAY COMPONENT
# ============================================================
# Purpose: Self-contained ship button with sprite and equipment slots
# Used in hangar, combat deployment, situation room
# ============================================================

# ============================================================
# SIGNALS
# ============================================================

signal ship_clicked(ship_id: String)
signal equipment_slot_gui_input(event: InputEvent, slot: PanelContainer)
signal deployment_toggled(ship_id: String, deployed: bool)

# ============================================================
# CONSTANTS
# ============================================================

const CARD_SIZE := Vector2(480, 360)
const SLOT_SIZE := 60.0  # Sized for larger cards

# ============================================================
# DATA
# ============================================================

var ship_instance_id: String = ""
var ship_instance: Dictionary = {}
var ship_blueprint: Dictionary = {}
var equipment_slots: Array[PanelContainer] = []  # Upgrade slots
var weapon_slots: Array[PanelContainer] = []  # Weapon slots

# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
	custom_minimum_size = CARD_SIZE
	pressed.connect(_on_ship_pressed)

# ============================================================
# PUBLIC API
# ============================================================

func set_ship_data(instance_id: String) -> void:
	"""Set the ship data and build the UI"""
	ship_instance_id = instance_id
	ship_instance = GameState.get_ship_instance(ship_instance_id)
	ship_blueprint = GameState.get_ship_blueprint_data(ship_instance_id)

	if ship_instance.is_empty() or ship_blueprint.is_empty():
		push_error("[ShipCard] Ship data not found for: %s" % instance_id)
		text = "Error: Ship Not Found"
		return

	_build_ship_ui()

# ============================================================
# UI CONSTRUCTION
# ============================================================

func _build_ship_ui() -> void:
	"""Build the complete ship card UI"""
	# Clear existing children (except built-in button elements)
	for child in get_children():
		if child is Control:
			child.queue_free()

	equipment_slots.clear()
	weapon_slots.clear()

	# Create main container
	var main_container := Control.new()
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(main_container)

	# Add ship name
	_add_ship_name_label(main_container)

	# Add ship subclass
	_add_ship_subclass_label(main_container)

	# Add deployment checkbox (top right)
	_add_deployment_checkbox(main_container)

	# Add pilot slot
	_add_pilot_slot(main_container)

	# Add ship sprite
	_add_ship_sprite(main_container)

	# Add weapon slots
	_add_weapon_slots(main_container)

	# Add upgrade slots
	_add_upgrade_slots(main_container)

func _add_ship_name_label(parent: Control) -> void:
	"""Add ship name label at top center"""
	var label := Label.new()
	label.text = str(ship_blueprint.get("ship_name", "Unknown"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.position = Vector2(0, 5)
	label.size = Vector2(CARD_SIZE.x, 20)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)

func _add_ship_subclass_label(parent: Control) -> void:
	"""Add ship subclass label below name"""
	var label := Label.new()
	label.text = str(ship_blueprint.get("ship_sub_class", ""))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.position = Vector2(0, 23)
	label.size = Vector2(CARD_SIZE.x, 18)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)

func _add_deployment_checkbox(parent: Control) -> void:
	"""Add deployment checkbox in top right corner"""
	var checkbox := CheckBox.new()
	checkbox.position = Vector2(CARD_SIZE.x - 80, 5)
	checkbox.custom_minimum_size = Vector2(70, 70)
	checkbox.size = Vector2(70, 70)
	checkbox.tooltip_text = "Deploy for Combat"
	checkbox.mouse_filter = Control.MOUSE_FILTER_STOP  # Ensure it receives clicks

	# Make the checkbox icon much larger
	checkbox.add_theme_font_size_override("font_size", 48)
	checkbox.add_theme_constant_override("check_v_offset", 5)

	# Add icon size overrides to make the actual checkbox box larger
	var icon_size = 60
	checkbox.add_theme_constant_override("h_separation", 0)

	# Create a StyleBox for better visibility
	var style_box := StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.5, 0.5, 0.5, 1.0)
	style_box.corner_radius_top_left = 5
	style_box.corner_radius_top_right = 5
	style_box.corner_radius_bottom_left = 5
	style_box.corner_radius_bottom_right = 5
	checkbox.add_theme_stylebox_override("normal", style_box)

	var style_box_hover := StyleBoxFlat.new()
	style_box_hover.bg_color = Color(0.3, 0.3, 0.3, 0.9)
	style_box_hover.border_width_left = 2
	style_box_hover.border_width_right = 2
	style_box_hover.border_width_top = 2
	style_box_hover.border_width_bottom = 2
	style_box_hover.border_color = Color(0.7, 0.7, 0.7, 1.0)
	style_box_hover.corner_radius_top_left = 5
	style_box_hover.corner_radius_top_right = 5
	style_box_hover.corner_radius_bottom_left = 5
	style_box_hover.corner_radius_bottom_right = 5
	checkbox.add_theme_stylebox_override("hover", style_box_hover)

	# Check if this ship is already deployed
	checkbox.button_pressed = GameState.active_loadout.has(ship_instance_id)

	# Connect toggle signal
	checkbox.toggled.connect(_on_deployment_checkbox_toggled)

	parent.add_child(checkbox)

func _add_pilot_slot(parent: Control) -> void:
	"""Add pilot slot in top left corner"""
	var slot := _create_equipment_slot("P", "pilot", "", -1, "")
	slot.position = Vector2(5, 45)
	parent.add_child(slot)

func _add_ship_sprite(parent: Control) -> void:
	"""Add ship sprite in center"""
	var blueprint_id: String = ship_instance.get("blueprint_id", "")
	var visual_data := DataManager.get_ship_visual(blueprint_id)

	if visual_data.is_empty() or not visual_data.get("sprite_exists", false):
		return

	var sprite_path: String = visual_data.get("sprite_path", "")
	if not ResourceLoader.exists(sprite_path):
		return

	var texture_rect := TextureRect.new()
	texture_rect.texture = load(sprite_path)
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.custom_minimum_size = Vector2(200, 180)
	texture_rect.position = Vector2((CARD_SIZE.x - 200) / 2, 50)
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(texture_rect)

func _add_weapon_slots(parent: Control) -> void:
	"""Add weapon slots horizontally centered under ship"""
	var num_weapon_slots: int = int(ship_blueprint.get("weapon_slots", 1))
	var weapon_y_pos := 240.0
	var weapon_total_width := num_weapon_slots * SLOT_SIZE + (num_weapon_slots - 1) * 10
	var weapon_start_x := (CARD_SIZE.x - weapon_total_width) / 2

	# Get equipped weapons from instance
	var equipped_weapons: Array = ship_instance.get("equipped_weapons", [])

	for i in range(num_weapon_slots):
		var equipped_weapon_id: String = equipped_weapons[i] if i < equipped_weapons.size() else ""
		var slot := _create_equipment_slot("W%d" % (i + 1), "weapon", ship_instance_id, i, equipped_weapon_id)
		slot.position = Vector2(weapon_start_x + i * (SLOT_SIZE + 10), weapon_y_pos)
		parent.add_child(slot)
		weapon_slots.append(slot)

func _add_upgrade_slots(parent: Control) -> void:
	"""Add upgrade slots horizontally centered under weapons"""
	var upgrade_slots: int = int(ship_blueprint.get("upgrade_slots", 1))
	var upgrade_y_pos := 310.0
	var upgrade_total_width := upgrade_slots * SLOT_SIZE + (upgrade_slots - 1) * 10
	var upgrade_start_x := (CARD_SIZE.x - upgrade_total_width) / 2

	# Get equipped upgrades from instance
	var equipped_upgrades: Array = ship_instance.get("equipped_upgrades", [])

	for i in range(upgrade_slots):
		var equipped_item_id: String = equipped_upgrades[i] if i < equipped_upgrades.size() else ""
		var slot := _create_equipment_slot("U%d" % (i + 1), "upgrade", ship_instance_id, i, equipped_item_id)
		slot.position = Vector2(upgrade_start_x + i * (SLOT_SIZE + 10), upgrade_y_pos)
		parent.add_child(slot)
		equipment_slots.append(slot)

# ============================================================
# EQUIPMENT SLOT CREATION
# ============================================================

func _create_equipment_slot(label_text: String, slot_type: String, ship_id: String, slot_index: int, equipped_item_id: String) -> PanelContainer:
	"""Create an equipment slot panel"""
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)

	# Store metadata
	slot.set_meta("slot_type", slot_type)
	slot.set_meta("ship_id", ship_id)
	slot.set_meta("slot_index", slot_index)
	slot.set_meta("equipped_item_id", equipped_item_id)

	# Enable interactions for upgrade and weapon slots
	if slot_type == "upgrade" or slot_type == "weapon":
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.gui_input.connect(_on_slot_gui_input.bind(slot))
	else:
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Add label
	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(label)

	# Add equipped item sprite if present
	if not equipped_item_id.is_empty():
		_add_equipped_sprite(slot, equipped_item_id)

	return slot

func _add_equipped_sprite(slot: PanelContainer, item_id: String) -> void:
	"""Add sprite to show equipped item or weapon"""
	var slot_type: String = slot.get_meta("slot_type", "")
	var sprite_path: String = ""

	# Get data based on slot type
	if slot_type == "weapon":
		var weapon_data := DataManager.get_weapon(item_id)
		if weapon_data.is_empty():
			return
		sprite_path = weapon_data.get("sprite_path", "")
	else:  # upgrade slot
		var item_data := DataManager.get_relic_t1(item_id)
		if item_data.is_empty():
			return
		sprite_path = item_data.get("sprite_resource", "")

	# Validate sprite path
	if sprite_path.is_empty() or not ResourceLoader.exists(sprite_path):
		return

	# Create and add sprite
	var texture_rect := TextureRect.new()
	texture_rect.texture = load(sprite_path)
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.custom_minimum_size = Vector2(52, 52)
	texture_rect.position = Vector2(4, 4)
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(texture_rect)

# ============================================================
# SIGNAL HANDLERS
# ============================================================

func _on_ship_pressed() -> void:
	"""Emit signal when ship card is clicked"""
	ship_clicked.emit(ship_instance_id)

func _on_slot_gui_input(event: InputEvent, slot: PanelContainer) -> void:
	"""Forward slot input events to parent"""
	equipment_slot_gui_input.emit(event, slot)

func _on_deployment_checkbox_toggled(button_pressed: bool) -> void:
	"""Forward deployment toggle to parent"""
	deployment_toggled.emit(ship_instance_id, button_pressed)

# ============================================================
# PUBLIC HELPERS
# ============================================================

func get_upgrade_slots() -> Array[PanelContainer]:
	"""Get all upgrade slot panels"""
	return equipment_slots

func get_weapon_slots() -> Array[PanelContainer]:
	"""Get all weapon slot panels"""
	return weapon_slots

func refresh_display() -> void:
	"""Refresh the card display (re-fetch data and rebuild)"""
	if not ship_instance_id.is_empty():
		set_ship_data(ship_instance_id)
