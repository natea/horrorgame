extends Node3D

# Background ambient sounds (non-positional)
@onready var background_drone: AudioStreamPlayer = $BackgroundDrone
@onready var wind_sound: AudioStreamPlayer = $WindSound

# Positional creak sounds
@onready var creaks: Array[AudioStreamPlayer3D] = []

# Timing for random creaks
var creak_timer: float = 0.0
var next_creak_time: float = 5.0

func _ready() -> void:
	# Collect all creak audio players
	for child in $RandomCreaks.get_children():
		if child is AudioStreamPlayer3D:
			creaks.append(child)
	
	# Start background sounds if they have streams assigned
	if background_drone.stream:
		background_drone.play()
	if wind_sound.stream:
		wind_sound.play()
	
	# Set initial random creak time
	next_creak_time = randf_range(3.0, 10.0)

func _process(delta: float) -> void:
	# Random creak timer
	creak_timer += delta
	if creak_timer >= next_creak_time:
		play_random_creak()
		creak_timer = 0.0
		next_creak_time = randf_range(5.0, 15.0)

func play_random_creak() -> void:
	if creaks.is_empty():
		return
	
	# Pick a random creak that isn't currently playing
	var available_creaks = creaks.filter(func(c): return not c.playing)
	if available_creaks.is_empty():
		return
	
	var creak = available_creaks[randi() % available_creaks.size()]
	if creak.stream:
		creak.play()
