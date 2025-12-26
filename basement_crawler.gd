extends CharacterBody3D

## Frank - a terrifying crawler that haunts the basement

@export var speed: float = 0.9  # 0.5 (50%) faster than George's 0.6
@export var attack_range: float = 2.0

var player: Node3D = null
var has_caught_player: bool = false
@onready var model: Node3D = $FrankModel
@onready var anim_player: AnimationPlayer = $FrankModel/AnimationPlayer

# Animation blending for smooth loop
var crawl_anim_name: String = "mixamo_com"
var anim_length: float = 0.0
var blend_time: float = 0.3  # Cross-fade duration

func _ready() -> void:
	add_to_group("zombie")

	# Play crawl animation with cross-fade looping
	if anim_player:
		var anims = anim_player.get_animation_list()
		print("Frank animations: ", anims)
		if anims.size() > 0:
			var anim = anim_player.get_animation(crawl_anim_name)
			if anim:
				anim_length = anim.length
				# Don't use built-in loop - we'll handle it manually with cross-fade
				anim.loop_mode = Animation.LOOP_NONE

			anim_player.play(crawl_anim_name)
			anim_player.speed_scale = 0.7  # Slow creepy crawl

	# Find player
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	# Handle smooth animation looping with cross-fade
	if anim_player and anim_length > 0:
		var current_pos = anim_player.current_animation_position
		var adjusted_length = anim_length / anim_player.speed_scale

		# When near the end, restart with a blend
		if current_pos >= (adjusted_length - blend_time):
			anim_player.play(crawl_anim_name, blend_time)
			anim_player.speed_scale = 0.7

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

	# Only chase if player is in basement (Y < -1)
	if player.global_position.y > -1.0:
		return

	# Direct movement toward player
	var direction = (player.global_position - global_position).normalized()
	direction.y = 0  # Stay on floor plane

	# Check for walls using raycast before moving
	var space_state = get_world_3d().direct_space_state
	var ray_origin = global_position + Vector3(0, 0.5, 0)  # Slightly above ground
	var ray_end = ray_origin + direction * 1.5  # Check 1.5m ahead

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

	# Check if caught player
	var distance = global_position.distance_to(player.global_position)
	var y_distance = abs(global_position.y - player.global_position.y)

	if distance < attack_range and y_distance < 2.0 and not has_caught_player:
		catch_player()

	# Face movement direction
	if direction.length() > 0.1:
		var angle = atan2(direction.x, direction.z)
		model.rotation.y = angle

func catch_player() -> void:
	has_caught_player = true
	print("Frank caught you in the basement!")

	if player.has_method("on_caught_by"):
		player.on_caught_by("frank")
	elif player.has_method("on_caught"):
		player.on_caught()
