extends Node3D
## Attach this to any node with OmniLight3D children to make them flicker like candles

@export var flicker_speed: float = 10.0
@export var flicker_intensity: float = 0.15
@export var base_energy: float = 0.3

var lights: Array[OmniLight3D] = []
var time_offsets: Array[float] = []

func _ready() -> void:
	# Find all OmniLight3D children
	for child in get_children():
		if child is OmniLight3D:
			lights.append(child)
			time_offsets.append(randf() * 100.0)  # Random offset for variety

func _process(_delta: float) -> void:
	for i in range(lights.size()):
		var light = lights[i]
		var offset = time_offsets[i]
		
		# Create organic flickering using multiple sine waves
		var flicker = sin((Time.get_ticks_msec() / 1000.0 + offset) * flicker_speed)
		flicker += sin((Time.get_ticks_msec() / 1000.0 + offset) * flicker_speed * 2.3) * 0.5
		flicker += sin((Time.get_ticks_msec() / 1000.0 + offset) * flicker_speed * 0.7) * 0.3
		flicker = flicker / 1.8  # Normalize
		
		# Apply flicker to light energy
		light.light_energy = base_energy + flicker * flicker_intensity
		
		# Subtle color temperature shift
		var warmth = 0.7 + flicker * 0.1
		light.light_color = Color(1.0, warmth, 0.3 + flicker * 0.05)
