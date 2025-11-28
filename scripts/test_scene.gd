extends Control

# ============================================================
# TEST SCENE - Phase 1 Verification
# ============================================================
# Purpose: Simple scene to test autoloads and see console output
# ============================================================

@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel
@onready var data_label: Label = $CenterContainer/VBoxContainer/DataLabel
@onready var data_viewer_button: Button = $CenterContainer/VBoxContainer/DataViewerButton

func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("TEST SCENE LOADED")
	print("=".repeat(60) + "\n")

	# Wait for data to load
	if DataManager.is_loaded:
		_on_data_loaded()
	else:
		EventBus.all_data_loaded.connect(_on_data_loaded)

	# Connect button
	data_viewer_button.pressed.connect(_on_data_viewer_pressed)

	# Update status
	status_label.text = "Phase 1 Test Scene\nWaiting for data to load..."

func _on_data_loaded() -> void:
	print("\n[TestScene] Data loading complete! Updating UI...")

	status_label.text = "Phase 1 Test Scene\nData Loaded Successfully!"

	# Display data summary
	var summary := "=== CORE DATA ===\n"
	summary += "Ships: %d\n" % DataManager.ships.size()
	summary += "Abilities: %d\n" % DataManager.abilities.size()
	summary += "Status Effects: %d\n" % DataManager.status_effects.size()
	summary += "Elemental Combos: %d\n" % DataManager.combos.size()
	summary += "\n=== ITEMS & EQUIPMENT ===\n"
	summary += "Relics T1: %d\n" % DataManager.relics_t1.size()
	summary += "Relics T2: %d\n" % DataManager.relics_t2.size()
	summary += "Weapons: %d\n" % DataManager.weapons.size()
	summary += "Drones: %d\n" % DataManager.drones.size()
	summary += "Powerups: %d\n" % DataManager.powerups.size()
	summary += "Blueprints: %d\n" % DataManager.blueprints.size()
	summary += "\n=== VISUALS ===\n"
	summary += "Ship Visuals: %d\n" % DataManager.ship_visuals.size()
	summary += "Drone Visuals: %d\n" % DataManager.drone_visuals.size()
	summary += "\n=== SECTOR EXPLORATION ===\n"
	summary += "Sector Nodes: %d (base + band-exclusive)\n" % DataManager.sector_nodes.size()
	summary += "Environment Bands: %d\n" % DataManager.environment_bands.size()
	summary += "Node Weights: %d\n" % DataManager.environment_node_weights.size()
	summary += "Sector Progression: %d\n" % DataManager.sector_progression.size()
	summary += "\n=== PLACEHOLDERS ===\n"
	summary += "Combat Scenarios: %d\n" % DataManager.combat_scenarios.size()
	summary += "Personnel: %d\n" % DataManager.personnel.size()

	data_label.text = summary

	print("[TestScene] UI updated with data summary")

	# Test query function
	var first_ship_id := DataManager.get_all_ship_ids()[0] if DataManager.ships.size() > 0 else ""
	if not first_ship_id.is_empty():
		print("\n[TestScene] Testing query function with ship: " + first_ship_id)
		DataManager.print_ship_data(first_ship_id)

func _on_data_viewer_pressed() -> void:
	print("[TestScene] Opening Data Viewer...")
	get_tree().change_scene_to_file("res://scenes/debug/data_viewer.tscn")
