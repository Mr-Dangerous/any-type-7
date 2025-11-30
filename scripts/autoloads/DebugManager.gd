extends Node

# ============================================================
# DEBUG MANAGER - DEVELOPMENT TOOLS
# ============================================================
# Purpose: Runtime debug controls for testing and tuning
# Allows adjusting spawn rates, speeds, and other values on the fly
# ============================================================

# ============================================================
# SPAWN RATE CONTROLS
# ============================================================

# Planetary body spawning (stars, planets)
var planetary_spawn_interval: float = 800.0  # Pixels between planetary spawns
const PLANETARY_STEP: float = 50.0  # Increment/decrement step

# Debris field spawning (asteroids, clusters)
var debris_spawn_interval: float = 100.0  # Pixels between debris spawns
const DEBRIS_STEP: float = 10.0  # Increment/decrement step
var debris_min_per_cluster: int = 2  # Minimum asteroids per cluster
var debris_max_per_cluster: int = 5  # Maximum asteroids per cluster

# Regular node spawning (traders, outposts, etc.)
var node_spawn_interval: float = 400.0  # Pixels between regular node spawns
const NODE_STEP: float = 25.0  # Increment/decrement step

# ============================================================
# TRACTOR BEAM SYSTEM
# ============================================================

# Debris attraction and collection
var debris_attraction_range: float = 0.0  # Debris starts moving toward player within this range (disabled, potential upgrade)
var debris_attraction_speed: float = 150.0  # Speed debris moves toward player (px/sec)
var tractor_beam_range: float = 100.0  # Range at which tractor beam locks onto debris
var tractor_beam_duration: float = 2.0  # Time to pull debris to player (seconds)
var tractor_beam_projectile_count: int = 3  # Max simultaneous tractor beams

# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
	print("[DebugManager] Initialized")
	print("  Planetary: %.0f px" % planetary_spawn_interval)
	print("  Debris: %.0f px, %d-%d per cluster" % [debris_spawn_interval, debris_min_per_cluster, debris_max_per_cluster])
	print("  Nodes: %.0f px" % node_spawn_interval)

# ============================================================
# PLANETARY BODY SPAWN CONTROLS
# ============================================================

func increase_planetary_rate() -> void:
	"""Spawn planets more frequently"""
	planetary_spawn_interval = max(planetary_spawn_interval - PLANETARY_STEP, 100.0)
	print("[DebugManager] Planetary rate increased - Interval: %.0f px" % planetary_spawn_interval)

func decrease_planetary_rate() -> void:
	"""Spawn planets less frequently"""
	planetary_spawn_interval += PLANETARY_STEP
	print("[DebugManager] Planetary rate decreased - Interval: %.0f px" % planetary_spawn_interval)

func get_planetary_interval() -> float:
	return planetary_spawn_interval

# ============================================================
# DEBRIS FIELD SPAWN CONTROLS
# ============================================================

func increase_debris_rate() -> void:
	"""Spawn debris more frequently"""
	debris_spawn_interval = max(debris_spawn_interval - DEBRIS_STEP, 10.0)
	print("[DebugManager] Debris rate increased - Interval: %.0f px" % debris_spawn_interval)

func decrease_debris_rate() -> void:
	"""Spawn debris less frequently"""
	debris_spawn_interval += DEBRIS_STEP
	print("[DebugManager] Debris rate decreased - Interval: %.0f px" % debris_spawn_interval)

func get_debris_interval() -> float:
	return debris_spawn_interval

func increase_debris_cluster_size() -> void:
	"""Increase maximum debris per cluster"""
	debris_max_per_cluster = min(debris_max_per_cluster + 1, 20)  # Cap at 20
	# Ensure min doesn't exceed max
	debris_min_per_cluster = min(debris_min_per_cluster, debris_max_per_cluster)
	print("[DebugManager] Debris cluster size increased - Range: %d-%d" % [debris_min_per_cluster, debris_max_per_cluster])

func decrease_debris_cluster_size() -> void:
	"""Decrease maximum debris per cluster"""
	debris_max_per_cluster = max(debris_max_per_cluster - 1, 1)  # Min 1
	# Ensure min doesn't exceed max
	debris_min_per_cluster = min(debris_min_per_cluster, debris_max_per_cluster)
	print("[DebugManager] Debris cluster size decreased - Range: %d-%d" % [debris_min_per_cluster, debris_max_per_cluster])

func increase_debris_min_cluster() -> void:
	"""Increase minimum debris per cluster"""
	debris_min_per_cluster = min(debris_min_per_cluster + 1, debris_max_per_cluster)
	print("[DebugManager] Debris min cluster increased - Range: %d-%d" % [debris_min_per_cluster, debris_max_per_cluster])

func decrease_debris_min_cluster() -> void:
	"""Decrease minimum debris per cluster"""
	debris_min_per_cluster = max(debris_min_per_cluster - 1, 1)
	print("[DebugManager] Debris min cluster decreased - Range: %d-%d" % [debris_min_per_cluster, debris_max_per_cluster])

func get_debris_cluster_range() -> Vector2i:
	"""Get debris cluster size range as Vector2i(min, max)"""
	return Vector2i(debris_min_per_cluster, debris_max_per_cluster)

# ============================================================
# REGULAR NODE SPAWN CONTROLS
# ============================================================

func increase_node_rate() -> void:
	"""Spawn nodes more frequently"""
	node_spawn_interval = max(node_spawn_interval - NODE_STEP, 50.0)
	print("[DebugManager] Node rate increased - Interval: %.0f px" % node_spawn_interval)

func decrease_node_rate() -> void:
	"""Spawn nodes less frequently"""
	node_spawn_interval += NODE_STEP
	print("[DebugManager] Node rate decreased - Interval: %.0f px" % node_spawn_interval)

func get_node_interval() -> float:
	return node_spawn_interval

# ============================================================
# TRACTOR BEAM CONTROLS
# ============================================================

func increase_attraction_range() -> void:
	"""Increase debris attraction range"""
	debris_attraction_range = min(debris_attraction_range + 25.0, 500.0)
	print("[DebugManager] Attraction range increased: %.0f px" % debris_attraction_range)

func decrease_attraction_range() -> void:
	"""Decrease debris attraction range"""
	debris_attraction_range = max(debris_attraction_range - 25.0, 50.0)
	print("[DebugManager] Attraction range decreased: %.0f px" % debris_attraction_range)

func increase_attraction_speed() -> void:
	"""Increase debris attraction speed"""
	debris_attraction_speed = min(debris_attraction_speed + 5.0, 100.0)
	print("[DebugManager] Attraction speed increased: %.0f px/sec" % debris_attraction_speed)

func decrease_attraction_speed() -> void:
	"""Decrease debris attraction speed"""
	debris_attraction_speed = max(debris_attraction_speed - 5.0, 5.0)
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
	print("DEBUG MANAGER")
	print("=".repeat(60))
	print("Planetary Interval: %.0f px" % planetary_spawn_interval)
	print("Debris Interval: %.0f px, Cluster Size: %d-%d" % [debris_spawn_interval, debris_min_per_cluster, debris_max_per_cluster])
	print("Node Interval: %.0f px" % node_spawn_interval)
	print("=".repeat(60))
