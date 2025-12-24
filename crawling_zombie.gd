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
		if anims.size() > 0:
			var anim = anim_player.get_animation(anims[0])
			if anim:
				anim.loop_mode = Animation.LOOP_LINEAR
			anim_player.play(anims[0])
	
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
	
	# Update navigation target
	nav_agent.target_position = player.global_position
	
	# Get next path position
	if nav_agent.is_navigation_finished():
		return
	
	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - global_position).normalized()
	direction.y = 0  # Keep on ground
	
	# Move toward next navigation point
	global_position += direction * speed * delta
	
	# Check if caught player (XZ distance only)
	var xz_distance = Vector2(global_position.x, global_position.z).distance_to(Vector2(player.global_position.x, player.global_position.z))
	if xz_distance < attack_range and not has_caught_player:
		catch_player()
	
	# Face movement direction
	if direction.length() > 0.1:
		var angle = atan2(direction.x, direction.z)
		model.rotation.y = angle

func catch_player() -> void:
	has_caught_player = true
	print("Player caught!")
	
	# Tell player they're caught
	if player.has_method("on_caught"):
		player.on_caught()
