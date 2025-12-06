extends Node

# ============================================================
# COLLECTION MANAGER - RESOURCE COLLECTION SYSTEM
# ============================================================
# Purpose: Handle resource collection from nodes with multipliers
# Integrates with GameState (streaks), ResourceManager (awards),
# AnimationManager (visuals), and UIManager (display)
# ============================================================

# ============================================================
# RESOURCE TRACKING
# ============================================================

# Counter tracking for number animations (old value to new value)
var resource_counters: Dictionary = {
	"metal": 0,
	"crystals": 0,
	"fuel": 0
}

# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
	# Initialize counters from ResourceManager
	resource_counters["metal"] = ResourceManager.get_metal()
	resource_counters["crystals"] = ResourceManager.get_crystals()
	resource_counters["fuel"] = ResourceManager.get_fuel()

	# Connect to resource change signals to keep counters in sync
	EventBus.resource_changed.connect(_on_resource_changed)

	print("[CollectionManager] Initialized - Resource collection system ready")


# ============================================================
# RESOURCE COLLECTION
# ============================================================

func collect_from_node(node: Area2D, ui_overlay: Node) -> void:
	"""Collect resources from a node with full animation and multiplier system"""
	# Handle trader nodes separately
	if node.is_trader:
		_handle_trader_purchase(node)
		return

	var resource_type = node.resource_type
	var base_resources = node.base_resources
	var rarity = node.rarity

	# Skip if no resources
	if resource_type == "none" or base_resources == 0:
		return

	# Get streak multiplier from GameState
	var streak_multiplier = GameState.collect_resource_node(resource_type)

	# Calculate final resources
	var final_amount = int(base_resources * streak_multiplier)

	# Award resources
	if resource_type != "item":
		ResourceManager.add_resource(resource_type, final_amount, "node_collection")

		# Trigger collection animation (flying icon + number count + pulse)
		animate_collection(resource_type, final_amount, node.global_position, ui_overlay)

		# Console feedback
		print("[CollectionManager] Collected %d %s from %s %s (base: %d, streak: %.1fx)" %
			[final_amount, resource_type.capitalize(), rarity.capitalize(), node.node_type, base_resources, streak_multiplier])
	else:
		# Upgrade node - collect specific Tier 1 upgrade
		if node.is_upgrade and node.upgrade_item_id != "":
			GameState.collect_tier_1_upgrade(node.upgrade_item_id)
			print("[CollectionManager] Collected Tier 1 upgrade: %s from %s %s" %
				[node.upgrade_item_id, rarity.capitalize(), node.node_type])
		else:
			print("[CollectionManager] Warning: Item node has no upgrade_item_id")


# ============================================================
# TRADER SYSTEM
# ============================================================

func _handle_trader_purchase(node: Area2D) -> void:
	"""Handle purchasing from a trader node"""
	var cost_type = node.trade_cost_type
	var cost_amount = node.trade_cost_amount
	var reward_id = node.trade_reward_id

	# Check if player can afford it
	if not ResourceManager.can_afford_individual(cost_type, cost_amount):
		print("[CollectionManager] Cannot afford trader! Need %d %s (Have: %d)" %
			[cost_amount, cost_type.capitalize(), ResourceManager.get_resource(cost_type)])
		return

	# Spend resources
	if ResourceManager.spend_resource(cost_type, cost_amount, "trader_purchase"):
		# Give Tier 1 upgrade reward
		GameState.collect_tier_1_upgrade(reward_id)
		print("[CollectionManager] Trade completed! Spent %d %s, received %s" %
			[cost_amount, cost_type.capitalize(), reward_id])


# ============================================================
# ANIMATION INTEGRATION
# ============================================================

func animate_collection(resource_type: String, amount: int, from_position: Vector2,
		ui_overlay: Node) -> void:
	"""Animate resource collection with flying icon, number count, and pulse"""
	if resource_type == "item":
		return  # Items don't have UI animations yet

	# Get target UI panel from UIManager
	var target_panel = UIManager.get_resource_panel(resource_type)
	if not target_panel:
		print("[CollectionManager] Warning: No panel registered for %s" % resource_type)
		return

	# Calculate target position (center of panel)
	var target_pos = target_panel.global_position + target_panel.size / 2

	# Create flying icon with callbacks
	AnimationManager.create_flying_icon(
		ui_overlay,
		resource_type,
		from_position,
		target_pos,
		0.5,
		func():
			_on_icon_arrived(resource_type, amount, target_panel)
	)


func _on_icon_arrived(resource_type: String, amount: int, panel: Control) -> void:
	"""Called when flying icon reaches the UI panel"""
	# Animate number counting up
	var label = UIManager.get_resource_label(resource_type)
	if label:
		var old_value = resource_counters[resource_type]
		var new_value = ResourceManager.get_resource(resource_type)
		resource_counters[resource_type] = new_value
		AnimationManager.animate_number_count(self, label, old_value, new_value, 0.3)

	# Pulse the panel
	AnimationManager.pulse_scale(self, panel, Vector2(1.15, 1.15), 0.1, 0.2)


# ============================================================
# DIRECT COLLECTION (NO ANIMATION)
# ============================================================

func collect_direct(resource_type: String, amount: int, source: String = "direct") -> void:
	"""Collect resources directly without animations (for combat, events, etc.)"""
	ResourceManager.add_resource(resource_type, amount, source)
	print("[CollectionManager] Direct collection: %d %s from %s" % [amount, resource_type.capitalize(), source])


# ============================================================
# FLOATING TEXT FEEDBACK
# ============================================================

func show_collection_text(resource_type: String, amount: int, position: Vector2,
		ui_overlay: Node) -> void:
	"""Show floating text for resource collection"""
	var color = Color.WHITE
	match resource_type:
		"metal":
			color = Color(0.7, 0.7, 0.7)  # Gray
		"crystals":
			color = Color(0.3, 0.6, 1.0)  # Blue
		"fuel":
			color = Color(1.0, 0.6, 0.2)  # Orange

	var text = "+%d %s" % [amount, resource_type.capitalize()]
	AnimationManager.create_floating_text(ui_overlay, text, position, color, 36, 1.0, 80.0)


# ============================================================
# EVENT HANDLERS
# ============================================================

func _on_resource_changed(resource_type: String, old_amount: int, new_amount: int) -> void:
	"""Keep internal counters in sync with ResourceManager"""
	if resource_counters.has(resource_type):
		resource_counters[resource_type] = new_amount


# ============================================================
# UTILITY FUNCTIONS
# ============================================================

func reset_counters() -> void:
	"""Reset resource counters (for new game or module transitions)"""
	resource_counters["metal"] = ResourceManager.get_metal()
	resource_counters["crystals"] = ResourceManager.get_crystals()
	resource_counters["fuel"] = ResourceManager.get_fuel()
	print("[CollectionManager] Resource counters reset")


func get_counter(resource_type: String) -> int:
	"""Get current counter value for a resource"""
	return resource_counters.get(resource_type, 0)
