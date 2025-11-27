extends Control

# ============================================================
# DATA VIEWER - DEBUG TOOL
# ============================================================
# Purpose: Browse and inspect all loaded CSV databases
# Allows verification of DataManager and data integrity
# ============================================================

@onready var database_dropdown: OptionButton = $MarginContainer/VBoxContainer/TopBar/DatabaseDropdown
@onready var record_dropdown: OptionButton = $MarginContainer/VBoxContainer/TopBar/RecordDropdown
@onready var data_display: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/DataDisplay
@onready var back_button: Button = $MarginContainer/VBoxContainer/BottomBar/BackButton

var current_database: Dictionary = {}
var current_database_name: String = ""

# Database mapping
var database_map: Dictionary = {}

# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
	# Wait for DataManager to load
	if not DataManager.is_loaded:
		await EventBus.all_data_loaded

	_initialize_database_map()
	_populate_database_dropdown()

	# Connect signals
	database_dropdown.item_selected.connect(_on_database_selected)
	record_dropdown.item_selected.connect(_on_record_selected)
	back_button.pressed.connect(_on_back_pressed)

	print("[DataViewer] Initialized")

func _initialize_database_map() -> void:
	database_map = {
		"Ships": DataManager.ships,
		"Abilities": DataManager.abilities,
		"Upgrades": DataManager.upgrades,
		"Status Effects": DataManager.status_effects,
		"Elemental Combos": DataManager.combos,
		"Weapons": DataManager.weapons,
		"Drones": DataManager.drones,
		"Powerups": DataManager.powerups,
		"Blueprints": DataManager.blueprints,
		"Ship Visuals": DataManager.ship_visuals,
		"Drone Visuals": DataManager.drone_visuals,
		"Combat Scenarios": DataManager.combat_scenarios,
		"Personnel": DataManager.personnel,
	}

# ============================================================
# DROPDOWN POPULATION
# ============================================================

func _populate_database_dropdown() -> void:
	database_dropdown.clear()

	for db_name: String in database_map.keys():
		var db: Dictionary = database_map[db_name]
		var item_text := "%s (%d)" % [db_name, db.size()]
		database_dropdown.add_item(item_text)

	if database_dropdown.item_count > 0:
		database_dropdown.select(0)
		_on_database_selected(0)

func _populate_record_dropdown() -> void:
	record_dropdown.clear()

	if current_database.is_empty():
		record_dropdown.add_item("(No records)")
		record_dropdown.disabled = true
		return

	record_dropdown.disabled = false

	for record_id: String in current_database.keys():
		record_dropdown.add_item(record_id)

	if record_dropdown.item_count > 0:
		record_dropdown.select(0)
		_on_record_selected(0)

# ============================================================
# SIGNAL HANDLERS
# ============================================================

func _on_database_selected(index: int) -> void:
	var full_text := database_dropdown.get_item_text(index)
	# Extract database name (before the count)
	var parts := full_text.split(" (")
	current_database_name = parts[0] if parts.size() > 0 else ""

	current_database = database_map.get(current_database_name, {})
	_populate_record_dropdown()

	print("[DataViewer] Selected database: %s (%d records)" % [current_database_name, current_database.size()])

func _on_record_selected(index: int) -> void:
	if record_dropdown.item_count == 0:
		return

	var record_id := record_dropdown.get_item_text(index)
	var record: Dictionary = current_database.get(record_id, {})

	_display_record(record_id, record)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/test_scene.tscn")

# ============================================================
# DATA DISPLAY
# ============================================================

func _display_record(record_id: String, record: Dictionary) -> void:
	# Clear previous display
	for child in data_display.get_children():
		child.queue_free()

	if record.is_empty():
		var label := Label.new()
		label.text = "No data available"
		label.add_theme_color_override("font_color", Color(0.8, 0.4, 0.4))
		data_display.add_child(label)
		return

	# Title
	var title := Label.new()
	title.text = "=== %s: %s ===" % [current_database_name, record_id]
	title.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	title.add_theme_font_size_override("font_size", 20)
	data_display.add_child(title)

	# Spacer
	var spacer1 := Control.new()
	spacer1.custom_minimum_size = Vector2(0, 10)
	data_display.add_child(spacer1)

	# Display each key-value pair
	for key: String in record.keys():
		var value: Variant = record[key]
		var value_str := str(value)

		# Create key-value label
		var kv_label := Label.new()
		kv_label.text = "%s: %s" % [key, value_str]

		# Color code by type
		if value is int or value is float:
			kv_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))  # Green for numbers
		elif value is bool:
			kv_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.6))  # Yellow for booleans
		else:
			kv_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))  # Blue for strings

		data_display.add_child(kv_label)

	print("[DataViewer] Displaying record: %s" % record_id)
