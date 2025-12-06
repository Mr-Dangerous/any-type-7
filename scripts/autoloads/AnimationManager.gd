extends Node

# ============================================================
# ANIMATION MANAGER - VISUAL FEEDBACK SYSTEM
# ============================================================
# Purpose: Reusable animation system for visual feedback
# Handles flying icons, number counting, pulse effects, tweens
# Used across all modules for consistent visual polish
# ============================================================

# ============================================================
# RESOURCE ICON PATHS
# ============================================================

const ICON_PATHS = {
	"metal": "res://assets/Icons/metal_small_icon.png",
	"crystals": "res://assets/Icons/crystal_small_icon.png",
	"fuel": "res://assets/Icons/fuel_icon.png"
}

# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
	print("[AnimationManager] Initialized - Visual feedback system ready")


# ============================================================
# FLYING ICON ANIMATION
# ============================================================

func create_flying_icon(parent: Node, resource_type: String, from_position: Vector2,
		to_position: Vector2, duration: float = 0.5, on_complete: Callable = Callable()) -> void:
	"""Create a flying icon that moves from point A to B"""
	# Get icon path
	var icon_path = ICON_PATHS.get(resource_type, "")
	if icon_path == "" or not FileAccess.file_exists(icon_path):
		print("[AnimationManager] Warning: Icon not found for %s" % resource_type)
		if on_complete.is_valid():
			on_complete.call()
		return

	# Create flying icon
	var flying_icon = Sprite2D.new()
	flying_icon.texture = load(icon_path)
	flying_icon.scale = Vector2(0.6, 0.6)
	flying_icon.z_index = 200  # Above everything
	flying_icon.global_position = from_position
	parent.add_child(flying_icon)

	# Animate icon flying to target
	var tween = parent.create_tween()
	tween.set_parallel(true)
	tween.tween_property(flying_icon, "global_position", to_position, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(flying_icon, "scale", Vector2(0.3, 0.3), duration).set_trans(Tween.TRANS_CUBIC)
	tween.chain().tween_callback(func():
		flying_icon.queue_free()
		if on_complete.is_valid():
			on_complete.call()
	)


# ============================================================
# NUMBER COUNTING ANIMATION
# ============================================================

func animate_number_count(parent: Node, label: Label, from_value: int, to_value: int,
		duration: float = 0.3) -> void:
	"""Animate a label counting from one value to another"""
	if not label or not is_instance_valid(label):
		return

	var tween = parent.create_tween()
	tween.tween_method(func(val): label.text = str(int(val)), from_value, to_value, duration)


# ============================================================
# SCALE PULSE ANIMATION
# ============================================================

func pulse_scale(parent: Node, target: Control, scale_to: Vector2 = Vector2(1.15, 1.15),
		pulse_duration: float = 0.1, return_duration: float = 0.2) -> void:
	"""Scale pulse animation for UI elements"""
	if not target or not is_instance_valid(target):
		return

	var tween = parent.create_tween()
	tween.set_parallel(false)
	tween.tween_property(target, "scale", scale_to, pulse_duration).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(target, "scale", Vector2(1.0, 1.0), return_duration).set_trans(Tween.TRANS_CUBIC)


# ============================================================
# COLOR FLASH ANIMATION
# ============================================================

func flash_color(parent: Node, target: Control, flash_color: Color, duration: float = 0.2) -> void:
	"""Flash a control to a color and back"""
	if not target or not is_instance_valid(target):
		return

	var original_modulate = target.modulate
	var tween = parent.create_tween()
	tween.set_parallel(false)
	tween.tween_property(target, "modulate", flash_color, duration / 2.0)
	tween.tween_property(target, "modulate", original_modulate, duration / 2.0)


# ============================================================
# FLOATING TEXT ANIMATION
# ============================================================

func create_floating_text(parent: Node, text: String, position: Vector2, color: Color,
		font_size: int = 32, duration: float = 1.0, rise_amount: float = 50.0) -> void:
	"""Create floating text that rises and fades"""
	var label = Label.new()
	label.text = text
	label.position = position - Vector2(50, 25)  # Center roughly
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.z_index = 300  # Very high
	parent.add_child(label)

	# Animate rising and fading
	var tween = parent.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", position.y - rise_amount, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_CUBIC)
	tween.chain().tween_callback(func(): label.queue_free())


# ============================================================
# SHAKE ANIMATION
# ============================================================

func shake_node(parent: Node, target: Node2D, intensity: float = 10.0, duration: float = 0.3,
		frequency: float = 30.0) -> void:
	"""Shake a node with random offset"""
	if not target or not is_instance_valid(target):
		return

	var original_position = target.position
	var shake_timer = 0.0
	var shake_interval = 1.0 / frequency

	# Create timer for shake updates
	var timer = Timer.new()
	timer.wait_time = shake_interval
	timer.one_shot = false
	parent.add_child(timer)

	timer.timeout.connect(func():
		shake_timer += shake_interval
		if shake_timer >= duration:
			target.position = original_position
			timer.queue_free()
		else:
			var progress = 1.0 - (shake_timer / duration)  # Decay over time
			var shake_x = randf_range(-intensity, intensity) * progress
			var shake_y = randf_range(-intensity, intensity) * progress
			target.position = original_position + Vector2(shake_x, shake_y)
	)

	timer.start()


# ============================================================
# BOUNCE ANIMATION
# ============================================================

func bounce_scale(parent: Node, target: Control, bounce_scale: float = 1.2,
		duration: float = 0.3) -> void:
	"""Bounce scale animation with overshoot"""
	if not target or not is_instance_valid(target):
		return

	var tween = parent.create_tween()
	tween.set_parallel(false)
	tween.tween_property(target, "scale", Vector2(bounce_scale, bounce_scale), duration / 2.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "scale", Vector2(1.0, 1.0), duration / 2.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)


# ============================================================
# FADE ANIMATION
# ============================================================

func fade_in(parent: Node, target: CanvasItem, duration: float = 0.3) -> void:
	"""Fade in from transparent to opaque"""
	if not target or not is_instance_valid(target):
		return

	target.modulate.a = 0.0
	var tween = parent.create_tween()
	tween.tween_property(target, "modulate:a", 1.0, duration)


func fade_out(parent: Node, target: CanvasItem, duration: float = 0.3,
		auto_free: bool = false) -> void:
	"""Fade out from opaque to transparent"""
	if not target or not is_instance_valid(target):
		return

	var tween = parent.create_tween()
	tween.tween_property(target, "modulate:a", 0.0, duration)
	if auto_free:
		tween.chain().tween_callback(func(): target.queue_free())


# ============================================================
# UTILITY FUNCTIONS
# ============================================================
# Note: In Godot 4.x, Tweens are RefCounted objects created by create_tween()
# They are automatically managed and cleaned up when they complete or when
# the parent node is freed. No manual cleanup needed in most cases.
