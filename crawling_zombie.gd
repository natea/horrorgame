extends CharacterBody3D

## George the crawling zombie that chases the player

@export var speed: float = 0.5
@export var attack_range: float = 2.0

var player: Node3D = null
var has_caught_player: bool = false
@onready var model: Node3D = $ZombieModel
@onready var anim_player: AnimationPlayer = $ZombieModel/AnimationPlayer
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
	add_to_group("zombie")

	# Play crawl animation
	if anim_player:
		var anims = anim_player.get_animation_list()
		print("Available animations: ", anims)
		if anims.size() > 0:
			var crawl_anim_name = "mixamo_com"

			var anim = anim_player.get_animation(crawl_anim_name)
			if anim:
				# Use pingpong loop for smoother back-and-forth crawling motion
				# This avoids the snap back to start
				anim.loop_mode = Animation.LOOP_PINGPONG

			anim_player.play(crawl_anim_name)
			anim_player.speed_scale = 0.8  # Slightly slower for creepier crawl
	
	# Find player
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	# Don't do anything if already caught player
	if has_caught_player:
		return
	
	# Find player if not found
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return
	
	# Don't chase if player is hiding or dead
	if player.is_in_group("hiding"):
		return
	if player.get("is_dead"):
		return

	# Don't chase if player is in basement (George stays on first floor only)
	if player.global_position.y < -1.0:
		return

	# Update navigation target
	nav_agent.target_position = player.global_position

	# Get next path position
	if nav_agent.is_navigation_finished():
		return

	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - global_position).normalized()

	# Check if next position would be in the basement hole - go around it
	var future_pos = global_position + direction * speed * delta
	if is_near_basement_hole(future_pos):
		# Find which side to go around
		direction = get_direction_around_hole(global_position, player.global_position)
		if direction == Vector3.ZERO:
			return

	# Move toward next navigation point
	global_position += direction * speed * delta
	
	# Check if caught player (must be on same floor - within 2m height difference)
	var y_distance = abs(global_position.y - player.global_position.y)
	var xz_distance = Vector2(global_position.x, global_position.z).distance_to(Vector2(player.global_position.x, player.global_position.z))
	if xz_distance < attack_range and y_distance < 2.0 and not has_caught_player:
		catch_player()
	
	# Face movement direction
	if direction.length() > 0.1:
		var angle = atan2(direction.x, direction.z)
		model.rotation.y = angle

func is_near_basement_hole(pos: Vector3) -> bool:
	# Basement hole is at approximately X: -2 to 2, Z: -2 to 6
	return pos.x > -4 and pos.x < 4 and pos.z > -3 and pos.z < 8

func get_direction_around_hole(my_pos: Vector3, target_pos: Vector3) -> Vector3:
	# Hole center is at X=0, Z=2.5
	var hole_center = Vector3(0, 0, 2.5)

	# Determine which side of the hole we're on and which way to go around
	var to_target = target_pos - my_pos
	to_target.y = 0

	# If we're on the left of the hole, go further left to get around
	# If we're on the right, go further right
	var direction: Vector3

	if my_pos.x < 0:
		# We're on the left, go around the left side (negative X)
		if my_pos.z < 2.5:
			# Go left and forward
			direction = Vector3(-1, 0, 0.5).normalized()
		else:
			# Go left and backward
			direction = Vector3(-1, 0, -0.5).normalized()
	else:
		# We're on the right, go around the right side (positive X)
		if my_pos.z < 2.5:
			# Go right and forward
			direction = Vector3(1, 0, 0.5).normalized()
		else:
			# Go right and backward
			direction = Vector3(1, 0, -0.5).normalized()

	return direction

func catch_player() -> void:
	has_caught_player = true
	print("Player caught!")

	# Tell player they're caught
	if player.has_method("on_caught"):
		player.on_caught()
