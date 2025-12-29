extends Area3D

## A collectible key - find all 10 to escape the mansion
## Must look directly at the key and press E to pick it up

@export var key_id: int = 0  # Unique identifier for this key
@export var pickup_distance: float = 3.0  # Max distance to pick up

var is_collected: bool = false
var pickup_sound: AudioStreamPlayer3D = null
var pickup_audio: AudioStream = null

# Spawn positions - spread across all floors
# Mansion bounds: X=-14 to +14, Z=-9 to +9
# First floor Y=0.15, Second floor Y=4.65, Third floor Y=8.15, Basement Y=-3.85
static var spawn_positions: Array[Vector3] = [
	# === FIRST FLOOR (Y = 0.15) ===
	# Center hallway (between interior walls at X=-5 and X=+5)
	Vector3(0.0, 0.15, 0.0),
	Vector3(2.0, 0.15, 3.0),
	Vector3(-2.0, 0.15, -3.0),
	Vector3(0.0, 0.15, 5.0),
	Vector3(3.0, 0.15, -5.0),
	# Left room (X < -5)
	Vector3(-8.0, 0.15, 0.0),
	Vector3(-10.0, 0.15, 5.0),
	Vector3(-12.0, 0.15, -3.0),
	# Right room (X > 5)
	Vector3(8.0, 0.15, 0.0),
	Vector3(10.0, 0.15, 5.0),

	# === SECOND FLOOR (Y = 4.65) ===
	# Dining room (right side, X > 0)
	Vector3(5.0, 4.65, 0.0),
	Vector3(8.0, 4.65, 3.0),
	Vector3(10.0, 4.65, -3.0),
	# Kitchen (left side, X < 0, Z > 0)
	Vector3(-5.0, 4.65, 5.0),
	Vector3(-8.0, 4.65, 7.0),
	Vector3(-10.0, 4.65, 3.0),
	# Bathroom (left side, X < -5, Z < -4)
	Vector3(-8.0, 4.65, -6.0),
	Vector3(-12.0, 4.65, -7.0),
	# Near stairs
	Vector3(10.0, 4.65, 6.0),

	# === THIRD FLOOR (Y = 8.15) ===
	# Living room (left side, X < 0)
	Vector3(-5.0, 8.15, 0.0),
	Vector3(-8.0, 8.15, 3.0),
	Vector3(-10.0, 8.15, -3.0),
	# Bedroom (right side, X > 0, Z > 0)
	Vector3(5.0, 8.15, 5.0),
	Vector3(8.0, 8.15, 7.0),
	Vector3(10.0, 8.15, 3.0),
	# Bathroom (right side, X > 7, Z < -4)
	Vector3(10.0, 8.15, -6.0),
	Vector3(12.0, 8.15, -7.0),

	# === BASEMENT (Y = -3.85) ===
	Vector3(0.0, -3.85, 0.0),
	Vector3(5.0, -3.85, 3.0),
	Vector3(-5.0, -3.85, 3.0),
	Vector3(8.0, -3.85, -3.0),
	Vector3(-8.0, -3.85, -3.0),
	Vector3(0.0, -3.85, 5.0),
	Vector3(-10.0, -3.85, 0.0),
	Vector3(10.0, -3.85, 0.0),
]

static var used_positions: Array[int] = []

func _ready() -> void:
	add_to_group("key")
	# Set collision layer so raycast can hit it
	collision_layer = 2  # Layer 2 for interactables
	collision_mask = 0

	# Setup pickup sound
	pickup_sound = AudioStreamPlayer3D.new()
	pickup_sound.unit_size = 5.0
	pickup_sound.max_distance = 20.0
	add_child(pickup_sound)

	if ResourceLoader.exists("res://audio/pickup.mp3"):
		pickup_audio = load("res://audio/pickup.mp3")

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

	# Play pickup sound
	if pickup_audio and pickup_sound:
		pickup_sound.stream = pickup_audio
		pickup_sound.play()

	# Add key to player's inventory
	if player and player.has_method("add_key"):
		player.add_key(key_id)

	# Hide the key
	visible = false
	set_deferred("monitoring", false)

	print("Key #", key_id, " collected!")
