extends Node

# ============================================================
# UI MANAGER - UNIFIED HUD SYSTEM
# ============================================================
# Purpose: Coordinate UI/HUD across all game modules
# Handles UI element creation, updates, and references
# Provides consistent UI patterns across sector, combat, hangar
# ============================================================

# ============================================================
# UI REFERENCES (set by modules)
# ============================================================

# Sector exploration UI
var sector_distance_label: Label = null
var sector_timer_label: Label = null
var sector_tier_1_container: Node = null  # Container for Tier 1 upgrade icons
var sector_streak_label: Label = null
var sector_enemy_trigger_label: Label = null

# Resource display labels
var fuel_label: Label = null
var metal_label: Label = null
var crystals_label: Label = null
var speed_label: Label = null

# Resource display panels (for animations)
var fuel_panel: Control = null
var metal_panel: Control = null
var crystals_panel: Control = null

# Combat UI (future)
var combat_phase_label: Label = null
var combat_wave_label: Label = null

# Hangar UI (future)
var hangar_credits_label: Label = null

# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
	print("[UIManager] Initialized - Unified HUD system ready")


# ============================================================
# UI ELEMENT CREATION HELPERS
# ============================================================

func create_label(parent: Node, label_name: String, position: Vector2, size: Vector2,
		font_size: int, color: Color, initial_text: String = "") -> Label:
	"""Create a standardized label with common styling"""
	var label = Label.new()
	label.name = label_name
	label.position = position
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.text = initial_text
	parent.add_child(label)
	return label


func create_panel(parent: Node, panel_name: String, position: Vector2, size: Vector2) -> Panel:
	"""Create a standardized panel"""
	var panel = Panel.new()
	panel.name = panel_name
	panel.position = position
	panel.size = size
	parent.add_child(panel)
	return panel


# ============================================================
# SECTOR EXPLORATION UI REGISTRATION
# ============================================================

func register_sector_ui(distance: Label, timer: Label, tier_1_container: Node,
		fuel: Label, metal: Label, crystals: Label, speed: Label,
		fuel_pnl: Control, metal_pnl: Control, crystals_pnl: Control) -> void:
	"""Register sector exploration UI elements for updates"""
	sector_distance_label = distance
	sector_timer_label = timer
	sector_tier_1_container = tier_1_container
	fuel_label = fuel
	metal_label = metal
	crystals_label = crystals
	speed_label = speed
	fuel_panel = fuel_pnl
	metal_panel = metal_pnl
	crystals_panel = crystals_pnl
	print("[UIManager] Sector UI registered")


func register_sector_dynamic_ui(streak: Label, enemy_trigger: Label) -> void:
	"""Register dynamically created sector UI elements"""
	sector_streak_label = streak
	sector_enemy_trigger_label = enemy_trigger
	print("[UIManager] Sector dynamic UI registered")


# ============================================================
# UI UPDATE METHODS
# ============================================================

func update_sector_ui(scrolling_system: Node) -> void:
	"""Update sector exploration UI elements"""
	if sector_distance_label:
		sector_distance_label.text = scrolling_system.get_distance_display()

	if sector_timer_label:
		sector_timer_label.text = GameState.get_elapsed_time_formatted()

	# Tier 1 upgrades updated via signal (not every frame)

	if fuel_label:
		fuel_label.text = str(ResourceManager.get_resource("fuel"))

	if metal_label:
		metal_label.text = str(ResourceManager.get_resource("metal"))

	if crystals_label:
		crystals_label.text = str(ResourceManager.get_resource("crystals"))

	if speed_label:
		speed_label.text = "%.1fx" % scrolling_system.get_speed_multiplier()

	if sector_streak_label:
		sector_streak_label.text = GameState.get_streak_display()

	if sector_enemy_trigger_label:
		sector_enemy_trigger_label.text = "Enemy Hits: %d" % GameState.enemy_triggers


func update_resource_label(resource_type: String, value: int) -> void:
	"""Update a specific resource label"""
	match resource_type:
		"metal":
			if metal_label:
				metal_label.text = str(value)
		"crystals":
			if crystals_label:
				crystals_label.text = str(value)
		"fuel":
			if fuel_label:
				fuel_label.text = str(value)


# ============================================================
# UI GETTERS
# ============================================================

func get_resource_panel(resource_type: String) -> Control:
	"""Get resource panel for animations"""
	match resource_type:
		"metal":
			return metal_panel
		"crystals":
			return crystals_panel
		"fuel":
			return fuel_panel
	return null


func get_resource_label(resource_type: String) -> Label:
	"""Get resource label for updates"""
	match resource_type:
		"metal":
			return metal_label
		"crystals":
			return crystals_label
		"fuel":
			return fuel_label
	return null


# ============================================================
# TIER 1 UPGRADE DISPLAY
# ============================================================

func add_tier_1_upgrade_icon(item_id: String, icon_path: String) -> void:
	"""Add a Tier 1 upgrade icon to the display"""
	if not sector_tier_1_container:
		print("[UIManager] Warning: Tier 1 container not registered")
		return

	# Create icon sprite
	var icon = TextureRect.new()
	icon.name = item_id + "_icon"
	icon.custom_minimum_size = Vector2(40, 40)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Load texture
	if FileAccess.file_exists(icon_path):
		icon.texture = load(icon_path)
	else:
		print("[UIManager] Warning: Icon not found: %s" % icon_path)

	sector_tier_1_container.add_child(icon)
	print("[UIManager] Added Tier 1 upgrade icon: %s" % item_id)


# ============================================================
# UI CLEANUP
# ============================================================

func clear_sector_ui() -> void:
	"""Clear sector exploration UI references"""
	sector_distance_label = null
	sector_timer_label = null
	sector_tier_1_container = null
	sector_streak_label = null
	sector_enemy_trigger_label = null
	fuel_label = null
	metal_label = null
	crystals_label = null
	speed_label = null
	fuel_panel = null
	metal_panel = null
	crystals_panel = null
	print("[UIManager] Sector UI cleared")
