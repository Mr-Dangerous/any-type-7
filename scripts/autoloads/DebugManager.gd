extends Node

# ============================================================
# DEBUG MANAGER - DEVELOPMENT TOOLS
# ============================================================
# Purpose: Runtime debug controls for testing and tuning
# Handles tractor beam tuning parameters
# ============================================================

# ============================================================
# TRACTOR BEAM SYSTEM
# ============================================================

# Debris attraction and collection
var debris_attraction_range: float = 0.0  # Debris starts moving toward player within this range (disabled, potential upgrade)
var debris_attraction_speed: float = 150.0  # Speed debris moves toward player (px/sec)
var tractor_beam_range: float = 200.0  # Range at which tractor beam locks onto debris (doubled)
var tractor_beam_duration: float = 2.0  # Time to pull debris to player (seconds)
var tractor_beam_projectile_count: int = 3  # Max simultaneous tractor beams

# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
	print("[DebugManager] Initialized - Tractor Beam Controls")
	print("  Attraction Range: %.0f px (disabled)" % debris_attraction_range)
	print("  Beam Range: %.0f px" % tractor_beam_range)
	print("  Beam Duration: %.1f sec" % tractor_beam_duration)
	print("  Max Beams: %d" % tractor_beam_projectile_count)

# ============================================================
# TRACTOR BEAM CONTROLS
# ============================================================

func increase_attraction_range() -> void:
	"""Increase debris attraction range"""
	debris_attraction_range = min(debris_attraction_range + 25.0, 500.0)
	print("[DebugManager] Attraction range increased: %.0f px" % debris_attraction_range)

func decrease_attraction_range() -> void:
	"""Decrease debris attraction range"""
	debris_attraction_range = max(debris_attraction_range - 25.0, 0.0)
	print("[DebugManager] Attraction range decreased: %.0f px" % debris_attraction_range)

func increase_attraction_speed() -> void:
	"""Increase debris attraction speed"""
	debris_attraction_speed = min(debris_attraction_speed + 25.0, 500.0)
	print("[DebugManager] Attraction speed increased: %.0f px/sec" % debris_attraction_speed)

func decrease_attraction_speed() -> void:
	"""Decrease debris attraction speed"""
	debris_attraction_speed = max(debris_attraction_speed - 25.0, 25.0)
	print("[DebugManager] Attraction speed decreased: %.0f px/sec" % debris_attraction_speed)

func increase_beam_range() -> void:
	"""Increase tractor beam lock range"""
	tractor_beam_range = min(tractor_beam_range + 10.0, 300.0)
	print("[DebugManager] Beam range increased: %.0f px" % tractor_beam_range)

func decrease_beam_range() -> void:
	"""Decrease tractor beam lock range"""
	tractor_beam_range = max(tractor_beam_range - 10.0, 25.0)
	print("[DebugManager] Beam range decreased: %.0f px" % tractor_beam_range)

func increase_beam_duration() -> void:
	"""Increase tractor beam pull duration"""
	tractor_beam_duration = min(tractor_beam_duration + 0.5, 10.0)
	print("[DebugManager] Beam duration increased: %.1f sec" % tractor_beam_duration)

func decrease_beam_duration() -> void:
	"""Decrease tractor beam pull duration"""
	tractor_beam_duration = max(tractor_beam_duration - 0.5, 0.5)
	print("[DebugManager] Beam duration decreased: %.1f sec" % tractor_beam_duration)

func increase_beam_count() -> void:
	"""Increase max simultaneous tractor beams"""
	tractor_beam_projectile_count = min(tractor_beam_projectile_count + 1, 10)
	print("[DebugManager] Max beams increased: %d" % tractor_beam_projectile_count)

func decrease_beam_count() -> void:
	"""Decrease max simultaneous tractor beams"""
	tractor_beam_projectile_count = max(tractor_beam_projectile_count - 1, 1)
	print("[DebugManager] Max beams decreased: %d" % tractor_beam_projectile_count)

# Getters
func get_attraction_range() -> float:
	return debris_attraction_range

func get_attraction_speed() -> float:
	return debris_attraction_speed

func get_beam_range() -> float:
	return tractor_beam_range

func get_beam_duration() -> float:
	return tractor_beam_duration

func get_beam_count() -> int:
	return tractor_beam_projectile_count

# ============================================================
# DEBUG INFO
# ============================================================

func print_debug_info() -> void:
	print("=".repeat(60))
	print("DEBUG MANAGER - TRACTOR BEAM CONTROLS")
	print("=".repeat(60))
	print("Attraction Range: %.0f px" % debris_attraction_range)
	print("Attraction Speed: %.0f px/sec" % debris_attraction_speed)
	print("Beam Range: %.0f px" % tractor_beam_range)
	print("Beam Duration: %.1f sec" % tractor_beam_duration)
	print("Max Beams: %d" % tractor_beam_projectile_count)
	print("=".repeat(60))
