extends Area3D

## A collectible key - find all 10 to escape the mansion
## Must look directly at the key and press E to pick it up

@export var key_id: int = 0  # Unique identifier for this key
@export var pickup_distance: float = 3.0  # Max distance to pick up

var is_collected: bool = false

# Spawn positions - spread across all floors
# First floor Y=0.06, Second floor Y=4.56, Basement Y=-3.94 (just above floor)
static var spawn_positions: Array[Vector3] = [
	# === FIRST FLOOR (Y = 0.06) ===
	# Center hallway
	Vector3(0.0, 0.06, 0.0),
	Vector3(1.0, 0.06, 3.0),
	Vector3(2.0, 0.06, -3.0),
	Vector3(-1.0, 0.06, 5.0),
	Vector3(3.0, 0.06, -5.0),
	# Left room
	Vector3(-8.0, 0.06, 0.0),
	Vector3(-10.0, 0.06, 4.0),
	# Right room
	Vector3(10.0, 0.06, 0.0),
	Vector3(12.0, 0.06, 4.0),

	# === SECOND FLOOR (Y = 4.56) ===
	# Dining room (right side, X > 2)
	Vector3(5.0, 4.56, 0.0),
	Vector3(8.0, 4.56, 3.0),
	Vector3(10.0, 4.56, -2.0),
	Vector3(6.0, 4.56, 5.0),
	# Kitchen (left side, X < 0, Z > 2)
	Vector3(-5.0, 4.56, 5.0),
	Vector3(-8.0, 4.56, 7.0),
	Vector3(-10.0, 4.56, 4.0),
	# Bathroom (left side, X < 0, Z < -2)
	Vector3(-8.0, 4.56, -5.0),
	Vector3(-10.0, 4.56, -7.0),
	# Near stairs
	Vector3(10.0, 4.56, 7.0),

	# === BASEMENT (Y = -3.94) ===
	Vector3(0.0, -3.94, 0.0),
	Vector3(5.0, -3.94, 3.0),
	Vector3(-5.0, -3.94, 3.0),
	Vector3(8.0, -3.94, -3.0),
	Vector3(-8.0, -3.94, -3.0),
	Vector3(0.0, -3.94, 6.0),
]

static var used_positions: Array[int] = []

func _ready() -> void:
	add_to_group("key")
	# Set collision layer so raycast can hit it
	collision_layer = 2  # Layer 2 for interactables
	collision_mask = 0

	# Randomize position on spawn
	randomize_position()

func randomize_position() -> void:
	# Reset used positions if this is key 1 (first key to spawn)
	if key_id == 1:
		used_positions.clear()

	# Find an unused position
	var available_indices: Array[int] = []
	for i in range(spawn_positions.size()):
		if i not in used_positions:
			available_indices.append(i)

	if available_indices.size() > 0:
		# Pick a random available position
		var random_index = available_indices[randi() % available_indices.size()]
		used_positions.append(random_index)
		global_position = spawn_positions[random_index]
		print("Key #", key_id, " spawned at: ", global_position)

func collect(player: Node3D) -> void:
	if is_collected:
		return
	is_collected = true

	# Add key to player's inventory
	if player and player.has_method("add_key"):
		player.add_key(key_id)

	# Hide the key
	visible = false
	set_deferred("monitoring", false)

	print("Key #", key_id, " collected!")
