extends Node

## Scrolling System Module
## Handles infinite scrolling grid, distance tracking, and speed management

# Grid tile references (set by parent)
var grid_tiles: Array = []

# Scrolling state
var scroll_distance: float = 0.0
var base_scroll_speed: float = 200.0
var current_speed_multiplier: float = 1.0
var current_scroll_speed: float = 200.0
var max_speed: float = 5.0
var min_speed: float = 1.0

# Constants
const TILE_HEIGHT: float = 2340.0


func _ready() -> void:
	print("[ScrollingSystem] Initialized")


func initialize(tiles: Array) -> void:
	"""Initialize with grid tile references"""
	grid_tiles = tiles

	# Set initial tile positions for infinite scrolling
	if grid_tiles.size() >= 3:
		grid_tiles[0].position.y = 0.0          # Tile 1: on screen
		grid_tiles[1].position.y = -2340.0      # Tile 2: above screen
		grid_tiles[2].position.y = -4680.0      # Tile 3: further above

	print("[ScrollingSystem] Grid tiles initialized: %d tiles" % grid_tiles.size())


func process_scrolling(delta: float) -> void:
	"""Update scrolling each frame"""
	# Update scroll speed
	current_scroll_speed = base_scroll_speed * current_speed_multiplier

	# Update distance
	scroll_distance += current_scroll_speed * delta

	# Scroll all grid tiles downward
	for tile in grid_tiles:
		tile.position.y += current_scroll_speed * delta

		# Wrap tile to top when it goes off bottom (infinite scrolling)
		if tile.position.y > TILE_HEIGHT:
			tile.position.y -= TILE_HEIGHT * 3


func set_speed_multiplier(multiplier: float) -> void:
	"""Set the speed multiplier (clamped to 1.0 - 10.0)"""
	current_speed_multiplier = clamp(multiplier, min_speed, max_speed)
	current_scroll_speed = base_scroll_speed * current_speed_multiplier
	print("[ScrollingSystem] Speed set to %.1fx" % current_speed_multiplier)


func adjust_speed_multiplier(delta_multiplier: float) -> void:
	"""Adjust speed multiplier by a delta amount (clamped to 1.0 - 10.0)"""
	current_speed_multiplier += delta_multiplier
	current_speed_multiplier = clamp(current_speed_multiplier, min_speed, max_speed)
	current_scroll_speed = base_scroll_speed * current_speed_multiplier
	print("[ScrollingSystem] Speed adjusted to %.1fx"% current_speed_multiplier)


func get_distance() -> float:
	"""Get current scroll distance"""
	return scroll_distance


func get_speed_multiplier() -> float:
	"""Get current speed multiplier"""
	return current_speed_multiplier


func get_scroll_speed() -> float:
	"""Get current scroll speed (px/s)"""
	return current_scroll_speed


func get_distance_display() -> String:
	"""Get formatted distance display string"""
	if scroll_distance < 1000:
		return "Distance: %d px" % int(scroll_distance)
	else:
		return "Distance: %.1f km" % (scroll_distance / 1000.0)
