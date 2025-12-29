extends Node3D

## A trapdoor that opens when the player interacts with it

var player_nearby: bool = false
var player_ref: Node3D = null
var is_open: bool = false

@onready var door_mesh: CSGBox3D = $DoorMesh
@onready var interaction_area: Area3D = $InteractionArea

func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

func _input(event: InputEvent) -> void:
	if is_open:
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		if player_nearby and player_ref:
			open_trapdoor()

func open_trapdoor() -> void:
	is_open = true
	print("The trapdoor creaks open...")

	# Play door creak sound
	if ResourceLoader.exists("res://audio/door_creak.mp3"):
		var sound = AudioStreamPlayer3D.new()
		sound.stream = load("res://audio/door_creak.mp3")
		sound.volume_db = 5.0
		add_child(sound)
		sound.play()

	# Disable collision so player can fall through
	door_mesh.use_collision = false

	# Animate door opening (swing down on hinge)
	var tween = create_tween()
	tween.tween_property(door_mesh, "rotation:x", deg_to_rad(-100), 0.8)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		player_ref = body

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		player_ref = null
