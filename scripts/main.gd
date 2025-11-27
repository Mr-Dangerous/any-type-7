extends Control

# ============================================================
# MAIN SCENE - GAME ENTRY POINT
# ============================================================
# Purpose: Root scene with portrait UI framework
# Displays resources and provides navigation
# ============================================================

@onready var metal_label: Label = $CanvasLayer/MarginContainer/VBoxContainer/ResourcePanel/ResourceGrid/MetalLabel
@onready var crystals_label: Label = $CanvasLayer/MarginContainer/VBoxContainer/ResourcePanel/ResourceGrid/CrystalsLabel
@onready var fuel_label: Label = $CanvasLayer/MarginContainer/VBoxContainer/ResourcePanel/ResourceGrid/FuelLabel

@onready var start_button: Button = $CanvasLayer/MarginContainer/VBoxContainer/MenuPanel/VBoxContainer/StartButton
@onready var data_viewer_button: Button = $CanvasLayer/MarginContainer/VBoxContainer/MenuPanel/VBoxContainer/DataViewerButton
@onready var debug_button: Button = $CanvasLayer/MarginContainer/VBoxContainer/MenuPanel/VBoxContainer/DebugButton
@onready var quit_button: Button = $CanvasLayer/MarginContainer/VBoxContainer/MenuPanel/VBoxContainer/QuitButton

# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
	print("[Main] Main scene loaded")

	# Wait for data to load
	if not DataManager.is_loaded:
		await EventBus.all_data_loaded

	# Connect EventBus signals
	EventBus.resource_changed.connect(_on_resource_changed)

	# Connect button signals
	start_button.pressed.connect(_on_start_pressed)
	data_viewer_button.pressed.connect(_on_data_viewer_pressed)
	debug_button.pressed.connect(_on_debug_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Initialize display
	_update_resource_display()

	print("[Main] UI initialized and ready")

# ============================================================
# RESOURCE DISPLAY
# ============================================================

func _update_resource_display() -> void:
	metal_label.text = "Metal: %d" % ResourceManager.get_metal()
	crystals_label.text = "Crystals: %d" % ResourceManager.get_crystals()
	fuel_label.text = "Fuel: %d" % ResourceManager.get_fuel()

func _on_resource_changed(_type: String, _old: int, _new: int) -> void:
	_update_resource_display()

# ============================================================
# BUTTON HANDLERS
# ============================================================

func _on_start_pressed() -> void:
	print("[Main] Start button pressed - Game start not implemented yet (Phase 2)")
	EventBus.notification_shown.emit("Game start coming in Phase 2!", "info")

func _on_data_viewer_pressed() -> void:
	print("[Main] Opening Data Viewer...")
	get_tree().change_scene_to_file("res://scenes/debug/data_viewer.tscn")

func _on_debug_pressed() -> void:
	print("[Main] Debug button pressed")

	# Print all system states
	print("\n" + "=".repeat(60))
	print("DEBUG INFO")
	print("=".repeat(60))

	GameState.print_state()
	ResourceManager.print_resources()
	DataManager._print_load_summary()

	print("=".repeat(60) + "\n")

	EventBus.notification_shown.emit("Debug info printed to console", "info")

func _on_quit_pressed() -> void:
	print("[Main] Quit button pressed")
	get_tree().quit()
