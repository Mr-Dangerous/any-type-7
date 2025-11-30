extends Node

## IndicatorManager
## Global autoload singleton for managing visual feedback indicators across all game modules.
## Provides pulsing indicators, cooldown displays, charge effects, and other visual feedback.
##
## Usage:
##   IndicatorManager.show_jump_indicator(Vector2(540, 1950))
##   IndicatorManager.hide_jump_indicator()
##
## Future expansion:
##   - Cooldown indicators (circular progress)
##   - Charge indicators (fill-up effects)
##   - Damage numbers (floating text)
##   - Status effect icons (buffs/debuffs)

# ============================================================
# CONSTANTS - Visual Styling
# ============================================================

## Jump indicator appearance
const JUMP_INDICATOR_SIZE: float = 50.0  # Base diameter in pixels
const JUMP_PULSE_MIN_SCALE: float = 0.7  # Smallest scale during pulse
const JUMP_PULSE_MAX_SCALE: float = 1.3  # Largest scale during pulse
const JUMP_PULSE_SPEED: float = 2.0      # Pulses per second
const JUMP_GLOW_SIZE: float = 80.0       # Outer glow diameter
const JUMP_CENTER_SIZE: float = 15.0     # White center dot diameter

## Cooldown indicator appearance
const COOLDOWN_INDICATOR_RADIUS: float = 40.0  # Circle radius in pixels
const COOLDOWN_INDICATOR_WIDTH: float = 6.0    # Arc thickness

## Colors
const JUMP_COLOR_PRIMARY := Color(1.0, 0.9, 0.2, 1.0)    # Bright yellow/gold
const JUMP_COLOR_GLOW := Color(1.0, 0.85, 0.0, 0.6)     # Gold glow (semi-transparent)
const JUMP_COLOR_CENTER := Color(1.0, 1.0, 1.0, 1.0)    # White center
const COOLDOWN_COLOR_BG := Color(0.3, 0.3, 0.3, 0.5)    # Gray background
const COOLDOWN_COLOR_FILL := Color(1.0, 0.5, 0.0, 0.8)  # Orange fill

## Z-index layering
const INDICATOR_Z_INDEX: int = 100  # High z-index to appear above game elements

# ============================================================
# JUMP INDICATOR STATE
# ============================================================

var jump_indicator: CanvasLayer = null
var jump_indicator_sprite: Node2D = null
var jump_pulse_timer: float = 0.0
var jump_indicator_visible: bool = false
var jump_target_position: Vector2 = Vector2.ZERO

# ============================================================
# COOLDOWN INDICATOR STATE
# ============================================================

var cooldown_indicator: CanvasLayer = null
var cooldown_indicator_sprite: Node2D = null
var cooldown_indicator_visible: bool = false
var cooldown_progress: float = 0.0  # 0.0 to 1.0 (1.0 = cooldown complete)
var cooldown_position: Vector2 = Vector2.ZERO


# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
	# Create indicators on ready (persist across scenes)
	_create_jump_indicator()
	_create_cooldown_indicator()

	print("[IndicatorManager] Initialized - Global visual feedback system ready")


func _process(delta: float) -> void:
	# Update pulse animation if jump indicator is visible
	if jump_indicator_visible and jump_indicator_sprite:
		_update_jump_pulse(delta)

	# Cooldown indicator is updated externally via update_cooldown_indicator()


# ============================================================
# JUMP INDICATOR - Public API
# ============================================================

func show_jump_indicator(world_position: Vector2) -> void:
	"""
	Display a pulsing jump indicator at the specified world position.

	Args:
		world_position: World coordinates where the indicator should appear

	Usage:
		IndicatorManager.show_jump_indicator(Vector2(540, 1950))
	"""
	if not jump_indicator or not jump_indicator_sprite:
		push_error("[IndicatorManager] Jump indicator not initialized")
		return

	# Update position
	jump_target_position = world_position
	jump_indicator_sprite.position = world_position

	# Show indicator
	jump_indicator_visible = true
	jump_indicator.visible = true

	# Reset pulse timer for smooth animation start
	jump_pulse_timer = 0.0


func hide_jump_indicator() -> void:
	"""
	Hide the jump indicator.

	Usage:
		IndicatorManager.hide_jump_indicator()
	"""
	if not jump_indicator:
		return

	jump_indicator_visible = false
	jump_indicator.visible = false


func is_jump_indicator_visible() -> bool:
	"""
	Check if the jump indicator is currently visible.

	Returns:
		bool: True if indicator is visible, false otherwise
	"""
	return jump_indicator_visible


func get_jump_indicator_position() -> Vector2:
	"""
	Get the current world position of the jump indicator.

	Returns:
		Vector2: World coordinates of the indicator
	"""
	return jump_target_position


# ============================================================
# COOLDOWN INDICATOR - Public API
# ============================================================

func show_cooldown_indicator(world_position: Vector2) -> void:
	"""
	Display a circular cooldown indicator at the specified world position.

	Args:
		world_position: World coordinates where the indicator should appear (typically over the ship)

	Usage:
		IndicatorManager.show_cooldown_indicator(Vector2(540, 1950))
	"""
	if not cooldown_indicator or not cooldown_indicator_sprite:
		push_error("[IndicatorManager] Cooldown indicator not initialized")
		return

	# Update position
	cooldown_position = world_position
	cooldown_indicator_sprite.position = world_position

	# Show indicator
	cooldown_indicator_visible = true
	cooldown_indicator.visible = true


func update_cooldown_indicator(progress: float) -> void:
	"""
	Update the cooldown progress (0.0 to 1.0).

	Args:
		progress: Cooldown progress from 0.0 (just started) to 1.0 (complete)

	Usage:
		IndicatorManager.update_cooldown_indicator(0.5)  # 50% complete
	"""
	if not cooldown_indicator_sprite:
		return

	cooldown_progress = clamp(progress, 0.0, 1.0)
	cooldown_indicator_sprite.queue_redraw()


func hide_cooldown_indicator() -> void:
	"""
	Hide the cooldown indicator.

	Usage:
		IndicatorManager.hide_cooldown_indicator()
	"""
	if not cooldown_indicator:
		return

	cooldown_indicator_visible = false
	cooldown_indicator.visible = false


# ============================================================
# JUMP INDICATOR - Internal Implementation
# ============================================================

func _create_jump_indicator() -> void:
	"""Create the persistent jump indicator node tree"""
	# Create CanvasLayer to ensure indicator renders on top
	jump_indicator = CanvasLayer.new()
	jump_indicator.name = "JumpIndicatorLayer"
	jump_indicator.layer = INDICATOR_Z_INDEX
	jump_indicator.visible = false
	add_child(jump_indicator)

	# Create Node2D container for positioning with custom drawing
	jump_indicator_sprite = JumpIndicatorDrawer.new()
	jump_indicator_sprite.name = "JumpIndicatorSprite"
	jump_indicator.add_child(jump_indicator_sprite)

	print("[IndicatorManager] Jump indicator created (CanvasLayer-based, persistent)")


func _update_jump_pulse(delta: float) -> void:
	"""Update pulsing animation for jump indicator"""
	if not jump_indicator_sprite:
		return

	# Update pulse timer
	jump_pulse_timer += delta * JUMP_PULSE_SPEED

	# Calculate pulsing scale (sine wave from min to max)
	var pulse_phase = sin(jump_pulse_timer * TAU)  # -1 to +1
	var scale_range = JUMP_PULSE_MAX_SCALE - JUMP_PULSE_MIN_SCALE
	var current_scale = JUMP_PULSE_MIN_SCALE + (scale_range * (pulse_phase + 1.0) / 2.0)

	# Apply scale
	jump_indicator_sprite.scale = Vector2(current_scale, current_scale)

	# Queue redraw for custom drawing
	jump_indicator_sprite.queue_redraw()


# ============================================================
# COOLDOWN INDICATOR - Internal Implementation
# ============================================================

func _create_cooldown_indicator() -> void:
	"""Create the persistent cooldown indicator node tree"""
	# Create CanvasLayer to ensure indicator renders on top
	cooldown_indicator = CanvasLayer.new()
	cooldown_indicator.name = "CooldownIndicatorLayer"
	cooldown_indicator.layer = INDICATOR_Z_INDEX
	cooldown_indicator.visible = false
	add_child(cooldown_indicator)

	# Create Node2D container with custom drawing
	cooldown_indicator_sprite = CooldownIndicatorDrawer.new()
	cooldown_indicator_sprite.name = "CooldownIndicatorSprite"
	cooldown_indicator.add_child(cooldown_indicator_sprite)

	print("[IndicatorManager] Cooldown indicator created (CanvasLayer-based, persistent)")


# ============================================================
# CUSTOM DRAWING - Jump Indicator
# ============================================================

## Note: This is a placeholder for future visual implementation
## The actual drawing will be implemented when needed, or replaced with sprite-based rendering
##
## Current implementation uses scale animation on a Node2D
## Future: Add custom _draw() function to draw circles/glows
## Or: Replace with animated sprite sheets for better visual quality


# ============================================================
# FUTURE EXPANSION - Cooldown Indicators (NOW IMPLEMENTED)
# ============================================================

## Cooldown indicators are now implemented! See:
##   - show_cooldown_indicator(world_position)
##   - update_cooldown_indicator(progress)
##   - hide_cooldown_indicator()
## in the "COOLDOWN INDICATOR - Public API" section above


# ============================================================
# FUTURE EXPANSION - Charge Indicators
# ============================================================

## TODO: Implement charge indicator system (fill-up progress bar/circle)
## Usage:
##   IndicatorManager.show_charge_indicator(position)
##   IndicatorManager.update_charge_progress(progress)  # 0.0 to 1.0
##   IndicatorManager.hide_charge_indicator()

func show_charge_indicator(_position: Vector2) -> void:
	"""
	Show a charge-up indicator (future implementation).

	Args:
		_position: World position for the charge indicator
	"""
	push_warning("[IndicatorManager] Charge indicators not yet implemented")


func update_charge_progress(_progress: float) -> void:
	"""
	Update charge indicator progress (future implementation).

	Args:
		_progress: Progress value from 0.0 (empty) to 1.0 (full)
	"""
	push_warning("[IndicatorManager] Charge indicators not yet implemented")


func hide_charge_indicator() -> void:
	"""Hide the charge indicator (future implementation)."""
	push_warning("[IndicatorManager] Charge indicators not yet implemented")


# ============================================================
# FUTURE EXPANSION - Damage Numbers
# ============================================================

## TODO: Implement floating damage number system
## Usage:
##   IndicatorManager.show_damage_number(position, damage, is_critical)

func show_damage_number(_position: Vector2, _damage: int, _is_critical: bool = false) -> void:
	"""
	Show floating damage number (future implementation).

	Args:
		_position: World position where damage occurred
		_damage: Damage amount to display
		_is_critical: Whether this is a critical hit (different styling)
	"""
	push_warning("[IndicatorManager] Damage numbers not yet implemented")


# ============================================================
# FUTURE EXPANSION - Status Effect Icons
# ============================================================

## TODO: Implement status effect icon system
## Usage:
##   IndicatorManager.show_status_icon(target_node, effect_type, duration)

func show_status_icon(_target_node: Node2D, _effect_type: String, _duration: float) -> String:
	"""
	Show a status effect icon above a target (future implementation).

	Args:
		_target_node: Node to attach the icon to
		_effect_type: Type of status effect (burn, freeze, etc.)
		_duration: Duration in seconds

	Returns:
		String: Unique ID for this status icon
	"""
	push_warning("[IndicatorManager] Status effect icons not yet implemented")
	return ""


func hide_status_icon(_id: String) -> void:
	"""
	Hide a specific status effect icon (future implementation).

	Args:
		_id: Unique ID of the status icon to hide
	"""
	push_warning("[IndicatorManager] Status effect icons not yet implemented")


# ============================================================
# UTILITY FUNCTIONS
# ============================================================

func clear_all_indicators() -> void:
	"""
	Clear all active indicators (useful for scene transitions).

	Usage:
		IndicatorManager.clear_all_indicators()
	"""
	# Hide all indicators
	hide_jump_indicator()
	hide_cooldown_indicator()

	print("[IndicatorManager] All indicators cleared")


func _notification(what: int) -> void:
	"""Handle scene changes and cleanup"""
	if what == NOTIFICATION_PREDELETE:
		# Cleanup on deletion
		if jump_indicator:
			jump_indicator.queue_free()


# ============================================================
# INNER CLASS - Jump Indicator Drawer
# ============================================================

class JumpIndicatorDrawer extends Node2D:
	"""Custom Node2D class that draws the jump indicator visual"""

	func _draw() -> void:
		# Draw outer glow (large, semi-transparent)
		var glow_radius = IndicatorManager.JUMP_GLOW_SIZE / 2.0
		draw_circle(
			Vector2.ZERO,
			glow_radius,
			IndicatorManager.JUMP_COLOR_GLOW
		)

		# Draw main indicator (bright yellow/gold)
		var main_radius = IndicatorManager.JUMP_INDICATOR_SIZE / 2.0
		draw_circle(
			Vector2.ZERO,
			main_radius,
			IndicatorManager.JUMP_COLOR_PRIMARY
		)

		# Draw white center dot
		var center_radius = IndicatorManager.JUMP_CENTER_SIZE / 2.0
		draw_circle(
			Vector2.ZERO,
			center_radius,
			IndicatorManager.JUMP_COLOR_CENTER
		)


# ============================================================
# INNER CLASS - Cooldown Indicator Drawer
# ============================================================

class CooldownIndicatorDrawer extends Node2D:
	"""Custom Node2D class that draws the circular cooldown indicator"""

	func _draw() -> void:
		var radius = IndicatorManager.COOLDOWN_INDICATOR_RADIUS
		var width = IndicatorManager.COOLDOWN_INDICATOR_WIDTH
		var progress = IndicatorManager.cooldown_progress

		# Draw background circle (gray, full circle)
		draw_arc(
			Vector2.ZERO,
			radius,
			0.0,
			TAU,
			64,
			IndicatorManager.COOLDOWN_COLOR_BG,
			width
		)

		# Draw progress arc (orange, fills up as cooldown progresses)
		# Start from top (- PI/2) and fill clockwise
		var start_angle = -PI / 2.0
		var end_angle = start_angle + (TAU * progress)

		if progress > 0.0:
			draw_arc(
				Vector2.ZERO,
				radius,
				start_angle,
				end_angle,
				64,
				IndicatorManager.COOLDOWN_COLOR_FILL,
				width
			)
