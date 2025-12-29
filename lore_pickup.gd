extends Area3D

## A collectible lore page - find all 4 to learn the truth and escape

@export var lore_id: int = 0  # 1=Bertha, 2=Jane, 3=Frank, 4=George

var is_collected: bool = false
var pickup_sound: AudioStreamPlayer3D = null
var pickup_audio: AudioStream = null

# Spawn positions for lore pages - spread across all floors
static var spawn_positions: Array[Vector3] = [
	# First floor
	Vector3(3.0, 0.15, 2.0),
	Vector3(-6.0, 0.15, 4.0),
	Vector3(8.0, 0.15, -4.0),
	Vector3(-10.0, 0.15, -2.0),
	# Second floor
	Vector3(5.0, 4.65, 3.0),
	Vector3(-7.0, 4.65, 6.0),
	Vector3(10.0, 4.65, -5.0),
	Vector3(-10.0, 4.65, 0.0),
	# Third floor
	Vector3(6.0, 8.15, 5.0),
	Vector3(-8.0, 8.15, 2.0),
	Vector3(10.0, 8.15, -4.0),
	Vector3(-5.0, 8.15, -6.0),
	# Basement
	Vector3(3.0, -3.85, 2.0),
	Vector3(-6.0, -3.85, 4.0),
	Vector3(8.0, -3.85, -2.0),
	Vector3(-8.0, -3.85, -4.0),
]

static var used_positions: Array[int] = []

# Lore text for each character
static var lore_texts: Dictionary = {
	1: "BERTHA (The Mother)\n\nSubject's brain was surgically modified. Neural pathways were rewired to invert spatial perception. She now believes up is down and down is up. Crawls on ceilings, hunting prey from above.",
	2: "JANE (The Daughter)\n\nSubject was subjected to prolonged psychological torture. Conditioned to believe everyone is trying to hurt her. Trust completely broken. Now attacks anyone who enters her territory.",
	3: "FRANK (The Father)\n\nFirst test subject. Parasitic organism was implanted into brain stem. Parasite has taken control of motor functions. Host consciousness may still be present, trapped within.",
	4: "GEORGE (The Butler)\n\nNo modifications performed. Subject's psychosis is self-induced. Witnessed the transformation of the family he served. Mind shattered. Now hunts intruders with feral intensity.",
	5: "THE PRISONER\n\nWhen George witnessed what happened to his masters, something inside him broke. Consumed by rage and grief, he sought revenge on the world. He captured a villager from the nearby town and imprisoned him in the dungeon. The innocent man has been tortured for weeks. George blames everyone for what happened to the family."
}

func _ready() -> void:
	add_to_group("lore")
	collision_layer = 2  # Layer 2 for interactables
	collision_mask = 0

	# Setup pickup sound
	pickup_sound = AudioStreamPlayer3D.new()
	pickup_sound.unit_size = 5.0
	pickup_sound.max_distance = 20.0
	add_child(pickup_sound)

	if ResourceLoader.exists("res://audio/pickup.mp3"):
		pickup_audio = load("res://audio/pickup.mp3")

	# Create the paper mesh
	create_paper_mesh()

	# Randomize position on spawn
	randomize_position()

func randomize_position() -> void:
	# Lore #5 (prisoner lore) stays in the dungeon on the table - don't randomize
	if lore_id == 5:
		print("Lore #5 (prisoner) staying at fixed position: ", global_position)
		return

	# Reset used positions if this is lore 1 (first to spawn)
	if lore_id == 1:
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
		print("Lore #", lore_id, " spawned at: ", global_position)

func create_paper_mesh() -> void:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "PaperMesh"

	# Create a flat box for the paper
	var box = BoxMesh.new()
	box.size = Vector3(0.3, 0.02, 0.4)  # Flat paper shape
	mesh_instance.mesh = box

	# Create paper material (off-white, slightly dirty)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.85, 0.75)  # Yellowed paper
	mat.roughness = 0.9
	mesh_instance.material_override = mat

	# Position slightly above ground
	mesh_instance.position.y = 0.02

	add_child(mesh_instance)

	# Add collision shape
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.5, 0.3, 0.6)  # Slightly larger for easier pickup
	collision.shape = shape
	collision.position.y = 0.15
	add_child(collision)

func collect(player: Node3D) -> void:
	if is_collected:
		return
	is_collected = true

	# Play pickup sound
	if pickup_audio and pickup_sound:
		pickup_sound.stream = pickup_audio
		pickup_sound.play()

	# Add lore to player's collection
	if player and player.has_method("add_lore"):
		player.add_lore(lore_id)

	# Show lore text to player
	show_lore_popup(player)

	# Hide the paper
	visible = false
	set_deferred("monitoring", false)

	print("Lore #", lore_id, " collected!")

func show_lore_popup(player: Node3D) -> void:
	if lore_id not in lore_texts:
		return

	var lore_text = lore_texts[lore_id]

	# Pause the game
	player.get_tree().paused = true

	# Create popup UI (process mode set to always so it works while paused)
	var canvas = CanvasLayer.new()
	canvas.name = "LorePopup"
	canvas.layer = 100
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	player.add_child(canvas)

	var viewport_size = player.get_viewport().get_visible_rect().size

	# Dark semi-transparent background
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.size = viewport_size
	canvas.add_child(bg)

	# Lore text panel
	var panel = ColorRect.new()
	panel.color = Color(0.15, 0.12, 0.1, 0.95)
	panel.size = Vector2(600, 400)
	panel.position = (viewport_size - panel.size) / 2
	canvas.add_child(panel)

	# Border
	var border = ColorRect.new()
	border.color = Color(0.6, 0.5, 0.3)
	border.size = Vector2(604, 404)
	border.position = panel.position - Vector2(2, 2)
	border.z_index = -1
	canvas.add_child(border)

	# Title
	var title = Label.new()
	title.text = "CLASSIFIED DOCUMENT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(600, 40)
	title.position = panel.position + Vector2(0, 20)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
	canvas.add_child(title)

	# Lore content
	var content = Label.new()
	content.text = lore_text
	content.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.size = Vector2(560, 280)
	content.position = panel.position + Vector2(20, 70)
	content.add_theme_font_size_override("font_size", 18)
	content.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7))
	canvas.add_child(content)

	# Dismiss instruction
	var dismiss = Label.new()
	dismiss.text = "Press any key to continue..."
	dismiss.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dismiss.size = Vector2(600, 30)
	dismiss.position = panel.position + Vector2(0, 360)
	dismiss.add_theme_font_size_override("font_size", 14)
	dismiss.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	canvas.add_child(dismiss)

	# Wait for key press to dismiss
	await player.get_tree().create_timer(0.5).timeout  # Small delay to prevent instant dismiss
   
	# Create a one-shot input handler
	var popup_ref = canvas
	var tree_ref = player.get_tree()
	while popup_ref and is_instance_valid(popup_ref):
		await tree_ref.process_frame
		if Input.is_anything_pressed():
			popup_ref.queue_free()
			# Unpause the game
			tree_ref.paused = false
			break
