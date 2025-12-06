extends Node

## Camera System Module
## Handles camera zoom effects and transitions

# Camera reference
var camera: Camera2D = null

# Zoom state
var base_zoom: Vector2 = Vector2(1.0, 1.0)
var target_zoom: Vector2 = Vector2(1.0, 1.0)
var is_zooming: bool = false
var is_returning: bool = false  # Returning to base zoom
var zoom_duration: float = 0.0
var zoom_elapsed: float = 0.0

# Shake state
var shake_time_remaining: float = 0.0
var shake_intensity: float = 0.0
var camera_original_position: Vector2 = Vector2.ZERO

# Cooldown state
var zoom_cooldown: float = 0.0
const ZOOM_COOLDOWN_TIME: float = 2.0  # 2 second cooldown between zooms

# Zoom animation parameters
const ZOOM_SPEED: float = 8.0  # Lerp speed for smooth zoom
const ZOOM_THRESHOLD: float = 0.01  # Close enough to target


func _ready() -> void:
	print("[CameraSystem] Initialized")


func initialize(cam: Camera2D) -> void:
	"""Initialize with camera reference"""
	camera = cam
	if camera:
		base_zoom = camera.zoom
		target_zoom = base_zoom
		print("[CameraSystem] Camera linked - Base zoom: %.2f" % base_zoom.x)


func process_camera(delta: float) -> void:
	"""Update camera each frame"""
	if not camera:
		return

	# Update cooldown
	if zoom_cooldown > 0.0:
		zoom_cooldown -= delta

	# Handle zoom animation
	if is_zooming or is_returning:
		# If we're zooming in/out, check duration first
		if is_zooming:
			zoom_elapsed += delta
			if zoom_elapsed >= zoom_duration:
				# Duration expired, start returning to base
				is_zooming = false
				is_returning = true
				target_zoom = base_zoom
				print("[CameraSystem] Returning to base zoom %.2f" % base_zoom.x)

		# Smooth lerp to target zoom
		camera.zoom = camera.zoom.lerp(target_zoom, ZOOM_SPEED * delta)

		# Check if we've reached the return target (base zoom)
		if is_returning:
			var distance = abs(camera.zoom.x - target_zoom.x)
			if distance < ZOOM_THRESHOLD:
				camera.zoom = target_zoom
				is_returning = false
				print("[CameraSystem] Zoom complete - at %.2f" % camera.zoom.x)

	# Process camera shake
	_process_shake(delta)


func zoom_in(amount: float, duration: float) -> void:
	"""Zoom in by a multiplier for a duration

	Args:
		amount: Zoom multiplier (e.g., 1.3 for 30% zoom in)
		duration: How long to hold the zoom before returning to normal
	"""
	if not camera:
		return

	# Check cooldown
	if zoom_cooldown > 0.0:
		print("[CameraSystem] Zoom on cooldown (%.1fs remaining)" % zoom_cooldown)
		return

	is_zooming = true
	is_returning = false
	zoom_elapsed = 0.0
	zoom_duration = duration
	target_zoom = base_zoom * amount
	zoom_cooldown = ZOOM_COOLDOWN_TIME

	print("[CameraSystem] Zoom in to %.2fx for %.1fs" % [amount, duration])


func zoom_out(amount: float, duration: float) -> void:
	"""Zoom out by a divisor for a duration

	Args:
		amount: Zoom divisor (e.g., 1.3 to zoom out by 30%)
		duration: How long to hold the zoom before returning to normal
	"""
	if not camera:
		return

	# Check cooldown
	if zoom_cooldown > 0.0:
		print("[CameraSystem] Zoom on cooldown (%.1fs remaining)" % zoom_cooldown)
		return

	is_zooming = true
	is_returning = false
	zoom_elapsed = 0.0
	zoom_duration = duration
	target_zoom = base_zoom / amount
	zoom_cooldown = ZOOM_COOLDOWN_TIME

	print("[CameraSystem] Zoom out by %.2fx for %.1fs" % [amount, duration])


func reset_zoom() -> void:
	"""Immediately reset to base zoom"""
	if not camera:
		return

	is_zooming = false
	is_returning = false
	zoom_elapsed = 0.0
	target_zoom = base_zoom
	camera.zoom = base_zoom

	print("[CameraSystem] Zoom reset")


func set_base_zoom(zoom: float) -> void:
	"""Set the base zoom level"""
	if not camera:
		return

	base_zoom = Vector2(zoom, zoom)
	camera.zoom = base_zoom
	target_zoom = base_zoom

	print("[CameraSystem] Base zoom set to %.2f" % zoom)


func get_current_zoom() -> float:
	"""Get current zoom level"""
	if camera:
		return camera.zoom.x
	return 1.0


# ============================================================
# CAMERA SHAKE SYSTEM
# ============================================================

func start_shake(duration: float, intensity: float) -> void:
	"""Start camera shake effect

	Args:
		duration: How long to shake (seconds)
		intensity: Shake intensity in pixels
	"""
	if not camera:
		return

	shake_time_remaining = duration
	shake_intensity = intensity
	camera_original_position = camera.position
	print("[CameraSystem] Screen shake: %.2fs @ %.1fpx" % [duration, intensity])


func _process_shake(delta: float) -> void:
	"""Process camera shake effect"""
	if not camera:
		return

	if shake_time_remaining > 0.0:
		shake_time_remaining -= delta

		# Apply random shake offset
		var shake_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		camera.offset = shake_offset

		# When shake is done, reset camera
		if shake_time_remaining <= 0.0:
			camera.offset = Vector2.ZERO
			shake_intensity = 0.0
	else:
		# Ensure camera offset is zero when not shaking
		camera.offset = Vector2.ZERO
