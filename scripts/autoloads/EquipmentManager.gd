extends Node

# ============================================================
# EQUIPMENT MANAGER - EQUIPMENT SYSTEM
# ============================================================
# Purpose: Centralized equipment logic for ships
# Handles equipping, unequipping, validation, and slot management
# Works across hangar, combat prep, and loadout screens
# ============================================================

# ============================================================
# SIGNALS
# ============================================================

signal item_equipped(ship_id: String, slot_index: int, item_id: String)
signal item_unequipped(ship_id: String, slot_index: int, item_id: String)
signal equipment_changed(ship_id: String)

# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
	print("[EquipmentManager] Initialized")

# ============================================================
# EQUIP OPERATIONS
# ============================================================

func equip_upgrade_to_ship(ship_id: String, slot_index: int, item_id: String) -> bool:
	"""Equip a Tier 1 upgrade to a ship

	Args:
		ship_id: Ship instance ID
		slot_index: Upgrade slot index (0-based)
		item_id: Tier 1 item ID to equip

	Returns:
		true if equipped successfully, false otherwise
	"""
	# Validate ship exists
	var ship_instance := GameState.get_ship_instance(ship_id)
	if ship_instance.is_empty():
		push_error("[EquipmentManager] Ship not found: %s" % ship_id)
		return false

	# Validate slot index
	var blueprint := GameState.get_ship_blueprint_data(ship_id)
	var max_slots: int = int(blueprint.get("upgrade_slots", 1))
	if slot_index < 0 or slot_index >= max_slots:
		push_error("[EquipmentManager] Invalid slot index %d for ship %s (max: %d)" % [slot_index, ship_id, max_slots])
		return false

	# Check if slot is already occupied
	var equipped_upgrades: Array = ship_instance.get("equipped_upgrades", [])
	if slot_index < equipped_upgrades.size() and not equipped_upgrades[slot_index].is_empty():
		push_warning("[EquipmentManager] Slot %d already occupied on ship %s" % [slot_index, ship_id])
		return false

	# Validate player has this item
	var quantity: int = GameState.tier_1_inventory.get(item_id, 0)
	if quantity <= 0:
		push_warning("[EquipmentManager] Player doesn't have item: %s" % item_id)
		return false

	# Validate item exists in database
	var item_data := DataManager.get_relic_t1(item_id)
	if item_data.is_empty():
		push_error("[EquipmentManager] Item not found in database: %s" % item_id)
		return false

	# Perform equip via GameState
	var success := GameState.equip_upgrade_to_ship(ship_id, slot_index, item_id)

	if success:
		print("[EquipmentManager] Equipped %s to ship %s slot %d" % [item_id, ship_id, slot_index])
		item_equipped.emit(ship_id, slot_index, item_id)
		equipment_changed.emit(ship_id)

	return success

func unequip_upgrade_from_ship(ship_id: String, slot_index: int) -> String:
	"""Unequip a Tier 1 upgrade from a ship

	Args:
		ship_id: Ship instance ID
		slot_index: Upgrade slot index (0-based)

	Returns:
		Item ID that was unequipped (empty string if nothing was unequipped)
	"""
	# Validate ship exists
	var ship_instance := GameState.get_ship_instance(ship_id)
	if ship_instance.is_empty():
		push_error("[EquipmentManager] Ship not found: %s" % ship_id)
		return ""

	# Get currently equipped item
	var equipped_upgrades: Array = ship_instance.get("equipped_upgrades", [])
	if slot_index < 0 or slot_index >= equipped_upgrades.size():
		push_error("[EquipmentManager] Invalid slot index: %d" % slot_index)
		return ""

	var item_id: String = equipped_upgrades[slot_index]
	if item_id.is_empty():
		push_warning("[EquipmentManager] Slot %d is already empty on ship %s" % [slot_index, ship_id])
		return ""

	# Perform unequip via GameState
	var success := GameState.unequip_upgrade_from_ship(ship_id, slot_index)

	if success:
		print("[EquipmentManager] Unequipped %s from ship %s slot %d" % [item_id, ship_id, slot_index])
		item_unequipped.emit(ship_id, slot_index, item_id)
		equipment_changed.emit(ship_id)
		return item_id

	return ""

# ============================================================
# SLOT QUERIES
# ============================================================

func get_first_empty_upgrade_slot(ship_id: String) -> int:
	"""Find the first empty upgrade slot on a ship

	Args:
		ship_id: Ship instance ID

	Returns:
		Slot index (0-based), or -1 if no empty slots
	"""
	var ship_instance := GameState.get_ship_instance(ship_id)
	if ship_instance.is_empty():
		return -1

	var blueprint := GameState.get_ship_blueprint_data(ship_id)
	var max_slots: int = int(blueprint.get("upgrade_slots", 1))
	var equipped_upgrades: Array = ship_instance.get("equipped_upgrades", [])

	for i in range(max_slots):
		var item_id: String = equipped_upgrades[i] if i < equipped_upgrades.size() else ""
		if item_id.is_empty():
			return i

	return -1

func is_slot_empty(ship_id: String, slot_index: int) -> bool:
	"""Check if an upgrade slot is empty

	Args:
		ship_id: Ship instance ID
		slot_index: Upgrade slot index (0-based)

	Returns:
		true if slot is empty, false otherwise
	"""
	var ship_instance := GameState.get_ship_instance(ship_id)
	if ship_instance.is_empty():
		return false

	var equipped_upgrades: Array = ship_instance.get("equipped_upgrades", [])
	if slot_index < 0 or slot_index >= equipped_upgrades.size():
		return true  # Out of bounds = empty

	return equipped_upgrades[slot_index].is_empty()

func get_equipped_item(ship_id: String, slot_index: int) -> String:
	"""Get the item ID equipped in a specific slot

	Args:
		ship_id: Ship instance ID
		slot_index: Upgrade slot index (0-based)

	Returns:
		Item ID (empty string if slot is empty or invalid)
	"""
	var ship_instance := GameState.get_ship_instance(ship_id)
	if ship_instance.is_empty():
		return ""

	var equipped_upgrades: Array = ship_instance.get("equipped_upgrades", [])
	if slot_index < 0 or slot_index >= equipped_upgrades.size():
		return ""

	return equipped_upgrades[slot_index]

func get_all_equipped_upgrades(ship_id: String) -> Array:
	"""Get all equipped upgrade IDs for a ship

	Args:
		ship_id: Ship instance ID

	Returns:
		Array of item IDs (includes empty strings for empty slots)
	"""
	var ship_instance := GameState.get_ship_instance(ship_id)
	if ship_instance.is_empty():
		return []

	return ship_instance.get("equipped_upgrades", [])

# ============================================================
# VALIDATION
# ============================================================

func can_equip_to_slot(ship_id: String, slot_index: int, item_id: String) -> bool:
	"""Check if an item can be equipped to a specific slot

	Args:
		ship_id: Ship instance ID
		slot_index: Upgrade slot index (0-based)
		item_id: Tier 1 item ID to check

	Returns:
		true if item can be equipped, false otherwise
	"""
	# Validate ship exists
	var ship_instance := GameState.get_ship_instance(ship_id)
	if ship_instance.is_empty():
		return false

	# Validate slot index
	var blueprint := GameState.get_ship_blueprint_data(ship_id)
	var max_slots: int = int(blueprint.get("upgrade_slots", 1))
	if slot_index < 0 or slot_index >= max_slots:
		return false

	# Check if slot is empty
	if not is_slot_empty(ship_id, slot_index):
		return false

	# Validate player has this item
	var quantity: int = GameState.tier_1_inventory.get(item_id, 0)
	if quantity <= 0:
		return false

	# Validate item exists in database
	var item_data := DataManager.get_relic_t1(item_id)
	if item_data.is_empty():
		return false

	return true

func get_max_upgrade_slots(ship_id: String) -> int:
	"""Get the maximum number of upgrade slots for a ship

	Args:
		ship_id: Ship instance ID

	Returns:
		Number of upgrade slots (0 if ship not found)
	"""
	var blueprint := GameState.get_ship_blueprint_data(ship_id)
	if blueprint.is_empty():
		return 0

	return int(blueprint.get("upgrade_slots", 1))

# ============================================================
# WEAPON OPERATIONS
# ============================================================

func equip_weapon_to_ship(ship_id: String, slot_index: int, weapon_id: String) -> bool:
	"""Equip a weapon to a ship

	Args:
		ship_id: Ship instance ID
		slot_index: Weapon slot index (0-based)
		weapon_id: Weapon system ID to equip

	Returns:
		true if equipped successfully, false otherwise
	"""
	# Validate ship exists
	var ship_instance := GameState.get_ship_instance(ship_id)
	if ship_instance.is_empty():
		push_error("[EquipmentManager] Ship not found: %s" % ship_id)
		return false

	# Get ship blueprint data
	var blueprint := GameState.get_ship_blueprint_data(ship_id)
	var max_slots: int = int(blueprint.get("weapon_slots", 1))

	# Validate slot index
	if slot_index < 0 or slot_index >= max_slots:
		push_error("[EquipmentManager] Invalid weapon slot index %d for ship %s (max: %d)" % [slot_index, ship_id, max_slots])
		return false

	# Check if slot is already occupied
	var equipped_weapons: Array = ship_instance.get("equipped_weapons", [])
	if slot_index < equipped_weapons.size() and not equipped_weapons[slot_index].is_empty():
		push_warning("[EquipmentManager] Weapon slot %d already occupied on ship %s" % [slot_index, ship_id])
		return false

	# Validate player has this weapon
	var quantity: int = GameState.weapon_inventory.get(weapon_id, 0)
	if quantity <= 0:
		push_warning("[EquipmentManager] Player doesn't have weapon: %s" % weapon_id)
		return false

	# Validate weapon exists in database
	var weapon_data := DataManager.get_weapon(weapon_id)
	if weapon_data.is_empty():
		push_error("[EquipmentManager] Weapon not found in database: %s" % weapon_id)
		return false

	# Check ship class restrictions
	var ship_class: String = blueprint.get("ship_size_class", "")
	if not _can_ship_equip_weapon(ship_class, weapon_data):
		push_warning("[EquipmentManager] Ship class '%s' cannot equip weapon '%s'" % [ship_class, weapon_id])
		return false

	# Perform equip via GameState
	var success := GameState.equip_weapon_to_ship(ship_id, slot_index, weapon_id)

	if success:
		print("[EquipmentManager] Equipped weapon %s to ship %s slot %d" % [weapon_id, ship_id, slot_index])
		equipment_changed.emit(ship_id)

	return success

func unequip_weapon_from_ship(ship_id: String, slot_index: int) -> String:
	"""Unequip a weapon from a ship

	Args:
		ship_id: Ship instance ID
		slot_index: Weapon slot index (0-based)

	Returns:
		Weapon ID that was unequipped (empty string if nothing was unequipped)
	"""
	# Validate ship exists
	var ship_instance := GameState.get_ship_instance(ship_id)
	if ship_instance.is_empty():
		push_error("[EquipmentManager] Ship not found: %s" % ship_id)
		return ""

	# Get currently equipped weapon
	var equipped_weapons: Array = ship_instance.get("equipped_weapons", [])
	if slot_index < 0 or slot_index >= equipped_weapons.size():
		push_error("[EquipmentManager] Invalid weapon slot index: %d" % slot_index)
		return ""

	var weapon_id: String = equipped_weapons[slot_index]
	if weapon_id.is_empty():
		push_warning("[EquipmentManager] Weapon slot %d is already empty on ship %s" % [slot_index, ship_id])
		return ""

	# Perform unequip via GameState
	var success := GameState.unequip_weapon_from_ship(ship_id, slot_index)

	if success:
		print("[EquipmentManager] Unequipped weapon %s from ship %s slot %d" % [weapon_id, ship_id, slot_index])
		equipment_changed.emit(ship_id)
		return weapon_id

	return ""

func _can_ship_equip_weapon(ship_class: String, weapon_data: Dictionary) -> bool:
	"""Check if a ship class can equip a weapon based on required_class restrictions

	Args:
		ship_class: Ship class (e.g., "interceptor", "fighter", "frigate")
		weapon_data: Weapon data dictionary from DataManager

	Returns:
		true if ship can equip weapon, false otherwise
	"""
	var required_class: String = weapon_data.get("required_class", "")

	# No restriction = any ship can equip
	if required_class.is_empty():
		return true

	# Handle negative restriction (e.g., "!interceptor" means all except interceptor)
	if required_class.begins_with("!"):
		var excluded_class := required_class.substr(1).strip_edges()
		return ship_class != excluded_class

	# Handle positive restriction (e.g., "frigate" means only frigates)
	# Could also support comma-separated list: "frigate,cruiser"
	var allowed_classes := required_class.split(",")
	for allowed_class in allowed_classes:
		if ship_class == allowed_class.strip_edges():
			return true

	return false
