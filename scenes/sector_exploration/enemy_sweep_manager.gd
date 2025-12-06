extends Node

## Enemy Sweep Manager
## Manages alien sweep attack patterns during sector exploration

# References
var player_ship: Node2D = null
var world_container: Node2D = null
var ui_overlay: CanvasLayer = null
var scrolling_system: Node = null

# Sweep pattern data from CSV
var sweep_patterns: Array[Dictionary] = []
var enabled_patterns: Array[Dictionary] = []

# Timing configuration (tunable)
@export var initial_attack_delay: float = 25.0  # First attack after 25 seconds
@export var attack_interval: float = 20.0  # Subsequent attacks every 20 seconds

# Internal timing state
var time_until_next_attack: float = 0.0
var is_paused: bool = false
var attack_count: int = 0

# Warning system
var warning_overlay: ColorRect = null
var warning_label: Label = null
var warning_active: bool = false
var warning_time_remaining: float = 0.0
var current_warning_duration: float = 0.0

# Multi-pattern attack system (3 sweeps per attack)
var queued_patterns: Array[Dictionary] = []  # 3 patterns selected per attack
var spawn_queue: Array[Dictionary] = []  # Patterns waiting to spawn
var time_until_next_spawn: float = 0.0
const SPAWN_STAGGER_TIME: float = 1.0  # 1 second between spawns

# Active alien projectiles
var active_aliens: Array[Node2D] = []

# Screen dimensions
const SCREEN_WIDTH: float = 1080.0
const SCREEN_HEIGHT: float = 2340.0


func initialize(p_player_ship: Node2D, p_world_container: Node2D, p_ui_overlay: CanvasLayer, p_scrolling_system: Node) -> void:
	"""Initialize the enemy sweep manager"""
	player_ship = p_player_ship
	world_container = p_world_container
	ui_overlay = p_ui_overlay
	scrolling_system = p_scrolling_system

	# Load sweep patterns from CSV
	_load_sweep_patterns()

	# Create warning UI overlay
	_create_warning_ui()

	# Set initial countdown
	time_until_next_attack = initial_attack_delay

	print("[EnemySweepManager] Initialized - First attack in %.1f seconds" % initial_attack_delay)


func _load_sweep_patterns() -> void:
	"""Load alien sweep patterns from CSV"""
	var file = FileAccess.open("res://data/alien_sweep_patterns.csv", FileAccess.READ)
	if not file:
		push_error("[EnemySweepManager] Failed to open alien_sweep_patterns.csv")
		return

	# Skip header
	file.get_csv_line()

	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 7 or line[0] == "":
			continue

		var pattern = {
			"pattern_id": line[0],
			"pattern_type": line[1],
			"enabled": line[2].to_lower() == "yes",
			"base_speed": float(line[3]),
			"width_px": float(line[4]),
			"gap_px": float(line[5]),
			"min_sector": int(line[6]),
			"spawn_weight": int(line[7]),
			"description": line[8] if line.size() > 8 else ""
		}

		sweep_patterns.append(pattern)

		# Add to enabled patterns list
		if pattern.enabled:
			enabled_patterns.append(pattern)

	file.close()
	print("[EnemySweepManager] Loaded %d sweep patterns (%d enabled)" % [sweep_patterns.size(), enabled_patterns.size()])


func _create_warning_ui() -> void:
	"""Create warning flash overlay UI"""
	# Red semi-transparent overlay - centered behind text
	var overlay_width = 700.0
	var overlay_height = 180.0
	warning_overlay = ColorRect.new()
	warning_overlay.color = Color(1.0, 0.0, 0.0, 0.4)  # Red with 40% opacity (less obtrusive)
	warning_overlay.size = Vector2(overlay_width, overlay_height)
	warning_overlay.position = Vector2(
		(SCREEN_WIDTH - overlay_width) / 2,  # Centered horizontally
		SCREEN_HEIGHT / 2 - overlay_height / 2  # Centered vertically
	)
	warning_overlay.z_index = 90  # Below warning text
	warning_overlay.visible = false
	ui_overlay.add_child(warning_overlay)

	# Warning label - on top of overlay
	warning_label = Label.new()
	warning_label.text = "WARNING"
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	warning_label.position = Vector2(0, SCREEN_HEIGHT / 2 - 100)
	warning_label.size = Vector2(SCREEN_WIDTH, 200)
	warning_label.add_theme_font_size_override("font_size", 72)
	warning_label.add_theme_color_override("font_color", Color.WHITE)
	warning_label.z_index = 91  # Above overlay
	warning_label.visible = false
	ui_overlay.add_child(warning_label)


func _process(delta: float) -> void:
	"""Update sweep manager each frame"""
	if is_paused:
		return

	# Update warning flash
	if warning_active:
		warning_time_remaining -= delta

		# Pulse the warning (fade in/out)
		var pulse_progress = warning_time_remaining / current_warning_duration
		var pulse_alpha = 0.3 + 0.3 * sin(pulse_progress * PI * 8)  # Fast pulsing
		warning_overlay.color.a = pulse_alpha

		if warning_time_remaining <= 0.0:
			_hide_warning()
			_spawn_attack()

	# Update countdown to next attack (starts from first attack)
	if not warning_active:  # Don't count down during warning
		time_until_next_attack -= delta

		if time_until_next_attack <= 0.0:
			_trigger_warning()

	# Update active alien projectiles
	_update_aliens(delta)

	# Handle staggered pattern spawning
	if not spawn_queue.is_empty():
		time_until_next_spawn -= delta
		if time_until_next_spawn <= 0.0:
			var pattern = spawn_queue.pop_front()
			_spawn_single_pattern(pattern)
			if not spawn_queue.is_empty():
				time_until_next_spawn = SPAWN_STAGGER_TIME


func _select_three_patterns() -> Array[Dictionary]:
	"""Select 3 sweep patterns with no sequential duplicates"""
	var selected: Array[Dictionary] = []

	if enabled_patterns.size() < 2:
		# Not enough patterns for variety, just pick randomly
		for i in 3:
			selected.append(enabled_patterns.pick_random())
		return selected

	# Pick first pattern randomly
	selected.append(enabled_patterns.pick_random())

	# Pick second pattern (must be different from first)
	var second = enabled_patterns.pick_random()
	while second.pattern_id == selected[0].pattern_id:
		second = enabled_patterns.pick_random()
	selected.append(second)

	# Pick third pattern (must be different from second)
	var third = enabled_patterns.pick_random()
	while third.pattern_id == selected[1].pattern_id:
		third = enabled_patterns.pick_random()
	selected.append(third)

	return selected


func _trigger_warning() -> void:
	"""Trigger warning flash before attack"""
	if enabled_patterns.is_empty():
		push_warning("[EnemySweepManager] No enabled patterns available")
		return

	# Select 3 patterns (duplicates allowed, but no sequential duplicates)
	queued_patterns = _select_three_patterns()

	# Show warning (always 4 seconds)
	warning_active = true
	current_warning_duration = 4.0
	warning_time_remaining = current_warning_duration
	warning_overlay.visible = true
	warning_label.visible = true

	var pattern_names = ", ".join(queued_patterns.map(func(p): return p.pattern_id))
	print("[EnemySweepManager] WARNING - Triple sweep incoming: %s" % pattern_names)


func _hide_warning() -> void:
	"""Hide warning flash"""
	warning_active = false
	warning_overlay.visible = false
	warning_label.visible = false


func _spawn_attack() -> void:
	"""Spawn triple alien sweep attack (3 patterns with 1s delays)"""
	if queued_patterns.is_empty():
		push_warning("[EnemySweepManager] No attack patterns selected")
		return

	attack_count += 1

	# Spawn first pattern immediately
	_spawn_single_pattern(queued_patterns[0])

	# Queue remaining patterns with 1-second stagger
	spawn_queue = [queued_patterns[1], queued_patterns[2]]
	time_until_next_spawn = SPAWN_STAGGER_TIME

	# Set next attack timer
	time_until_next_attack = attack_interval

	print("[EnemySweepManager] Attack #%d spawned: %s (2 more queued)" % [attack_count, queued_patterns[0].pattern_id])


func _spawn_single_pattern(pattern: Dictionary) -> void:
	"""Spawn a single sweep pattern based on its type"""
	match pattern.pattern_type:
		"horizontal":
			_spawn_horizontal_sweep(pattern)
		"vertical":
			_spawn_vertical_sweep(pattern)
		"targeted":
			_spawn_targeted_sweep(pattern)
		"diagonal":
			_spawn_diagonal_sweep(pattern)
		"pincer":
			_spawn_pincer_sweep(pattern)
		"wave":
			_spawn_wave_sweep(pattern)
		_:
			push_warning("[EnemySweepManager] Pattern type '%s' not yet implemented" % pattern.pattern_type)

	print("[EnemySweepManager] Spawned: %s" % pattern.pattern_id)


func _spawn_horizontal_sweep(pattern: Dictionary) -> void:
	"""Spawn a horizontal sweep pattern"""
	# Get current scroll speed to account for map movement
	var scroll_speed = scrolling_system.get_scroll_speed()
	var effective_speed = pattern.base_speed + scroll_speed

	# Position based on pattern_id
	if pattern.pattern_id == "sweep_h_left":
		# Spawn on left side, sweep down
		var alien = _create_alien_projectile(pattern)
		alien.position = Vector2(0, -pattern.width_px / 2)
		alien.set_meta("velocity", Vector2(0, effective_speed))
		world_container.add_child(alien)
		active_aliens.append(alien)
	elif pattern.pattern_id == "sweep_h_right":
		# Spawn on right side, sweep down
		var alien = _create_alien_projectile(pattern)
		alien.position = Vector2(SCREEN_WIDTH - pattern.width_px, -pattern.width_px / 2)
		alien.set_meta("velocity", Vector2(0, effective_speed))
		world_container.add_child(alien)
		active_aliens.append(alien)
	elif pattern.pattern_id == "sweep_v_double":
		# Spawn two vertical sweeps simultaneously with gap between them
		var half_gap = pattern.gap_px / 2.0
		var left_x = (SCREEN_WIDTH / 2.0) - half_gap - pattern.width_px
		var right_x = (SCREEN_WIDTH / 2.0) + half_gap

		# Spawn left sweep
		var alien_left = _create_alien_projectile(pattern)
		alien_left.position = Vector2(left_x, -pattern.width_px / 2)
		alien_left.set_meta("velocity", Vector2(0, effective_speed))
		world_container.add_child(alien_left)
		active_aliens.append(alien_left)

		# Spawn right sweep
		var alien_right = _create_alien_projectile(pattern)
		alien_right.position = Vector2(right_x, -pattern.width_px / 2)
		alien_right.set_meta("velocity", Vector2(0, effective_speed))
		world_container.add_child(alien_right)
		active_aliens.append(alien_right)

		print("[EnemySweepManager] Double vertical spawned: left at %.1f, right at %.1f (gap: %.1f)" % [left_x, right_x, pattern.gap_px])


func _spawn_vertical_sweep(pattern: Dictionary) -> void:
	"""Spawn a vertical sweep pattern"""
	var alien = _create_alien_projectile(pattern)

	# Get current scroll speed to account for map movement
	var scroll_speed = scrolling_system.get_scroll_speed()
	var effective_speed = pattern.base_speed + scroll_speed

	# Position based on pattern_id
	if pattern.pattern_id == "sweep_v_left":
		# Spawn on left side at top, sweep straight down
		alien.position = Vector2(pattern.width_px / 2, -pattern.width_px / 2)
		alien.set_meta("velocity", Vector2(0, effective_speed))
	elif pattern.pattern_id == "sweep_v_right":
		# Spawn on right side at top, sweep straight down
		alien.position = Vector2(SCREEN_WIDTH - pattern.width_px / 2, -pattern.width_px / 2)
		alien.set_meta("velocity", Vector2(0, effective_speed))
	elif pattern.pattern_id == "sweep_v_center":
		# Spawn at player's exact X position at top, sweep straight down
		var player_x = player_ship.position.x if player_ship else SCREEN_WIDTH / 2
		alien.position = Vector2(player_x, -pattern.width_px / 2)
		alien.set_meta("velocity", Vector2(0, effective_speed))

	world_container.add_child(alien)
	active_aliens.append(alien)


func _spawn_targeted_sweep(pattern: Dictionary) -> void:
	"""Spawn a targeted sweep pattern (aims at player on spawn)"""
	var alien = _create_alien_projectile(pattern)

	# Get current scroll speed to account for map movement
	var scroll_speed = scrolling_system.get_scroll_speed()
	var effective_speed = pattern.base_speed + scroll_speed

	# Position based on pattern_id
	if pattern.pattern_id == "sweep_v_aim_center":
		# Spawn centered on player's X position at top, sweep straight down
		var player_x = player_ship.position.x if player_ship else SCREEN_WIDTH / 2
		alien.position = Vector2(player_x, -pattern.width_px / 2)
		alien.set_meta("velocity", Vector2(0, effective_speed))

	world_container.add_child(alien)
	active_aliens.append(alien)


func _spawn_diagonal_sweep(pattern: Dictionary) -> void:
	"""Spawn a diagonal sweep pattern"""
	var alien = _create_alien_projectile(pattern)

	# Get current scroll speed to account for map movement
	var scroll_speed = scrolling_system.get_scroll_speed()
	var effective_speed_y = pattern.base_speed + scroll_speed

	# For diagonal movement, split speed between X and Y axes
	# Using 0.707 (1/sqrt(2)) to maintain consistent speed along diagonal
	var diagonal_speed = pattern.base_speed * 0.707

	# Position based on pattern_id
	if pattern.pattern_id == "sweep_d_topleft":
		# Spawn at top-left corner, move diagonally to bottom-right
		alien.position = Vector2(-pattern.width_px / 2, -pattern.width_px / 2)
		alien.set_meta("velocity", Vector2(diagonal_speed, effective_speed_y))
	elif pattern.pattern_id == "sweep_d_topright":
		# Spawn at top-right corner, move diagonally to bottom-left
		alien.position = Vector2(SCREEN_WIDTH + pattern.width_px / 2, -pattern.width_px / 2)
		alien.set_meta("velocity", Vector2(-diagonal_speed, effective_speed_y))

	world_container.add_child(alien)
	active_aliens.append(alien)


func _spawn_pincer_sweep(pattern: Dictionary) -> void:
	"""Spawn a pincer sweep pattern (two sweeps from left and right simultaneously)"""
	# Get current scroll speed to account for map movement
	var scroll_speed = scrolling_system.get_scroll_speed()
	var effective_speed = pattern.base_speed + scroll_speed

	# Calculate positions based on gap
	# gap_px defines the center safe zone
	var half_gap = pattern.gap_px / 2.0
	var left_x = (SCREEN_WIDTH / 2.0) - half_gap - pattern.width_px
	var right_x = (SCREEN_WIDTH / 2.0) + half_gap

	# Spawn left sweep
	var alien_left = _create_alien_projectile(pattern)
	alien_left.position = Vector2(left_x, -pattern.width_px / 2)
	alien_left.set_meta("velocity", Vector2(0, effective_speed))
	world_container.add_child(alien_left)
	active_aliens.append(alien_left)

	# Spawn right sweep
	var alien_right = _create_alien_projectile(pattern)
	alien_right.position = Vector2(right_x, -pattern.width_px / 2)
	alien_right.set_meta("velocity", Vector2(0, effective_speed))
	world_container.add_child(alien_right)
	active_aliens.append(alien_right)

	print("[EnemySweepManager] Pincer spawned: left at %.1f, right at %.1f (gap: %.1f)" % [left_x, right_x, pattern.gap_px])


func _spawn_wave_sweep(pattern: Dictionary) -> void:
	"""Spawn a wave sweep pattern (multiple small groups with gaps)"""
	# Get current scroll speed to account for map movement
	var scroll_speed = scrolling_system.get_scroll_speed()
	var effective_speed = pattern.base_speed + scroll_speed

	# Determine number of groups based on pattern_id
	var num_groups = 3
	if pattern.pattern_id == "sweep_wave_5":
		num_groups = 5
	elif pattern.pattern_id == "sweep_wave_chaos":
		num_groups = 7

	# Calculate spacing
	# gap_px is the spacing between groups
	var total_width = (num_groups * pattern.width_px) + ((num_groups - 1) * pattern.gap_px)
	var start_x = (SCREEN_WIDTH - total_width) / 2.0

	# Spawn each group
	for i in range(num_groups):
		var x_pos = start_x + (i * (pattern.width_px + pattern.gap_px))
		var alien = _create_alien_projectile(pattern)
		alien.position = Vector2(x_pos, -pattern.width_px / 2)
		alien.set_meta("velocity", Vector2(0, effective_speed))
		world_container.add_child(alien)
		active_aliens.append(alien)

	print("[EnemySweepManager] Wave spawned: %d groups, gap: %.1f" % [num_groups, pattern.gap_px])


func _create_alien_projectile(pattern: Dictionary) -> Node2D:
	"""Create an alien projectile node"""
	var alien = Node2D.new()
	alien.name = "AlienSweep_%s_%d" % [pattern.pattern_id, attack_count]

	# Visual representation (colored rectangle as placeholder)
	var visual = ColorRect.new()
	visual.color = Color(0.8, 0.2, 0.2, 1.0)  # Dark red
	visual.size = Vector2(pattern.width_px, pattern.width_px)
	visual.position = Vector2.ZERO
	alien.add_child(visual)

	# Store pattern data and velocity
	alien.set_meta("pattern", pattern)
	alien.set_meta("velocity", Vector2.ZERO)  # Will be set in spawn function

	# Collision area
	var area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(pattern.width_px, pattern.width_px)
	collision.shape = shape
	collision.position = Vector2(pattern.width_px / 2, pattern.width_px / 2)
	area.add_child(collision)
	alien.add_child(area)

	# Connect collision signal
	area.body_entered.connect(_on_alien_hit_player.bind(alien))
	area.area_entered.connect(_on_alien_hit_player_area.bind(alien))

	return alien


func _update_aliens(delta: float) -> void:
	"""Update all active alien projectiles"""
	var aliens_to_remove: Array[Node2D] = []

	for alien in active_aliens:
		if not is_instance_valid(alien):
			aliens_to_remove.append(alien)
			continue

		# Move alien
		var velocity: Vector2 = alien.get_meta("velocity")
		alien.position += velocity * delta

		# Check if offscreen and mark for removal
		if _is_alien_offscreen(alien):
			aliens_to_remove.append(alien)

	# Remove offscreen aliens
	for alien in aliens_to_remove:
		active_aliens.erase(alien)
		if is_instance_valid(alien):
			alien.queue_free()


func _is_alien_offscreen(alien: Node2D) -> bool:
	"""Check if alien is sufficiently offscreen to despawn"""
	var pattern: Dictionary = alien.get_meta("pattern")
	var margin = pattern.width_px + 100  # Extra margin

	return (alien.position.y > SCREEN_HEIGHT + margin or
			alien.position.y < -margin or
			alien.position.x > SCREEN_WIDTH + margin or
			alien.position.x < -margin)


func _on_alien_hit_player(body: Node, alien: Node2D) -> void:
	"""Handle alien collision with player"""
	if body == player_ship:
		_handle_player_hit(alien)


func _on_alien_hit_player_area(area: Area2D, alien: Node2D) -> void:
	"""Handle alien collision with player area"""
	if area.get_parent() == player_ship:
		_handle_player_hit(alien)


func _handle_player_hit(alien: Node2D) -> void:
	"""Process player getting hit by alien sweep"""
	# Record enemy trigger in GameState
	GameState.record_enemy_trigger()

	# Emit EventBus signals
	EventBus.emit_signal("enemy_sweep_hit_player")
	EventBus.emit_signal("screen_shake_requested", 0.3, 20.0)  # 0.3s duration, 20px intensity

	# Remove the alien that hit
	active_aliens.erase(alien)
	if is_instance_valid(alien):
		alien.queue_free()

	print("[EnemySweepManager] Player hit by alien sweep!")


func pause() -> void:
	"""Pause sweep manager"""
	is_paused = true


func resume() -> void:
	"""Resume sweep manager"""
	is_paused = false


func clear_all_aliens() -> void:
	"""Remove all active alien projectiles"""
	for alien in active_aliens:
		if is_instance_valid(alien):
			alien.queue_free()
	active_aliens.clear()
