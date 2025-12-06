extends PanelContainer

# ============================================================
# SHIP DETAIL POPUP
# ============================================================
# Purpose: Display detailed ship information in a popup
# Shows stats, pilot, weapons, and upgrades
# ============================================================

# ============================================================
# NODE REFERENCES
# ============================================================

@onready var title_label := $MarginContainer/VBoxContainer/Header/TitleLabel
@onready var close_button := $MarginContainer/VBoxContainer/Header/CloseButton
@onready var vbox_container := $MarginContainer/VBoxContainer
@onready var statistics_grid := $MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/StatisticsGrid
@onready var pilot_info := $MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/PilotInfo
@onready var weapons_container := $MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/WeaponsContainer
@onready var upgrades_container := $MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/UpgradesContainer

# ============================================================
# DATA
# ============================================================

var ship_instance_id: String = ""
var ship_sprite_container: CenterContainer = null
var ship_sprite: TextureRect = null

# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
	# Set up close button text (extra large for mobile tapping)
	close_button.text = "X"
	close_button.add_theme_font_size_override("font_size", 64)

	# Configure title (extra large and bold for mobile)
	title_label.text = "Ship Details"
	title_label.add_theme_font_size_override("font_size", 72)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Create ship sprite container (between header and scroll container)
	_create_ship_sprite_container()

	# Configure headers
	_configure_header_labels()

func _create_ship_sprite_container() -> void:
	"""Create the ship sprite display area"""
	ship_sprite_container = CenterContainer.new()
	ship_sprite_container.custom_minimum_size = Vector2(0, 450)

	ship_sprite = TextureRect.new()
	ship_sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	ship_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ship_sprite.custom_minimum_size = Vector2(400, 400)

	ship_sprite_container.add_child(ship_sprite)

	# Insert after header (index 1)
	var header_node = vbox_container.get_child(0)
	vbox_container.add_child(ship_sprite_container)
	vbox_container.move_child(ship_sprite_container, 1)

func _configure_header_labels() -> void:
	"""Configure section header labels with extra large mobile-friendly sizes"""
	var stats_header := $MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/StatisticsHeader
	stats_header.text = "STATISTICS"
	stats_header.add_theme_font_size_override("font_size", 52)

	var pilot_header := $MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/PilotHeader
	pilot_header.text = "PILOT"
	pilot_header.add_theme_font_size_override("font_size", 52)

	var weapons_header := $MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/WeaponsHeader
	weapons_header.text = "WEAPONS"
	weapons_header.add_theme_font_size_override("font_size", 52)

	var upgrades_header := $MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/UpgradesHeader
	upgrades_header.text = "UPGRADES"
	upgrades_header.add_theme_font_size_override("font_size", 52)

# ============================================================
# PUBLIC API
# ============================================================

func set_ship_data(instance_id: String) -> void:
	"""Load and display ship data"""
	ship_instance_id = instance_id

	# Get ship instance and blueprint data
	var instance := GameState.get_ship_instance(ship_instance_id)
	var blueprint := GameState.get_ship_blueprint_data(ship_instance_id)

	if instance.is_empty() or blueprint.is_empty():
		title_label.text = "Error: Ship Not Found"
		return

	# Update title
	var ship_name := str(blueprint.get("ship_name", "Unknown"))
	var ship_subclass := str(blueprint.get("ship_sub_class", ""))
	title_label.text = "%s\n%s" % [ship_name, ship_subclass]

	# Load and display ship sprite
	_load_ship_sprite(instance.get("blueprint_id", ""))

	# Get calculated stats (with item bonuses)
	var calculated_stats := GameState.get_ship_calculated_stats(ship_instance_id)

	# Populate sections
	_populate_statistics(calculated_stats, blueprint)
	_populate_pilot(instance)
	_populate_weapons(instance, blueprint)
	_populate_upgrades(instance, blueprint)

func _load_ship_sprite(blueprint_id: String) -> void:
	"""Load and display the ship sprite"""
	if ship_sprite == null:
		return

	var visual_data := DataManager.get_ship_visual(blueprint_id)

	if not visual_data.is_empty() and visual_data.get("sprite_exists", false):
		var sprite_path: String = visual_data.get("sprite_path", "")

		if ResourceLoader.exists(sprite_path):
			ship_sprite.texture = load(sprite_path)
		else:
			print("[ShipDetailPopup] Ship sprite not found: %s" % sprite_path)
	else:
		print("[ShipDetailPopup] No visual data for blueprint: %s" % blueprint_id)

# ============================================================
# STATISTICS SECTION
# ============================================================

func _populate_statistics(calculated_stats: Dictionary, base_stats: Dictionary) -> void:
	"""Populate the statistics grid with ship stats (calculated with bonuses)"""
	# Clear existing stat labels
	for child in statistics_grid.get_children():
		child.queue_free()

	# Get bonus data
	var flat_bonuses: Dictionary = calculated_stats.get("_flat_bonuses", {})
	var percent_bonuses: Dictionary = calculated_stats.get("_percent_bonuses", {})

	# Define the ship stats to display (using actual CSV column names)
	var stats := [
		{"key": "hull_points", "name": "Hull Points", "bonus_type": "flat"},
		{"key": "shield_points", "name": "Shield Points", "bonus_type": "flat"},
		{"key": "armor", "name": "Armor", "bonus_type": "flat"},
		{"key": "size_width", "name": "Width", "bonus_type": "none"},
		{"key": "size_height", "name": "Height", "bonus_type": "none"},
		{"key": "attack_damage", "name": "Damage", "bonus_type": "flat"},
		{"key": "projectile_count", "name": "Projectiles", "bonus_type": "none"},
		{"key": "attack_speed", "name": "Attack Speed", "bonus_type": "percent"},
		{"key": "attack_range", "name": "Attack Range", "bonus_type": "none"},
		{"key": "movement_speed", "name": "Movement Speed", "bonus_type": "percent"},
		{"key": "accuracy", "name": "Accuracy", "bonus_type": "none"},
		{"key": "evasion", "name": "Evasion", "bonus_type": "none"},
		{"key": "precision", "name": "Precision", "bonus_type": "percent"},
		{"key": "reinforced_armor", "name": "Reinforced Armor", "bonus_type": "none"},
		{"key": "energy_points", "name": "Energy Points", "bonus_type": "flat"},
		{"key": "amplitude", "name": "Amplitude", "bonus_type": "percent"},
		{"key": "frequency", "name": "Frequency", "bonus_type": "none"},
		{"key": "resilience", "name": "Resilience", "bonus_type": "percent"},
	]

	# Create label pairs for each stat
	for stat_def in stats:
		var stat_key: String = stat_def["key"]
		var stat_name: String = stat_def["name"]
		var bonus_type: String = stat_def["bonus_type"]

		var base_value = base_stats.get(stat_key, 0)
		var calculated_value = calculated_stats.get(stat_key, base_value)

		# Stat name label (extra large for mobile)
		var name_label := Label.new()
		name_label.text = "%s:" % stat_name
		name_label.add_theme_font_size_override("font_size", 36)
		statistics_grid.add_child(name_label)

		# Stat value label (extra large for mobile)
		var value_label := Label.new()

		# Format value based on bonus type
		if bonus_type == "flat":
			var bonus: int = flat_bonuses.get(stat_key.replace("size_", "").replace("attack_", "").replace("projectile_count", "projectiles"), 0)
			if stat_key == "attack_damage":
				bonus = flat_bonuses.get("attack_damage", 0)
			elif stat_key == "energy_points":
				bonus = flat_bonuses.get("energy_points", 0)

			if bonus > 0:
				value_label.text = "%s (+%d)" % [str(calculated_value), bonus]
				value_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))  # Bright green
			else:
				value_label.text = str(calculated_value)
				value_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))

		elif bonus_type == "percent":
			var bonus_percent: float = percent_bonuses.get(stat_key, 0.0)
			if bonus_percent > 0:
				value_label.text = "%.1f (+%d%%)" % [calculated_value, int(bonus_percent)]
				value_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))  # Bright green
			else:
				value_label.text = str(calculated_value)
				value_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))

		else:  # No bonus
			value_label.text = str(calculated_value)
			value_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))

		value_label.add_theme_font_size_override("font_size", 36)
		statistics_grid.add_child(value_label)

	# Add regen stats if they exist
	var hull_regen: float = calculated_stats.get("hull_regen_per_sec", 0.0)
	var energy_regen: float = calculated_stats.get("energy_regen_per_sec", 0.0)

	if hull_regen > 0:
		var name_label := Label.new()
		name_label.text = "Hull Regen/sec:"
		name_label.add_theme_font_size_override("font_size", 36)
		statistics_grid.add_child(name_label)

		var value_label := Label.new()
		value_label.text = "%.1f" % hull_regen
		value_label.add_theme_font_size_override("font_size", 36)
		value_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))  # Bright green (bonus stat)
		statistics_grid.add_child(value_label)

	if energy_regen > 0:
		var name_label := Label.new()
		name_label.text = "Energy Regen/sec:"
		name_label.add_theme_font_size_override("font_size", 36)
		statistics_grid.add_child(name_label)

		var value_label := Label.new()
		value_label.text = "%.1f" % energy_regen
		value_label.add_theme_font_size_override("font_size", 36)
		value_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))  # Bright green (bonus stat)
		statistics_grid.add_child(value_label)

# ============================================================
# PILOT SECTION
# ============================================================

func _populate_pilot(instance: Dictionary) -> void:
	"""Populate pilot information"""
	var pilot_id: String = instance.get("pilot_id", "")

	# Set extra large font size for mobile
	pilot_info.add_theme_font_size_override("font_size", 36)

	if pilot_id.is_empty():
		pilot_info.text = "No pilot assigned"
		pilot_info.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	else:
		# TODO: Get pilot data from DataManager once personnel_database.csv is populated
		pilot_info.text = "Pilot: %s (placeholder)" % pilot_id
		pilot_info.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))

# ============================================================
# WEAPONS SECTION
# ============================================================

func _populate_weapons(instance: Dictionary, blueprint: Dictionary) -> void:
	"""Populate weapons list"""
	# Clear existing weapon labels
	for child in weapons_container.get_children():
		child.queue_free()
	
	var weapon_slots: int = int(blueprint.get("weapon_slots", 1))
	var equipped_weapons: Array = instance.get("equipped_weapons", [])
	
	# Ensure equipped_weapons array matches slot count
	while equipped_weapons.size() < weapon_slots:
		equipped_weapons.append("")
	
	# Display each weapon slot
	for i in range(weapon_slots):
		var weapon_id: String = equipped_weapons[i] if i < equipped_weapons.size() else ""

		var weapon_label := Label.new()
		if weapon_id.is_empty():
			weapon_label.text = "Slot %d: Empty" % (i + 1)
			weapon_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		else:
			# TODO: Get weapon data from DataManager
			weapon_label.text = "Slot %d: %s (placeholder)" % [i + 1, weapon_id]
			weapon_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))

		weapon_label.add_theme_font_size_override("font_size", 36)
		weapons_container.add_child(weapon_label)

# ============================================================
# UPGRADES SECTION
# ============================================================

func _populate_upgrades(instance: Dictionary, blueprint: Dictionary) -> void:
	"""Populate upgrades/relics list"""
	# Clear existing upgrade labels
	for child in upgrades_container.get_children():
		child.queue_free()
	
	var upgrade_slots: int = int(blueprint.get("upgrade_slots", 1))
	var equipped_upgrades: Array = instance.get("equipped_upgrades", [])
	
	# Ensure equipped_upgrades array matches slot count
	while equipped_upgrades.size() < upgrade_slots:
		equipped_upgrades.append("")
	
	# Display each upgrade slot
	for i in range(upgrade_slots):
		var upgrade_id: String = equipped_upgrades[i] if i < equipped_upgrades.size() else ""

		var upgrade_label := Label.new()
		if upgrade_id.is_empty():
			upgrade_label.text = "Slot %d: Empty" % (i + 1)
			upgrade_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		else:
			# Get upgrade data from DataManager
			var upgrade_data: Dictionary = DataManager.get_relic_t1(upgrade_id)
			if not upgrade_data.is_empty():
				var upgrade_name: String = upgrade_data.get("item_name", upgrade_id)
				upgrade_label.text = "Slot %d: %s" % [i + 1, upgrade_name]
				upgrade_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))  # Gold
			else:
				upgrade_label.text = "Slot %d: %s (unknown)" % [i + 1, upgrade_id]

		upgrade_label.add_theme_font_size_override("font_size", 36)
		upgrades_container.add_child(upgrade_label)
