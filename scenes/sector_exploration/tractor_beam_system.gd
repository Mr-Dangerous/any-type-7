extends Node

## Tractor Beam System Module
## Handles debris attraction, tractor beam locking, and collection

# System references
var player_ship: Node2D = null
var node_spawner: Node = null

# Active tractor beams tracking
var active_beams: Array[Dictionary] = []

# Tractor beam state enum
enum TractorState {
	NONE,           # Not attracted
	ATTRACTING,     # Moving toward player slowly
	LOCKED          # Locked by tractor beam, being pulled
}


func initialize(ship: Node2D, spawner: Node) -> void:
	"""Initialize with references"""
	player_ship = ship
	node_spawner = spawner
	print("[TractorBeamSystem] Initialized")


func process_tractor_beams(delta: float) -> void:
	"""Update tractor beam attractions and pulls each frame"""
	if not player_ship or not node_spawner:
		return

	var player_pos = player_ship.position
	var active_nodes = node_spawner.get_active_nodes()

	var debris_count = 0
	var attracting_count = 0
	var closest_distance = 9999.0
	var closest_debris_id = ""

	# Update existing beams
	_update_active_beams(delta, player_pos)

	# Check for new attractions/locks
	for node_data in active_nodes:
		var node = node_data.node_ref as Area2D
		if not node or not is_instance_valid(node):
			continue

		# Count debris nodes
		if node.has_meta("is_debris") and node.get_meta("is_debris"):
			debris_count += 1
			var dist_check = player_pos.distance_to(node.position)
			if dist_check < closest_distance:
				closest_distance = dist_check
				closest_debris_id = node_data.node_id

		# Skip if not a debris field node
		if not node.has_meta("is_debris") or not node.get_meta("is_debris"):
			continue

		# Skip if already activated (collected)
		if node.is_activated:
			continue

		var distance = player_pos.distance_to(node.position)

		# Check if already locked by beam
		var is_locked = node.has_meta("tractor_locked") and node.get_meta("tractor_locked")

		if is_locked:
			# Already locked, skip (beam pull handles it)
			continue

		# Check distance for attraction or locking
		if distance <= DebugManager.get_beam_range():
			# Try to lock beam
			if active_beams.size() < DebugManager.get_beam_count():
				_lock_tractor_beam(node, node_data.node_id)
		elif distance <= DebugManager.get_attraction_range():
			# Apply attraction (passive movement)
			if not node.has_meta("tractor_attracting") or not node.get_meta("tractor_attracting"):
				node.set_meta("tractor_attracting", true)
				node.modulate = Color(1.0, 1.0, 0.5)  # Yellow tint for attracting
			_apply_attraction(node, player_pos, delta)
			attracting_count += 1
		else:
			# Clear attraction flag if out of range
			if node.has_meta("tractor_attracting") and node.get_meta("tractor_attracting"):
				node.set_meta("tractor_attracting", false)
				node.modulate = Color(1.0, 1.0, 1.0)  # Reset color

	# Debug output every 3 seconds when activity occurs
	if Engine.get_process_frames() % 180 == 0 and (attracting_count > 0 or active_beams.size() > 0):
		print("[TractorBeam] Attracting: %d, Locked: %d | Closest: %.0fpx" %
			[attracting_count, active_beams.size(), closest_distance])


func _update_active_beams(delta: float, player_pos: Vector2) -> void:
	"""Update all active tractor beams"""
	var beams_to_remove = []

	for i in range(active_beams.size()):
		var beam = active_beams[i]
		var node = beam.node_ref as Area2D

		# Validate node
		if not node or not is_instance_valid(node):
			beams_to_remove.append(i)
			continue

		# Update beam pull timer
		beam.pull_timer += delta
		var progress = beam.pull_timer / DebugManager.get_beam_duration()

		if progress >= 1.0:
			# Beam complete - collect node
			_collect_debris(node, beam.node_id)
			beams_to_remove.append(i)
		else:
			# Pull node toward player
			var pull_speed = player_pos.distance_to(node.position) / (DebugManager.get_beam_duration() - beam.pull_timer)
			var direction = (player_pos - node.position).normalized()
			node.position += direction * pull_speed * delta

	# Remove completed beams (reverse order to maintain indices)
	for i in range(beams_to_remove.size() - 1, -1, -1):
		active_beams.remove_at(beams_to_remove[i])


func _apply_attraction(node: Area2D, player_pos: Vector2, delta: float) -> void:
	"""Apply passive attraction to debris node"""
	var direction = (player_pos - node.position).normalized()
	var speed = DebugManager.get_attraction_speed()
	node.position += direction * speed * delta


func _lock_tractor_beam(node: Area2D, node_id: String) -> void:
	"""Lock a tractor beam onto a debris node"""
	# Mark node as locked
	node.set_meta("tractor_locked", true)

	# Add to active beams
	active_beams.append({
		"node_ref": node,
		"node_id": node_id,
		"pull_timer": 0.0
	})

	print("[TractorBeamSystem] Locked beam on %s (%d/%d active)" %
		[node_id, active_beams.size(), DebugManager.get_beam_count()])

	# Visual feedback (can add beam line here later)
	node.modulate = Color(0.5, 1.0, 1.0)  # Cyan tint for locked


func _collect_debris(node: Area2D, node_id: String) -> void:
	"""Collect a debris node via tractor beam"""
	if not node or not is_instance_valid(node):
		return

	# Emit collection signal (sector_map will handle resource collection)
	EventBus.node_activated.emit(node_id)

	# Mark as activated
	node.is_activated = true

	# Despawn
	node.queue_free()
	node_spawner.remove_node(node_id)

	print("[TractorBeamSystem] Collected debris: %s" % node_id)


func _get_beam_state(node: Area2D) -> TractorState:
	"""Get current tractor beam state for a node"""
	if node.has_meta("tractor_locked") and node.get_meta("tractor_locked"):
		return TractorState.LOCKED

	# Check if in attraction range
	var distance = player_ship.position.distance_to(node.position)
	if distance <= DebugManager.get_attraction_range():
		return TractorState.ATTRACTING

	return TractorState.NONE


func get_active_beam_count() -> int:
	"""Get number of active tractor beams"""
	return active_beams.size()


func get_max_beam_count() -> int:
	"""Get max tractor beams from DebugManager"""
	return DebugManager.get_beam_count()
