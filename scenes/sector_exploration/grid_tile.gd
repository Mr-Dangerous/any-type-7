extends Node2D

# Grid constants
const GRID_SIZE: int = 100  # 100px squares
const GRID_WIDTH: int = 1080
const GRID_HEIGHT: int = 2340
const GRID_COLOR: Color = Color(0.3, 0.8, 1.0, 1.0)  # Bright cyan, fully opaque
const LINE_WIDTH: float = 3.0


func _ready() -> void:
	queue_redraw()  # Trigger _draw() on ready


func _draw() -> void:
	# Draw vertical lines (every 100px)
	for x in range(0, GRID_WIDTH + 1, GRID_SIZE):
		draw_line(
			Vector2(x, 0),
			Vector2(x, GRID_HEIGHT),
			GRID_COLOR,
			LINE_WIDTH
		)

	# Draw horizontal lines (every 100px)
	for y in range(0, GRID_HEIGHT + 1, GRID_SIZE):
		draw_line(
			Vector2(0, y),
			Vector2(GRID_WIDTH, y),
			GRID_COLOR,
			LINE_WIDTH
		)
