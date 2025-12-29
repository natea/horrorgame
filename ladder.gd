extends Node3D

## A climbable ladder - player can go up and down

@export var ladder_height: float = 4.5  # Height of the climbable area
@export var face_direction: Vector3 = Vector3(0, 0, 1)  # Direction player faces when climbing

var climb_area: Area3D = null
var player_on_ladder: Node3D = null

func _ready() -> void:
	# Create the climbing detection area
	climb_area = Area3D.new()
	climb_area.name = "ClimbArea"
	climb_area.collision_layer = 0
	climb_area.collision_mask = 1  # Detect player (layer 1)

	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	# Make the climb area span the full height of the ladder
	shape.size = Vector3(1.5, ladder_height, 1.5)
	collision.shape = shape
	# Center the collision at middle height of ladder
	collision.position.y = ladder_height / 2

	climb_area.add_child(collision)
	add_child(climb_area)

	climb_area.body_entered.connect(_on_body_entered)
	climb_area.body_exited.connect(_on_body_exited)

	print("Ladder ready at ", global_position, " height: ", ladder_height)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("start_climbing"):
		player_on_ladder = body
		var ladder_center = global_position + Vector3(0, body.global_position.y - global_position.y, 0)
		ladder_center.x = global_position.x
		ladder_center.z = global_position.z
		body.start_climbing(ladder_center, face_direction)

func _on_body_exited(body: Node3D) -> void:
	if body == player_on_ladder and body.has_method("stop_climbing"):
		body.stop_climbing()
		player_on_ladder = null
