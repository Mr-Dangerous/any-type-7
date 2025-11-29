extends Control

# Node popup UI that appears when player enters node proximity
# Pauses game time and displays node information

@onready var title_label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var info_label = $Panel/MarginContainer/VBoxContainer/InfoLabel
@onready var gravity_label = $Panel/MarginContainer/VBoxContainer/GravityLabel
@onready var button_container = $Panel/MarginContainer/VBoxContainer/ButtonContainer
@onready var faster_button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/FasterButton
@onready var same_button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/SameButton
@onready var slower_button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/SlowerButton
@onready var continue_button = $Panel/MarginContainer/VBoxContainer/ContinueButton

var current_node_id: String = ""
var current_node_type: String = ""
var current_node_position: Vector2 = Vector2.ZERO
var current_has_gravity: bool = false
var current_gravity_multiplier: float = 0.0


func _ready() -> void:
	# Hide by default
	visible = false

	# Connect buttons
	faster_button.pressed.connect(_on_faster_pressed)
	same_button.pressed.connect(_on_same_pressed)
	slower_button.pressed.connect(_on_slower_pressed)
	continue_button.pressed.connect(_on_continue_pressed)

	print("[NodePopup] Initialized")


func show_popup(node_id: String, node_type: String, node_position: Vector2, has_gravity: bool = false, gravity_multiplier: float = 0.0) -> void:
	"""Display the popup with node information"""
	current_node_id = node_id
	current_node_type = node_type
	current_node_position = node_position
	current_has_gravity = has_gravity
	current_gravity_multiplier = gravity_multiplier

	# Update labels
	title_label.text = "%s Detected" % node_type.capitalize()
	info_label.text = "ID: %s" % node_id

	# Show/hide gravity assist UI vs Continue button
	if has_gravity:
		gravity_label.visible = true
		gravity_label.text = "Gravity Assist (±%.1fx):" % gravity_multiplier
		button_container.visible = true
		continue_button.visible = false
		# Update button text with actual multiplier
		faster_button.text = "Faster\n(+%.1fx)" % gravity_multiplier
		slower_button.text = "Slower\n(-%.1fx)" % gravity_multiplier
		same_button.text = "Same\n(%.1fx)" % 0.0
	else:
		gravity_label.visible = false
		button_container.visible = false
		continue_button.visible = true

	# Show popup
	visible = true

	# Pause game (freeze time)
	get_tree().paused = true

	print("[NodePopup] %s (%s) - Gravity: %s" % [node_id, node_type, has_gravity])


func _on_faster_pressed() -> void:
	"""Player chooses to speed up (+0.2x speed)"""
	_close_popup("faster")


func _on_same_pressed() -> void:
	"""Player chooses to maintain current speed"""
	_close_popup("same")


func _on_slower_pressed() -> void:
	"""Player chooses to slow down (-0.2x speed)"""
	_close_popup("slower")


func _on_continue_pressed() -> void:
	"""Player chooses to continue without gravity assist"""
	_close_popup("same")


func _close_popup(gravity_choice: String) -> void:
	"""Close popup and apply gravity assist choice"""
	# Emit activation signal with gravity choice
	EventBus.node_activated.emit(current_node_id)

	# Emit gravity assist signal with choice, node position, and multiplier
	EventBus.gravity_assist_applied.emit(gravity_choice, current_node_position, current_gravity_multiplier)

	# Hide popup
	visible = false

	# Resume game LAST (after node is marked as activated)
	get_tree().paused = false

	print("[NodePopup] Closed popup for %s - Gravity choice: %s" % [current_node_id, gravity_choice])
