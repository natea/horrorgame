extends CharacterBody3D

## Crawling zombie that chases the player

@export var speed: float = 2.0
@export var chase_range: float = 50.0
@export var attack_range: float = 1.5

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_player: AnimationPlayer = $"Zombie Crawl/AnimationPlayer"

var player: Node3D = null
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	# Find the player in the scene
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	
	# Play the crawl animation on loop
	if animation_player:
		var anims = animation_player.get_animation_list()
		if anims.size() > 0:
			animation_player.play(anims[0])
			animation_player.get_animation(anims[0]).loop_mode = Animation.LOOP_LINEAR

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			move_and_slide()
			return
	
	# Calculate distance to player
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Only chase if within range
	if distance_to_player <= chase_range:
		# Update navigation target
		nav_agent.target_position = player.global_position
		
		# Get next path position
		var next_pos = nav_agent.get_next_path_position()
		var direction = (next_pos - global_position).normalized()
		
		# Face the direction of movement (only on Y axis)
		if direction.length() > 0.1:
			var look_target = global_position + direction
			look_target.y = global_position.y
			look_at(look_target, Vector3.UP)
		
		# Move towards player
		if distance_to_player > attack_range:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			# In attack range - stop and attack
			velocity.x = 0
			velocity.z = 0
			# TODO: Deal damage to player
	else:
		# Player out of range - stop
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	move_and_slide()
