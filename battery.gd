extends Area3D

## Battery pickup - restores flashlight power

@export var battery_amount: float = 50.0  # How much battery to restore

var player_nearby: bool = false
var player_ref: Node3D = null
var is_picked_up: bool = false
var cooldown_timer: float = 0.0

# Static list of spawn positions - safely away from all walls
# Interior hallway walls: Left at X=-4, Right at X=6, both spanning Z=-2 to Z=10
# Safe zones: X < -5 (left of left wall), X between -3 and 5 (hallway), X > 7 (right of right wall)
static var spawn_positions: Array[Vector3] = [
	# === FIRST FLOOR ===
	# Center hallway area (between the walls, safe)
	Vector3(0, 0.15, 0),      # Dead center of hallway
	Vector3(2, 0.15, 0),      # Hallway right
	Vector3(-2, 0.15, 0),     # Hallway left
	Vector3(0, 0.15, 5),      # Hallway back
	Vector3(0, 0.15, -5),     # Hallway front
	Vector3(2, 0.15, -5),     # Hallway front right
	Vector3(-2, 0.15, -5),    # Hallway front left

	# Left room (X < -5, away from left wall)
	Vector3(-8, 0.15, 0),     # Left room center
	Vector3(-10, 0.15, -5),   # Left room front
	Vector3(-8, 0.15, 5),     # Left room back

	# Right room (X > 7, away from right wall)
	Vector3(10, 0.15, 0),     # Right room center
	Vector3(10, 0.15, -5),    # Right room front
	Vector3(10, 0.15, 5),     # Right room back

	# === SECOND FLOOR (Y = 4.65) ===
	# Dining room (right side, X > 0) - avoid under the table
	Vector3(5, 4.65, 3),      # Dining room back
	Vector3(10, 4.65, -3),    # Dining room front
	Vector3(10, 4.65, 3),     # Dining room corner

	# Kitchen (left side, X < 0, Z > 0)
	Vector3(-7, 4.65, 5),     # Kitchen center
	Vector3(-10, 4.65, 7),    # Kitchen near fridge
	Vector3(-5, 4.65, 8),     # Kitchen near sink

	# Bathroom (front left, X < -5, Z < -4)
	Vector3(-10, 4.65, -7),   # Bathroom center
	Vector3(-8, 4.65, -6),    # Bathroom near sink

	# Staircase landing
	Vector3(12, 4.65, 8),     # Top of stairs

	# === BASEMENT (Y = -3.85) ===
	Vector3(0, -3.85, 0),     # Basement center
	Vector3(5, -3.85, 3),     # Basement right back
	Vector3(-5, -3.85, 3),    # Basement left back
	Vector3(8, -3.85, -3),    # Basement right front
	Vector3(-8, -3.85, -3),   # Basement left front
	Vector3(0, -3.85, -6),    # Basement front center
	Vector3(10, -3.85, 0),    # Basement far right
	Vector3(-10, -3.85, 0),   # Basement far left
]

@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	print("Battery _ready() called at position: ", global_position)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	monitoring = true
	collision_layer = 0
	collision_mask = 1

func _input(event: InputEvent) -> void:
	if is_picked_up or cooldown_timer > 0:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		if player_nearby and player_ref:
			pickup()

func pickup() -> void:
	if is_picked_up:
		return
	is_picked_up = true
	print("Battery picked up!")
	
	# Give battery to player
	if player_ref and player_ref.has_method("add_battery"):
		player_ref.add_battery(battery_amount)
	
	# Make George faster
	var zombie = get_tree().get_first_node_in_group("zombie")
	if zombie:
		zombie.speed += 0.1  # 0.1 faster each pickup
		print("George is now faster! Speed: ", zombie.speed)
	
	# Teleport battery to new location instead of destroying/recreating
	teleport_to_new_location()

func teleport_to_new_location() -> void:
	# Pick a random position from the list
	var available_positions = spawn_positions.duplicate()
	available_positions.shuffle()
	
	# Find a position that's not too close to player
	var chosen_pos = available_positions[0]
	if player_ref:
		for pos in available_positions:
			var dist = pos.distance_to(player_ref.global_position)
			if dist > 5.0:  # At least 5 meters away
				chosen_pos = pos
				break
	
	# Teleport this battery
	global_position = chosen_pos
	player_nearby = false
	
	# Set cooldown so it can't be picked up immediately
	cooldown_timer = 2.0
	print("Battery teleported to: ", chosen_pos, " - cooldown for 2 seconds")

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		player_ref = body

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		player_ref = null

func _process(delta: float) -> void:
	# Handle cooldown after teleporting
	if cooldown_timer > 0:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			is_picked_up = false
			print("Battery ready to pick up at: ", global_position)
	
	# Safety check - if battery is out of bounds, teleport it back
	if global_position.y < -5 or global_position.y > 10:
		print("Battery out of Y bounds! Resetting...")
		global_position = Vector3(0, 0.15, 0)
	if abs(global_position.x) > 15 or abs(global_position.z) > 12:
		print("Battery out of XZ bounds! Resetting...")
		global_position = Vector3(0, 0.15, 0)
