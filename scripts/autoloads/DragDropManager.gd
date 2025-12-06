extends Node

# ============================================================
# DRAG DROP MANAGER - UNIFIED DRAG & DROP SYSTEM
# ============================================================
# Purpose: Centralized drag/drop state and preview management
# Works across hangar, foundry, combat prep, and shops
# ============================================================

# ============================================================
# SIGNALS
# ============================================================

signal drag_started(item_id: String, item_data: Dictionary)
signal drag_ended(item_id: String, was_dropped: bool)
signal drop_attempted(item_id: String, drop_target: Node)

# ============================================================
# DRAG STATE
# ============================================================

var is_dragging: bool = false
var dragged_item_id: String = ""
var dragged_item_data: Dictionary = {}
var drag_preview: Control = null
var drag_start_position: Vector2 = Vector2.ZERO

# Drop zones (nodes that can receive drops)
var registered_drop_zones: Array[Dictionary] = []

# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
	print("[DragDropManager] Initialized")

func _process(_delta: float) -> void:
	"""Update drag preview position"""
	if drag_preview != null and is_dragging:
		var viewport := get_viewport()
		if viewport:
			var mouse_pos := viewport.get_mouse_position()
			drag_preview.global_position = mouse_pos - drag_preview.size / 2

# ============================================================
# DRAG OPERATIONS
# ============================================================

func start_drag(item_id: String, item_data: Dictionary, preview_texture: Texture2D, preview_size: Vector2 = Vector2(130, 180)) -> void:
	"""Start dragging an item with a visual preview

	Args:
		item_id: Item identifier
		item_data: Item data dictionary
		preview_texture: Texture to show in drag preview
		preview_size: Size of drag preview
	"""
	if is_dragging:
		push_warning("[DragDropManager] Already dragging %s, canceling previous drag" % dragged_item_id)
		end_drag(false)

	dragged_item_id = item_id
	dragged_item_data = item_data
	is_dragging = true

	var viewport := get_viewport()
	if viewport:
		drag_start_position = viewport.get_mouse_position()

	# Create visual preview
	_create_drag_preview(preview_texture, preview_size)

	print("[DragDropManager] Started dragging: %s" % item_id)
	drag_started.emit(item_id, item_data)

func end_drag(was_dropped: bool) -> void:
	"""End the current drag operation

	Args:
		was_dropped: Whether the item was successfully dropped
	"""
	if not is_dragging:
		return

	var item_id := dragged_item_id

	# Clean up preview
	if drag_preview != null:
		drag_preview.queue_free()
		drag_preview = null

	# Clear state
	is_dragging = false
	dragged_item_id = ""
	dragged_item_data = {}
	drag_start_position = Vector2.ZERO

	print("[DragDropManager] Ended drag: %s (dropped: %s)" % [item_id, was_dropped])
	drag_ended.emit(item_id, was_dropped)

func cancel_drag() -> void:
	"""Cancel the current drag (same as end_drag(false))"""
	end_drag(false)

# ============================================================
# DRAG PREVIEW
# ============================================================

func _create_drag_preview(texture: Texture2D, preview_size: Vector2) -> void:
	"""Create a visual preview that follows the mouse"""
	# Remove old preview if exists
	if drag_preview != null:
		drag_preview.queue_free()

	# Create semi-transparent preview
	drag_preview = PanelContainer.new()
	drag_preview.custom_minimum_size = preview_size
	drag_preview.modulate = Color(1, 1, 1, 0.7)  # Semi-transparent
	drag_preview.z_index = 1000  # Always on top
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Add texture to preview
	if texture != null:
		var texture_rect := TextureRect.new()
		texture_rect.texture = texture
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.custom_minimum_size = Vector2(100, 100)
		texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		drag_preview.add_child(texture_rect)

	# Add to viewport root
	var root := get_tree().root
	if root:
		root.add_child(drag_preview)

		var viewport := get_viewport()
		if viewport:
			var mouse_pos := viewport.get_mouse_position()
			drag_preview.global_position = mouse_pos - drag_preview.size / 2

# ============================================================
# DROP ZONE MANAGEMENT
# ============================================================

func register_drop_zone(zone_node: Node, zone_id: String = "", custom_data: Dictionary = {}) -> void:
	"""Register a node as a drop zone

	Args:
		zone_node: Node that can receive drops
		zone_id: Optional identifier for this zone
		custom_data: Optional custom data for callbacks
	"""
	var zone_entry := {
		"node": zone_node,
		"zone_id": zone_id if not zone_id.is_empty() else zone_node.name,
		"custom_data": custom_data
	}

	registered_drop_zones.append(zone_entry)
	print("[DragDropManager] Registered drop zone: %s" % zone_entry["zone_id"])

func unregister_drop_zone(zone_node: Node) -> void:
	"""Unregister a drop zone

	Args:
		zone_node: Node to unregister
	"""
	for i in range(registered_drop_zones.size() - 1, -1, -1):
		if registered_drop_zones[i]["node"] == zone_node:
			print("[DragDropManager] Unregistered drop zone: %s" % registered_drop_zones[i]["zone_id"])
			registered_drop_zones.remove_at(i)

func clear_drop_zones() -> void:
	"""Clear all registered drop zones"""
	registered_drop_zones.clear()
	print("[DragDropManager] Cleared all drop zones")

# ============================================================
# DROP DETECTION
# ============================================================

func try_drop_at_position(position: Vector2) -> Dictionary:
	"""Check if position is over a registered drop zone

	Args:
		position: Global position to check

	Returns:
		Dictionary with drop zone info if found, empty dict otherwise
		Format: {"node": Node, "zone_id": String, "custom_data": Dictionary}
	"""
	if not is_dragging:
		return {}

	# Check registered drop zones
	for zone_entry in registered_drop_zones:
		var zone_node: Node = zone_entry["node"]
		if not is_instance_valid(zone_node) or not zone_node is Control:
			continue

		var control := zone_node as Control
		var rect := Rect2(control.global_position, control.size)

		if rect.has_point(position):
			print("[DragDropManager] Drop at zone: %s" % zone_entry["zone_id"])
			drop_attempted.emit(dragged_item_id, zone_node)
			return zone_entry

	return {}

func get_drop_zone_at_position(position: Vector2) -> Node:
	"""Get the drop zone node at a position

	Args:
		position: Global position to check

	Returns:
		Node if found, null otherwise
	"""
	var zone_info := try_drop_at_position(position)
	if not zone_info.is_empty():
		return zone_info.get("node")
	return null

# ============================================================
# STATE QUERIES
# ============================================================

func get_dragged_item_id() -> String:
	"""Get the ID of currently dragged item"""
	return dragged_item_id

func get_dragged_item_data() -> Dictionary:
	"""Get the data of currently dragged item"""
	return dragged_item_data

func is_item_being_dragged() -> bool:
	"""Check if an item is currently being dragged"""
	return is_dragging

func get_drag_start_position() -> Vector2:
	"""Get the position where drag started"""
	return drag_start_position
