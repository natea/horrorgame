extends Node3D

## Interactive door that opens/closes with E key

@export var open_angle: float = -110.0
@export var open_speed: float = 3.0

var is_open: bool = false
var target_rotation: float = 0.0
var player_nearby: bool = false

@onready var interaction_area: Area3D = $InteractionArea

func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	# Enable monitoring
	interaction_area.monitoring = true
	interaction_area.monitorable = true
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
