extends Node3D

## Interactive door that opens/closes with E key

@export var open_angle: float = -110.0
@export var open_speed: float = 3.0

var is_open: bool = false
var target_rotation: float = 0.0
var player_nearby: bool = false

var door_sound: AudioStreamPlayer3D = null
var door_creak_sound: AudioStream = null

@onready var interaction_area: Area3D = $InteractionArea

func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	# Enable monitoring
	interaction_area.monitoring = true
	interaction_area.monitorable = true

	# Setup door sound
	door_sound = AudioStreamPlayer3D.new()
	door_sound.name = "DoorSound"
	door_sound.unit_size = 3.0
	door_sound.max_distance = 15.0
	add_child(door_sound)

	# Load door creak sound
	if ResourceLoader.exists("res://audio/door_creak.wav"):
		door_creak_sound = load("res://audio/door_creak.wav")
	elif ResourceLoader.exists("res://audio/door_creak.mp3"):
		door_creak_sound = load("res://audio/door_creak.mp3")

	if door_creak_sound:
		print("Door sound loaded: ", door_creak_sound)
	else:
		print("Warning: No door creak sound found")

	print("Door ready")

func _process(delta: float) -> void:
	# Smoothly rotate door
	rotation_degrees.y = lerp(rotation_degrees.y, target_rotation, open_speed * delta)

func _input(event: InputEvent) -> void:
	# Check for E key press directly
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		print("E pressed, player_nearby: ", player_nearby)
		if player_nearby:
			toggle_door()

func toggle_door() -> void:
	is_open = !is_open
	if is_open:
		target_rotation = open_angle
	else:
		target_rotation = 0.0

	# Play door creak sound
	if door_creak_sound and door_sound:
		door_sound.stream = door_creak_sound
		door_sound.pitch_scale = randf_range(0.9, 1.1)  # Slight variation
		door_sound.play()

func _on_body_entered(body: Node3D) -> void:
	print("Body entered: ", body.name)
	if body.is_in_group("player"):
		player_nearby = true
		print("Player nearby!")

func _on_body_exited(body: Node3D) -> void:
	print("Body exited: ", body.name)
	if body.is_in_group("player"):
		player_nearby = false
		print("Player left")
