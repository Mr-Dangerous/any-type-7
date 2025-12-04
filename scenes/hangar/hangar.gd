extends Control

# ============================================================
# HANGAR - SHIP ROSTER
# ============================================================
# Purpose: Visual ship management interface
# Shows ships in a scrollable grid with sprites
# ============================================================

# ============================================================
# NODE REFERENCES
# ============================================================

@onready var metal_label := $VBoxContainer/TopSection/MarginContainer/VBoxContainer/ResourceBar/MetalPanel/MetalLabel
@onready var crystals_label := $VBoxContainer/TopSection/MarginContainer/VBoxContainer/ResourceBar/CrystalsPanel/CrystalsLabel
@onready var fuel_label := $VBoxContainer/TopSection/MarginContainer/VBoxContainer/ResourceBar/FuelPanel/FuelLabel
@onready var ship_grid := $VBoxContainer/MiddleSection/ScrollContainer/MarginContainer/ShipGrid
@onready var inventory_grid := $"VBoxContainer/BottomSection/MarginContainer/HBoxContainer/TabContainer/TIER 1 UPGRADES/MarginContainer/InventoryGrid"

# ============================================================
# CONSTANTS
# ============================================================

const SHIP_BUTTON_SIZE := Vector2(450, 450)  # Large buttons for ship display

# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
	print("[Hangar] Initializing...")

	# Connect to EventBus signals
	EventBus.resource_changed.connect(_on_resource_changed)

	# Update resource display
	_update_resource_bar()

	# Populate ship roster
	_populate_ship_roster()

	# Populate Tier 1 inventory
	_populate_tier1_inventory()

	print("[Hangar] Ready!")

# ============================================================
# RESOURCE BAR
# ============================================================

func _update_resource_bar() -> void:
	metal_label.text = "Metal: %d" % ResourceManager.get_metal()
	crystals_label.text = "Crystals: %d" % ResourceManager.get_crystals()
	fuel_label.text = "Fuel: %d" % ResourceManager.get_fuel()

func _on_resource_changed(_resource_type: String, _old_amount: int, _new_amount: int) -> void:
	_update_resource_bar()

# ============================================================
# SHIP ROSTER
# ============================================================

func _populate_ship_roster() -> void:
	# Clear existing ship cards
	for child in ship_grid.get_children():
		child.queue_free()

	# Get all owned ships from GameState
	var owned_ships: Array[String] = GameState.owned_ships

	print("[Hangar] Populating roster with %d ships" % owned_ships.size())

	# Create a button for each ship
	for ship_instance_id in owned_ships:
		var ship_button := _create_ship_button(ship_instance_id)
		ship_grid.add_child(ship_button)

func _create_ship_button(ship_instance_id: String) -> Button:
	"""Create a large ship button with sprite and equipment slots"""
	var button := Button.new()
	button.custom_minimum_size = SHIP_BUTTON_SIZE

	# Get ship instance and blueprint data
	var instance := GameState.get_ship_instance(ship_instance_id)
	var blueprint := GameState.get_ship_blueprint_data(ship_instance_id)

	if instance.is_empty() or blueprint.is_empty():
		button.text = "Error: Ship data not found"
		return button

	# Get slot counts from blueprint
	var weapon_slots: int = int(blueprint.get("weapon_slots", 1))
	var upgrade_slots: int = int(blueprint.get("upgrade_slots", 1))
	var blueprint_id: String = instance.get("blueprint_id", "")
	var visual_data := DataManager.get_ship_visual(blueprint_id)

	# Create main container (fills button)
	var main_container := Control.new()
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(main_container)

	# Add ship name (top center)
	var name_label := Label.new()
	name_label.text = str(blueprint.get("ship_name", "Unknown"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.position = Vector2(0, 10)
	name_label.size = Vector2(SHIP_BUTTON_SIZE.x, 30)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_container.add_child(name_label)

	# Add sub_class (below name)
	var subclass_label := Label.new()
	subclass_label.text = str(blueprint.get("ship_sub_class", ""))
	subclass_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subclass_label.add_theme_font_size_override("font_size", 18)
	subclass_label.position = Vector2(0, 38)
	subclass_label.size = Vector2(SHIP_BUTTON_SIZE.x, 25)
	subclass_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_container.add_child(subclass_label)

	# Add pilot slot (top left corner)
	var pilot_slot := _create_equipment_slot("PILOT")
	pilot_slot.position = Vector2(10, 70)
	main_container.add_child(pilot_slot)

	# Add ship sprite (centered)
	var sprite_y_pos := 80.0
	if not visual_data.is_empty() and visual_data.get("sprite_exists", false):
		var sprite_path: String = visual_data.get("sprite_path", "")

		if ResourceLoader.exists(sprite_path):
			var texture_rect := TextureRect.new()
			texture_rect.texture = load(sprite_path)
			texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			texture_rect.custom_minimum_size = Vector2(200, 200)
			texture_rect.position = Vector2((SHIP_BUTTON_SIZE.x - 200) / 2, sprite_y_pos)
			texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			main_container.add_child(texture_rect)

	# Add weapon slots (horizontal, centered under ship)
	var weapon_y_pos := 290.0
	var slot_size := 70.0
	var weapon_total_width := weapon_slots * slot_size + (weapon_slots - 1) * 10
	var weapon_start_x := (SHIP_BUTTON_SIZE.x - weapon_total_width) / 2

	for i in range(weapon_slots):
		var weapon_slot := _create_equipment_slot("W%d" % (i + 1))
		weapon_slot.position = Vector2(weapon_start_x + i * (slot_size + 10), weapon_y_pos)
		main_container.add_child(weapon_slot)

	# Add upgrade slots (horizontal, centered under weapons)
	var upgrade_y_pos := 370.0
	var upgrade_total_width := upgrade_slots * slot_size + (upgrade_slots - 1) * 10
	var upgrade_start_x := (SHIP_BUTTON_SIZE.x - upgrade_total_width) / 2

	for i in range(upgrade_slots):
		var upgrade_slot := _create_equipment_slot("U%d" % (i + 1))
		upgrade_slot.position = Vector2(upgrade_start_x + i * (slot_size + 10), upgrade_y_pos)
		main_container.add_child(upgrade_slot)

	# Connect button press (for future detail view)
	button.pressed.connect(_on_ship_button_pressed.bind(ship_instance_id))

	return button

func _create_equipment_slot(label_text: String) -> PanelContainer:
	"""Create a small equipment slot box"""
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(70, 70)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(label)

	return slot

func _on_ship_button_pressed(ship_instance_id: String) -> void:
	print("[Hangar] Ship button pressed: %s" % ship_instance_id)
	# TODO: Open ship detail view

# ============================================================
# TIER 1 INVENTORY
# ============================================================

func _populate_tier1_inventory() -> void:
	# Clear existing items
	for child in inventory_grid.get_children():
		child.queue_free()

	# Get all Tier 1 items from DataManager
	var all_tier1_items := DataManager.relics_t1

	print("[Hangar] Populating Tier 1 inventory with %d items" % all_tier1_items.size())

	# Create a card for each item
	for item_id in all_tier1_items.keys():
		var item_data: Dictionary = all_tier1_items[item_id]
		var quantity: int = GameState.tier_1_inventory.get(item_id, 0)
		var item_card := _create_tier1_item_card(item_id, item_data, quantity)
		inventory_grid.add_child(item_card)

func _create_tier1_item_card(item_id: String, item_data: Dictionary, quantity: int) -> Control:
	"""Create a compact Tier 1 item card with sprite on top and name below"""
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(130, 180)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vbox)

	# Get sprite path
	var sprite_path: String = item_data.get("sprite_resource", "")
	var has_item := quantity > 0

	# Create sprite container
	var sprite_container := Control.new()
	sprite_container.custom_minimum_size = Vector2(130, 120)
	sprite_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sprite_container)

	# Add sprite
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

		sprite_container.add_child(texture_rect)

	# Add quantity label (top left corner of sprite container)
	if has_item:
		var quantity_bg := PanelContainer.new()
		quantity_bg.position = Vector2(5, 5)
		quantity_bg.custom_minimum_size = Vector2(45, 35)
		quantity_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprite_container.add_child(quantity_bg)

		var quantity_label := Label.new()
		quantity_label.text = "x%d" % quantity
		quantity_label.add_theme_font_size_override("font_size", 20)
		quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		quantity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		quantity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		quantity_bg.add_child(quantity_label)

	# Add item name (below sprite)
	var name_label := Label.new()
	name_label.text = str(item_data.get("item_name", item_id))
	name_label.custom_minimum_size = Vector2(130, 60)
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if not has_item:
		name_label.modulate = Color(0.5, 0.5, 0.5, 0.7)

	vbox.add_child(name_label)

	return card
