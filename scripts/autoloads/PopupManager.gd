extends Node

# ============================================================
# POPUP MANAGER - CENTRALIZED POPUP SYSTEM
# ============================================================
# Purpose: Manage popups across all game modules
# Provides reusable popup system with:
# - Click-outside-to-close functionality
# - X button close support
# - Modal overlay (dimmed background)
# - Scene-based popup content
# ============================================================

# ============================================================
# SIGNALS
# ============================================================

signal popup_opened(popup_id: String)
signal popup_closed(popup_id: String)

# ============================================================
# POPUP STATE
# ============================================================

var current_popup: Control = null
var current_popup_id: String = ""
var popup_overlay: ColorRect = null
var popup_container: Control = null

# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
	# Create popup overlay (modal background)
	popup_overlay = ColorRect.new()
	popup_overlay.color = Color(0, 0, 0, 0.7)  # Semi-transparent black
	popup_overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # Catch clicks
	popup_overlay.visible = false
	popup_overlay.z_index = 100  # Above most UI
	popup_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_overlay.gui_input.connect(_on_overlay_clicked)

	# Create popup container (centered)
	popup_container = Control.new()
	popup_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_container.visible = false
	popup_container.z_index = 101  # Above overlay
	popup_container.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Add to scene tree (will be added to the root when needed)
	print("[PopupManager] Initialized")

# ============================================================
# PUBLIC API
# ============================================================

func show_popup(popup_scene: PackedScene, popup_id: String = "") -> Control:
	"""
	Show a popup from a scene.
	Returns the instantiated popup control for further customization.
	"""
	if current_popup != null:
		close_popup()

	# Instance the popup scene
	var popup_instance := popup_scene.instantiate()

	if popup_instance == null or not popup_instance is Control:
		push_error("[PopupManager] Popup scene must be a Control node!")
		return null

	# Get the root node
	var root := get_tree().root

	# Add overlay and container to root
	if not popup_overlay.is_inside_tree():
		root.add_child(popup_overlay)
	if not popup_container.is_inside_tree():
		root.add_child(popup_container)

	# Add popup to container
	popup_container.add_child(popup_instance)

	# Center the popup
	if popup_instance.has_method("set_anchors_preset"):
		popup_instance.set_anchors_preset(Control.PRESET_CENTER)
		popup_instance.position = Vector2.ZERO  # Reset position after preset

	# Store references
	current_popup = popup_instance
	current_popup_id = popup_id if not popup_id.is_empty() else "popup_%d" % Time.get_ticks_msec()

	# Show overlay and container
	popup_overlay.visible = true
	popup_container.visible = true

	# Connect close button if it exists
	_connect_close_button(popup_instance)

	# Emit signal
	popup_opened.emit(current_popup_id)

	print("[PopupManager] Opened popup: %s" % current_popup_id)

	return popup_instance

func show_popup_from_node(popup_node: Control, popup_id: String = "") -> Control:
	"""
	Show a popup from an existing node (does not need to be a scene).
	Returns the popup control.
	"""
	if current_popup != null:
		close_popup()

	if popup_node == null or not popup_node is Control:
		push_error("[PopupManager] Popup must be a Control node!")
		return null

	# Get the root node
	var root := get_tree().root

	# Add overlay and container to root
	if not popup_overlay.is_inside_tree():
		root.add_child(popup_overlay)
	if not popup_container.is_inside_tree():
		root.add_child(popup_container)

	# Add popup to container
	popup_container.add_child(popup_node)

	# Center the popup
	if popup_node.has_method("set_anchors_preset"):
		popup_node.set_anchors_preset(Control.PRESET_CENTER)
		popup_node.position = Vector2.ZERO  # Reset position after preset

	# Store references
	current_popup = popup_node
	current_popup_id = popup_id if not popup_id.is_empty() else "popup_%d" % Time.get_ticks_msec()

	# Show overlay and container
	popup_overlay.visible = true
	popup_container.visible = true

	# Connect close button if it exists
	_connect_close_button(popup_node)

	# Emit signal
	popup_opened.emit(current_popup_id)

	print("[PopupManager] Opened popup: %s" % current_popup_id)

	return popup_node

func close_popup() -> void:
	"""Close the current popup"""
	if current_popup == null:
		return

	var closed_id := current_popup_id

	# Remove popup from container
	if current_popup.is_inside_tree():
		popup_container.remove_child(current_popup)
		current_popup.queue_free()

	# Hide overlay and container
	popup_overlay.visible = false
	popup_container.visible = false

	# Clear references
	current_popup = null
	current_popup_id = ""

	# Emit signal
	popup_closed.emit(closed_id)

	print("[PopupManager] Closed popup: %s" % closed_id)

func is_popup_open() -> bool:
	"""Check if a popup is currently open"""
	return current_popup != null

func get_current_popup() -> Control:
	"""Get the current popup node"""
	return current_popup

func get_current_popup_id() -> String:
	"""Get the current popup ID"""
	return current_popup_id

# ============================================================
# INTERNAL METHODS
# ============================================================

func _connect_close_button(popup_node: Control) -> void:
	"""Look for a close button in the popup and connect it"""
	# Look for common close button names
	var close_button_names := ["CloseButton", "XButton", "Close", "X"]

	for button_name in close_button_names:
		var close_button := popup_node.find_child(button_name, true, false)
		if close_button != null and close_button is BaseButton:
			close_button.pressed.connect(close_popup)
			print("[PopupManager] Connected close button: %s" % button_name)
			return

func _on_overlay_clicked(event: InputEvent) -> void:
	"""Handle clicks on the overlay (outside popup)"""
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			print("[PopupManager] Overlay clicked - closing popup")
			close_popup()
	elif event is InputEventScreenTouch and event.pressed:
		print("[PopupManager] Overlay touched - closing popup")
		close_popup()
