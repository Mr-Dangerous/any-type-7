extends Control

# ============================================================
# HANGAR - SHIP ROSTER
# ============================================================
# Purpose: Visual ship management interface
# Shows ships in a scrollable grid with sprites
# ============================================================

# ============================================================
# PRELOADS
# ============================================================

const SHIP_DETAIL_POPUP := preload("res://scenes/ui/ship_detail_popup.tscn")
const SHIP_CARD := preload("res://scenes/hangar/ship_card.tscn")
const ITEM_CARD := preload("res://scenes/hangar/item_card.tscn")
const WEAPON_CARD := preload("res://scenes/hangar/weapon_card.tscn")
const FLEET_UPGRADE_CARD := preload("res://scenes/hangar/fleet_upgrade_card.tscn")

# ============================================================
# NODE REFERENCES
# ============================================================

@onready var metal_label := $VBoxContainer/TopSection/MarginContainer/VBoxContainer/ResourceBar/MetalPanel/MetalLabel
@onready var crystals_label := $VBoxContainer/TopSection/MarginContainer/VBoxContainer/ResourceBar/CrystalsPanel/CrystalsLabel
@onready var fuel_label := $VBoxContainer/TopSection/MarginContainer/VBoxContainer/ResourceBar/FuelPanel/FuelLabel
@onready var ship_page_container := $VBoxContainer/MiddleSection/PagedContent/ShipPageContainer
@onready var prev_button := $VBoxContainer/MiddleSection/PagedContent/PageNavigation/PrevButton
@onready var next_button := $VBoxContainer/MiddleSection/PagedContent/PageNavigation/NextButton
@onready var page_label := $VBoxContainer/MiddleSection/PagedContent/PageNavigation/PageLabel
@onready var inventory_grid := $"VBoxContainer/BottomSection/MarginContainer/HBoxContainer/TabContainer/TIER 1 UPGRADES/MarginContainer/InventoryGrid"
@onready var weapons_grid := $"VBoxContainer/BottomSection/MarginContainer/HBoxContainer/TabContainer/WEAPONS/MarginContainer/WeaponsGrid"
@onready var fleet_upgrades_grid := $"VBoxContainer/BottomSection/MarginContainer/HBoxContainer/TabContainer/FLEET UPGRADES/MarginContainer/FleetUpgradesGrid"

# ============================================================
# CONSTANTS
# ============================================================

const SHIP_CARD_SIZE := Vector2(480, 360)  # Sized for 2x3 grid
const SHIPS_PER_PAGE := 6  # Show 6 ships per page (2x3 grid)
const LONG_PRESS_DURATION := 1.0  # Seconds to hold for unequip
const GRID_COLUMNS := 2  # Number of columns in the grid

# ============================================================
# PAGING STATE
# ============================================================

var current_page := 0
var total_pages := 1
var ship_cards: Array[Node] = []  # Cache of all ship card instances

# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
	print("[Hangar] Initializing...")

	# Connect to EventBus signals
	EventBus.resource_changed.connect(_on_resource_changed)

	# Connect page navigation buttons
	prev_button.pressed.connect(_on_prev_page)
	next_button.pressed.connect(_on_next_page)

	# Set button text
	prev_button.text = "< PREV"
	next_button.text = "NEXT >"

	# Update resource display
	_update_resource_bar()

	# Populate ship roster
	_populate_ship_roster()

	# Populate Tier 1 inventory
	_populate_tier1_inventory()

	# Populate weapon inventory
	_populate_weapons_inventory()

	# Populate fleet upgrades
	_populate_fleet_upgrades()

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
	# Get all owned ships from GameState
	var owned_ships: Array[String] = GameState.owned_ships

	print("[Hangar] Populating roster with %d ships" % owned_ships.size())

	# Calculate total pages
	total_pages = max(1, ceili(float(owned_ships.size()) / float(SHIPS_PER_PAGE)))
	current_page = clampi(current_page, 0, total_pages - 1)

	# Create all ship cards if not already created
	if ship_cards.is_empty():
		for ship_instance_id in owned_ships:
			var ship_card := SHIP_CARD.instantiate()
			ship_card.custom_minimum_size = SHIP_CARD_SIZE

			# Set ship data (builds UI automatically)
			ship_card.set_ship_data(ship_instance_id)

			# Connect signals
			ship_card.ship_clicked.connect(_on_ship_card_clicked)
			ship_card.equipment_slot_gui_input.connect(_on_equipment_slot_gui_input)
			ship_card.deployment_toggled.connect(_on_ship_deployment_toggled)

			ship_cards.append(ship_card)

	# Display current page
	_display_current_page()

func _display_current_page() -> void:
	"""Display only the ship cards for the current page"""
	# Clear current page display
	for child in ship_page_container.get_children():
		ship_page_container.remove_child(child)

	# Calculate start and end indices for current page
	var start_idx := current_page * SHIPS_PER_PAGE
	var end_idx := mini(start_idx + SHIPS_PER_PAGE, ship_cards.size())

	# Add ship cards for current page (2x3 grid layout)
	for i in range(start_idx, end_idx):
		var ship_card = ship_cards[i]

		# Refresh ship data to show latest equipment changes
		ship_card.refresh_display()

		ship_page_container.add_child(ship_card)

		# Position cards in 2x3 grid
		var card_index := i - start_idx
		var col := card_index % GRID_COLUMNS
		var row := card_index / GRID_COLUMNS

		var x_spacing := 30
		var y_spacing := 25
		var x_pos := 50 + col * (SHIP_CARD_SIZE.x + x_spacing)
		var y_pos := 20 + row * (SHIP_CARD_SIZE.y + y_spacing)
		ship_card.position = Vector2(x_pos, y_pos)

	# Update page label
	page_label.text = "Page %d / %d" % [current_page + 1, total_pages]

	# Enable/disable navigation buttons
	prev_button.disabled = (current_page == 0)
	next_button.disabled = (current_page >= total_pages - 1)

func _on_prev_page() -> void:
	"""Navigate to previous page"""
	if current_page > 0:
		current_page -= 1
		_display_current_page()

func _on_next_page() -> void:
	"""Navigate to next page"""
	if current_page < total_pages - 1:
		current_page += 1
		_display_current_page()

func _on_ship_deployment_toggled(ship_instance_id: String, deployed: bool) -> void:
	"""Handle ship deployment checkbox toggle"""
	if deployed:
		# Add to active loadout if not already there
		if not GameState.active_loadout.has(ship_instance_id):
			GameState.active_loadout.append(ship_instance_id)
			print("[Hangar] Ship deployed: %s" % ship_instance_id)
	else:
		# Remove from active loadout
		var idx := GameState.active_loadout.find(ship_instance_id)
		if idx >= 0:
			GameState.active_loadout.remove_at(idx)
			print("[Hangar] Ship undeployed: %s" % ship_instance_id)

func _on_ship_card_clicked(ship_instance_id: String) -> void:
	print("[Hangar] Ship button pressed: %s" % ship_instance_id)

	# Create and show ship detail popup
	var popup := PopupManager.show_popup(SHIP_DETAIL_POPUP, "ship_detail_%s" % ship_instance_id)

	if popup != null:
		# Set the ship data on the popup
		popup.set_ship_data(ship_instance_id)

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

	# Create an ItemCard for each item
	for item_id in all_tier1_items.keys():
		var item_data: Dictionary = all_tier1_items[item_id]
		var quantity: int = GameState.tier_1_inventory.get(item_id, 0)

		# Instantiate ItemCard
		var item_card := ITEM_CARD.instantiate()
		inventory_grid.add_child(item_card)

		# Set item data (builds UI automatically)
		item_card.set_item_data(item_id, item_data, quantity)

		# Connect drag signal
		item_card.drag_requested.connect(_on_item_card_drag_requested)

# ============================================================
# WEAPONS INVENTORY
# ============================================================

func _populate_weapons_inventory() -> void:
	# Clear existing weapons
	for child in weapons_grid.get_children():
		child.queue_free()

	# Get all weapons from DataManager
	var all_weapons := DataManager.weapons

	print("[Hangar] Populating weapon inventory with %d weapons" % all_weapons.size())

	# Create a WeaponCard for each weapon
	for weapon_id in all_weapons.keys():
		var weapon_data: Dictionary = all_weapons[weapon_id]
		var quantity: int = GameState.weapon_inventory.get(weapon_id, 0)

		# Instantiate WeaponCard
		var weapon_card := WEAPON_CARD.instantiate()
		weapons_grid.add_child(weapon_card)

		# Set weapon data (builds UI automatically)
		weapon_card.set_weapon_data(weapon_id, weapon_data, quantity)

		# Connect drag signal
		weapon_card.drag_requested.connect(_on_weapon_card_drag_requested)

# ============================================================
# FLEET UPGRADES (TIER 2)
# ============================================================

func _populate_fleet_upgrades() -> void:
	# Clear existing upgrades
	for child in fleet_upgrades_grid.get_children():
		child.queue_free()

	# Get all Tier 2 items from DataManager
	var all_tier2_items := DataManager.relics_t2

	print("[Hangar] Populating Fleet Upgrades with %d items" % all_tier2_items.size())

	# Create a FleetUpgradeCard for each item (only show owned items)
	for upgrade_id in all_tier2_items.keys():
		var upgrade_data: Dictionary = all_tier2_items[upgrade_id]
		var quantity: int = GameState.tier_2_inventory.get(upgrade_id, 0)

		# Only show if player owns this upgrade
		if quantity <= 0:
			continue

		# Instantiate FleetUpgradeCard
		var upgrade_card := FLEET_UPGRADE_CARD.instantiate()
		fleet_upgrades_grid.add_child(upgrade_card)

		# Set upgrade data (builds UI automatically)
		upgrade_card.set_upgrade_data(upgrade_id, upgrade_data, quantity)

# ============================================================
# DRAG AND DROP - TIER 1 ITEMS
# ============================================================

func _on_item_card_drag_requested(item_id: String, item_data: Dictionary, texture: Texture2D, card_size: Vector2) -> void:
	"""Handle drag request from ItemCard"""
	DragDropManager.start_drag(item_id, item_data, texture, card_size)

func _on_weapon_card_drag_requested(weapon_id: String, weapon_data: Dictionary, texture: Texture2D, card_size: Vector2) -> void:
	"""Handle drag request from WeaponCard"""
	DragDropManager.start_drag(weapon_id, weapon_data, texture, card_size)

func _input(event: InputEvent) -> void:
	"""Global input handler for drag release"""
	if event is InputEventMouseButton:
		if not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if DragDropManager.is_item_being_dragged():
				# Check if we're over a valid drop target
				var was_dropped := _try_drop_at_mouse_position()
				# End drag
				DragDropManager.end_drag(was_dropped)

func _try_drop_at_mouse_position() -> bool:
	"""Check if mouse is over a ship card or upgrade slot and try to equip

	Returns:
		true if drop was successful, false otherwise
	"""
	var mouse_pos := get_global_mouse_position()
	var dragged_item_id := DragDropManager.get_dragged_item_id()

	# First, check if we're over any ship card (only those on current page)
	for ship_card in ship_page_container.get_children():
		var card_rect := Rect2(ship_card.global_position, ship_card.size)
		if card_rect.has_point(mouse_pos):
			# Found the ship! Try to equip to first available slot
			return _equip_to_first_available_slot(ship_card, dragged_item_id)

	# If not over a ship card, check specific equipment slots
	var all_slots := _get_all_equipment_slots()
	for slot in all_slots:
		if slot is PanelContainer:
			var slot_rect := Rect2(slot.global_position, slot.size)
			if slot_rect.has_point(mouse_pos):
				return _try_equip_item(slot, dragged_item_id)

	return false

func _equip_to_first_available_slot(ship_card: Node, item_id: String) -> bool:
	"""Find the first empty equipment slot on a ship and equip to it

	Returns:
		true if equipped successfully, false otherwise
	"""
	# Get dragged item data to determine slot type
	var dragged_data := DragDropManager.get_dragged_item_data()
	var is_weapon := dragged_data.has("sprite_path")  # Weapons use sprite_path, items use sprite_resource

	# Get appropriate slots based on item type
	var slots: Array = []
	if is_weapon and ship_card.has_method("get_weapon_slots"):
		slots = ship_card.get_weapon_slots()
	elif not is_weapon and ship_card.has_method("get_upgrade_slots"):
		slots = ship_card.get_upgrade_slots()
	else:
		return false

	# Find first empty slot
	for slot in slots:
		if slot is PanelContainer:
			var equipped_item_id: String = slot.get_meta("equipped_item_id", "")
			if equipped_item_id.is_empty():
				# Found an empty slot! Equip here
				var success := _try_equip_item(slot, item_id)
				if success:
					print("[Hangar] Auto-equipped to first available slot")
				return success

	print("[Hangar] No empty slots available on this ship")
	return false

func _get_all_equipment_slots() -> Array:
	"""Get all equipment slots (upgrades and weapons) from all ship cards"""
	var all_slots: Array = []

	for ship_card in ship_cards:
		# Get upgrade slots
		if ship_card.has_method("get_upgrade_slots"):
			var upgrade_slots: Array = ship_card.get_upgrade_slots()
			all_slots.append_array(upgrade_slots)

		# Get weapon slots
		if ship_card.has_method("get_weapon_slots"):
			var weapon_slots: Array = ship_card.get_weapon_slots()
			all_slots.append_array(weapon_slots)

	return all_slots

# ============================================================
# EQUIPMENT SLOT - DROP DETECTION & LONG-PRESS UNEQUIP
# ============================================================

var long_press_slot: PanelContainer = null
var long_press_timer: float = 0.0
var long_press_progress: ColorRect = null

func _on_equipment_slot_gui_input(event: InputEvent, slot: PanelContainer) -> void:
	"""Handle drops on upgrade slots and long-press for unequip"""
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Check if we're dropping an item
			if DragDropManager.is_item_being_dragged():
				var dragged_item_id := DragDropManager.get_dragged_item_id()
				var success := _try_equip_item(slot, dragged_item_id)
				DragDropManager.end_drag(success)
			# Check if slot has equipped item (start long-press to unequip)
			elif not slot.get_meta("equipped_item_id", "").is_empty():
				_start_long_press(slot)

		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Cancel long-press if released early
			_cancel_long_press()

func _process(delta: float) -> void:
	"""Update long-press timer"""
	# Update long-press timer
	if long_press_slot != null:
		long_press_timer += delta

		# Update visual progress
		if long_press_progress != null:
			var progress: float = clamp(long_press_timer / LONG_PRESS_DURATION, 0.0, 1.0)
			long_press_progress.size.x = long_press_slot.size.x * progress

		# Complete unequip after duration
		if long_press_timer >= LONG_PRESS_DURATION:
			_complete_unequip()

func _start_long_press(slot: PanelContainer) -> void:
	"""Start long-press timer for unequipping"""
	long_press_slot = slot
	long_press_timer = 0.0

	# Create visual progress bar
	long_press_progress = ColorRect.new()
	long_press_progress.color = Color(1.0, 0.8, 0.0, 0.7)  # Gold/orange
	long_press_progress.size = Vector2(0, 5)
	long_press_progress.position = Vector2(0, slot.size.y - 5)
	long_press_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(long_press_progress)

	print("[Hangar] Started long-press unequip on slot")

func _cancel_long_press() -> void:
	"""Cancel long-press if released early"""
	if long_press_slot != null:
		if long_press_progress != null:
			long_press_progress.queue_free()
			long_press_progress = null

		long_press_slot = null
		long_press_timer = 0.0

func _complete_unequip() -> void:
	"""Complete the unequip after long-press duration"""
	if long_press_slot == null:
		return

	var ship_id: String = long_press_slot.get_meta("ship_id")
	var slot_index: int = long_press_slot.get_meta("slot_index")
	var slot_type: String = long_press_slot.get_meta("slot_type", "upgrade")

	# Use appropriate EquipmentManager method based on slot type
	var unequipped_item_id := ""
	if slot_type == "weapon":
		unequipped_item_id = EquipmentManager.unequip_weapon_from_ship(ship_id, slot_index)
	else:  # upgrade
		unequipped_item_id = EquipmentManager.unequip_upgrade_from_ship(ship_id, slot_index)

	if not unequipped_item_id.is_empty():
		# Clean up
		_cancel_long_press()

		# Refresh UI
		_populate_ship_roster()
		_populate_tier1_inventory()
		_populate_weapons_inventory()

# ============================================================
# EQUIP/UNEQUIP LOGIC
# ============================================================

func _try_equip_item(slot: PanelContainer, item_id: String) -> bool:
	"""Try to equip an item or weapon to a slot

	Returns:
		true if equipped successfully, false otherwise
	"""
	var ship_id: String = slot.get_meta("ship_id")
	var slot_index: int = slot.get_meta("slot_index")
	var slot_type: String = slot.get_meta("slot_type", "upgrade")

	var success := false

	# Use appropriate EquipmentManager method based on slot type
	if slot_type == "weapon":
		success = EquipmentManager.equip_weapon_to_ship(ship_id, slot_index, item_id)
	else:  # upgrade
		success = EquipmentManager.equip_upgrade_to_ship(ship_id, slot_index, item_id)

	if success:
		# Refresh UI
		_populate_ship_roster()
		_populate_tier1_inventory()
		_populate_weapons_inventory()

	return success
