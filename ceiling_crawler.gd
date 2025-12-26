extends CharacterBody3D

## Mother - a terrifying ceiling crawler on the second floor

@export var speed: float = 0.8  # Slower, creepy crawl
@export var attack_range: float = 2.5
@export var ceiling_height: float = 7.8  # Y position to crawl at (upstairs ceiling)

var player: Node3D = null
var has_caught_player: bool = false
@onready var model: Node3D = $MotherModel
@onready var anim_player: AnimationPlayer = $MotherModel/AnimationPlayer

func _ready() -> void:
	add_to_group("zombie")

	# Flip the model upside down to crawl on ceiling
	if model:
		model.rotation.z = PI  # Rotate 180 degrees to be upside down

	# Play crawl animation
	if anim_player:
		var anims = anim_player.get_animation_list()
		print("Mother animations: ", anims)
		if anims.size() > 0:
			var crawl_anim_name = anims[0]

			var anim = anim_player.get_animation(crawl_anim_name)
			if anim:
				anim.loop_mode = Animation.LOOP_PINGPONG

			anim_player.play(crawl_anim_name)
			anim_player.speed_scale = 0.8  # Match movement speed

	# Find player
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

	# Start at ceiling height
	global_position.y = ceiling_height

func _physics_process(delta: float) -> void:
	if has_caught_player:
		return

	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return

	# Don't chase if player is hiding or dead
	if player.is_in_group("hiding"):
		return
	if player.get("is_dead"):
		return

	# Only chase if player is on second floor (Y > 3)
	if player.global_position.y < 3.0:
		return

	# Direct movement toward player
	var target_pos = Vector3(player.global_position.x, ceiling_height, player.global_position.z)
	var direction = (target_pos - global_position).normalized()
	direction.y = 0  # Stay on ceiling plane

	# Check for walls using raycast before moving
	var space_state = get_world_3d().direct_space_state
	var ray_origin = global_position
	var ray_end = global_position + direction * 1.5  # Check 1.5m ahead

	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.exclude = [self]
	query.collision_mask = 1  # Only check against environment/walls

	var result = space_state.intersect_ray(query)

	if result.is_empty():
		# No wall ahead, move toward player
		global_position.x += direction.x * speed * delta
		global_position.z += direction.z * speed * delta
	else:
		# Wall detected, try to slide along it
		var wall_normal = result.normal
		wall_normal.y = 0
		wall_normal = wall_normal.normalized()

		# Calculate slide direction (perpendicular to wall, toward player)
		var slide_dir = direction - wall_normal * direction.dot(wall_normal)
		slide_dir.y = 0
		if slide_dir.length() > 0.1:
			slide_dir = slide_dir.normalized()
			global_position.x += slide_dir.x * speed * delta
			global_position.z += slide_dir.z * speed * delta

	global_position.y = ceiling_height  # Lock to ceiling

	# Check if caught player
	var xz_distance = Vector2(global_position.x, global_position.z).distance_to(
		Vector2(player.global_position.x, player.global_position.z))
	var y_distance = abs(global_position.y - player.global_position.y)

	# Attack if directly above player
	if xz_distance < attack_range and y_distance < 4.0 and not has_caught_player:
		catch_player()

	# Face movement direction (but upside down)
	if direction.length() > 0.1:
		var angle = atan2(direction.x, direction.z)
		model.rotation.y = angle

func catch_player() -> void:
	has_caught_player = true
	print("Mother caught you from above!")

	if player.has_method("on_caught_by"):
		player.on_caught_by("mother")
	elif player.has_method("on_caught"):
		player.on_caught()
