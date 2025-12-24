extends Node3D

## Simple zombie that crawls and chases the player

@export var speed: float = 15.0  # Movement speed

var player: Node3D = null
var start_y: float = 0.0
var base_rotation_x: float = 0.0
@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	start_y = global_position.y
	base_rotation_x = rotation.x  # Store original X rotation
	
	# Play crawl animation
	if anim_player:
		var anims = anim_player.get_animation_list()
		if anims.size() > 0:
			var anim = anim_player.get_animation(anims[0])
			if anim:
				anim.loop_mode = Animation.LOOP_LINEAR
			anim_player.play(anims[0])
	
	# Find player
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return
	
	# Get direction to player
	var direction = (player.global_position - global_position).normalized()
	direction.y = 0  # Stay on ground
	
	# Move toward player (only on X/Z plane)
	global_position.x += direction.x * speed * delta
	global_position.z += direction.z * speed * delta
	global_position.y = start_y  # Stay at original height
	
	# Face the player (disabled for now)
	#if direction.length() > 0.1:
	#	var angle = atan2(direction.x, direction.z)
	#	rotation = Vector3(base_rotation_x, angle, 0)
