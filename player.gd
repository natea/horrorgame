extends CharacterBody3D

# Movement settings
const SPEED = 3.5
const SPRINT_SPEED = 5.5
const JUMP_VELOCITY = 4.0
const MOUSE_SENSITIVITY = 0.003

# Head bob settings for immersion
var bob_freq = 2.0
var bob_amp = 0.05
var t_bob = 0.0

# Stamina for sprinting
var stamina = 100.0
var max_stamina = 100.0
var stamina_drain = 3.33  # Drains over 30 seconds (100 / 30)
var stamina_regen = 15.0
var is_exhausted = false

# References
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var flashlight: SpotLight3D = $Head/Camera3D/Flashlight

# Footstep sounds
var footstep_player: AudioStreamPlayer3D = null
var footstep_timer: float = 0.0
var footstep_interval: float = 0.5  # Time between footsteps
var sprint_footstep_interval: float = 0.3  # Faster when sprinting
var footstep_sound: AudioStream = null

# Flashlight state
var flashlight_on = true
var battery_life: float = 100.0  # 0-100
var flashlight_click_sound: AudioStreamPlayer = null
var max_battery: float = 100.0
var battery_drain_rate: float = 100.0 / 300.0  # Drains over 5 minutes (300 seconds)
var base_flashlight_energy: float = 2.0
var flicker_timer: float = 0.0
var flicker_intensity: float = 0.0

# Death state
var is_dead: bool = false
var death_timer: float = 0.0
var shake_intensity: float = 0.0
var zombie_ref: Node3D = null
var jumpscare_sound: AudioStreamPlayer = null
var caught_by_monster: String = "george"  # "george" or "mother"

# Key inventory
var collected_keys: Array[int] = []
const KEYS_NEEDED: int = 10

# Lore inventory
var collected_lore: Array[int] = []
const LORE_NEEDED: int = 4

# Prisoner rescue tracking
var prisoner_freed: bool = false

# Ladder climbing
var is_on_ladder: bool = false
var ladder_direction: Vector3 = Vector3.FORWARD  # Direction player faces when on ladder
const CLIMB_SPEED: float = 3.0

# Key counter UI
var key_counter_label: Label = null

# Lore counter UI
var lore_counter_label: Label = null

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	base_flashlight_energy = flashlight.light_energy
	setup_footsteps()
	setup_crosshair()
	setup_flashlight_model()
	setup_key_counter()

func setup_crosshair() -> void:
	var canvas = CanvasLayer.new()
	canvas.name = "CrosshairLayer"
	add_child(canvas)

	# Use a Control as container to center the crosshair
	var container = CenterContainer.new()
	container.name = "CrosshairContainer"
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(container)

	var crosshair = ColorRect.new()
	crosshair.name = "Crosshair"
	crosshair.color = Color(1, 1, 1, 1)  # Solid white
	crosshair.custom_minimum_size = Vector2(6, 6)  # Dot size
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(crosshair)

func setup_key_counter() -> void:
	var canvas = CanvasLayer.new()
	canvas.name = "KeyCounterLayer"
	add_child(canvas)

	key_counter_label = Label.new()
	key_counter_label.name = "KeyCounter"
	key_counter_label.text = "Keys: 0/" + str(KEYS_NEEDED)
	key_counter_label.add_theme_font_size_override("font_size", 24)
	key_counter_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2))  # Gold color
	key_counter_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	key_counter_label.position = Vector2(-120, 20)
	canvas.add_child(key_counter_label)

	# Lore counter below key counter
	lore_counter_label = Label.new()
	lore_counter_label.name = "LoreCounter"
	lore_counter_label.text = "Lore: 0/" + str(LORE_NEEDED)
	lore_counter_label.add_theme_font_size_override("font_size", 20)
	lore_counter_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))  # Light blue
	lore_counter_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	lore_counter_label.position = Vector2(-120, 50)
	canvas.add_child(lore_counter_label)

func update_key_counter() -> void:
	if key_counter_label:
		key_counter_label.text = "Keys: " + str(collected_keys.size()) + "/" + str(KEYS_NEEDED)

func setup_flashlight_model() -> void:
	# Setup flashlight click sound
	flashlight_click_sound = AudioStreamPlayer.new()
	flashlight_click_sound.name = "FlashlightClickSound"
	if ResourceLoader.exists("res://audio/flashlight-click-46073.mp3"):
		flashlight_click_sound.stream = load("res://audio/flashlight-click-46073.mp3")
		flashlight_click_sound.volume_db = 15.0
	add_child(flashlight_click_sound)

	# Create a flashlight model in the bottom right of the view
	var flashlight_model = Node3D.new()
	flashlight_model.name = "FlashlightModel"
	camera.add_child(flashlight_model)

	# Position in bottom right corner of view
	flashlight_model.position = Vector3(0.55, -0.3, -0.5)
	flashlight_model.rotation_degrees = Vector3(0, -30, 20)

	# Create black material
	var black_mat = StandardMaterial3D.new()
	black_mat.albedo_color = Color(0.05, 0.05, 0.05)  # Near black

	# Flashlight body (cylinder)
	var body = CSGCylinder3D.new()
	body.name = "Body"
	body.radius = 0.025
	body.height = 0.2
	body.rotation_degrees = Vector3(90, 0, 0)  # Point forward
	body.material = black_mat
	flashlight_model.add_child(body)

	# Flashlight head (wider cylinder at front)
	var head = CSGCylinder3D.new()
	head.name = "Head"
	head.radius = 0.035
	head.height = 0.05
	head.rotation_degrees = Vector3(90, 0, 0)
	head.position = Vector3(0, 0, -0.12)
	head.material = black_mat
	flashlight_model.add_child(head)

	# Lens (front of flashlight - slightly lighter)
	var lens_mat = StandardMaterial3D.new()
	lens_mat.albedo_color = Color(0.2, 0.2, 0.2)

	var lens = CSGCylinder3D.new()
	lens.name = "Lens"
	lens.radius = 0.03
	lens.height = 0.01
	lens.rotation_degrees = Vector3(90, 0, 0)
	lens.position = Vector3(0, 0, -0.145)
	lens.material = lens_mat
	flashlight_model.add_child(lens)

func setup_footsteps() -> void:
	footstep_player = AudioStreamPlayer3D.new()
	footstep_player.name = "FootstepPlayer"
	footstep_player.unit_size = 2.0
	footstep_player.max_distance = 20.0
	add_child(footstep_player)

	# Load footstep sound
	footstep_sound = load("res://audio/footstep_single.wav")

func play_footstep(is_sprinting: bool = false) -> void:
	if footstep_player.playing:
		return

	if footstep_sound:
		footstep_player.stream = footstep_sound
		footstep_player.volume_db = 3.0  # Louder footsteps
		# Faster pitch when sprinting, with slight variation
		if is_sprinting:
			footstep_player.pitch_scale = randf_range(1.2, 1.4)  # Faster when sprinting
		else:
			footstep_player.pitch_scale = randf_range(0.9, 1.1)  # Normal walking
		footstep_player.play()

func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return

	# Mouse look
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

	# Toggle flashlight (only if battery available)
	if event.is_action_pressed("flashlight"):
		if battery_life > 0:
			flashlight_on = !flashlight_on
			flashlight.visible = flashlight_on
			# Play click sound
			if flashlight_click_sound:
				flashlight_click_sound.play()

	# Interact with E key - raycast to find what we're looking at
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		try_interact()

	# Exit mouse capture
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if event is InputEventMouseButton and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func try_interact() -> void:
	# Raycast from camera to see what we're looking at
	var space_state = get_world_3d().direct_space_state
	var cam = camera

	var ray_origin = cam.global_position
	var ray_end = ray_origin + -cam.global_transform.basis.z * 3.0  # 3 meter range

	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = 2  # Layer 2 = interactables (keys)
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var result = space_state.intersect_ray(query)

	if result:
		var hit = result.collider
		# Check if it's a key
		if hit.is_in_group("key") and hit.has_method("collect"):
			hit.collect(self)
		# Check if it's a lore page
		elif hit.is_in_group("lore") and hit.has_method("collect"):
			hit.collect(self)

func _physics_process(delta: float) -> void:
	if is_dead:
		handle_death(delta)
		return

	# Ladder climbing mode
	if is_on_ladder:
		handle_ladder_movement(delta)
		return

	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jumping
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Sprinting and stamina
	var is_sprinting = Input.is_action_pressed("sprint") and not is_exhausted
	if is_sprinting and velocity.length() > 0.1:
		stamina -= stamina_drain * delta
		if stamina <= 0:
			stamina = 0
			is_exhausted = true
	else:
		stamina += stamina_regen * delta
		if stamina >= max_stamina * 0.3:
			is_exhausted = false
		stamina = min(stamina, max_stamina)

	# Movement
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var current_speed = SPRINT_SPEED if is_sprinting else SPEED

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	# Head bob when walking
	if is_on_floor() and direction:
		t_bob += delta * velocity.length() * bob_freq
		camera.transform.origin.y = sin(t_bob) * bob_amp

		# Play footstep sounds
		var current_interval = sprint_footstep_interval if is_sprinting else footstep_interval
		footstep_timer += delta
		if footstep_timer >= current_interval:
			footstep_timer = 0.0
			play_footstep(is_sprinting)
	else:
		t_bob = 0.0
		camera.transform.origin.y = move_toward(camera.transform.origin.y, 0.0, delta * 2.0)
		footstep_timer = 0.0

	move_and_slide()

func _process(delta: float) -> void:
	update_flashlight(delta)

func update_flashlight(delta: float) -> void:
	if not flashlight_on or battery_life <= 0:
		return
	
	# Drain battery
	battery_life -= battery_drain_rate * delta
	battery_life = max(battery_life, 0)
	
	# Calculate dimming based on battery level
	var brightness_factor = battery_life / max_battery
	
	# Start flickering when battery is below 30%
	if battery_life < 30:
		flicker_intensity = (30 - battery_life) / 30.0  # 0 to 1 as battery drains
		flicker_timer += delta * (10 + flicker_intensity * 20)  # Flicker faster as it drains
		
		# Random flicker effect
		var flicker = 1.0 - (sin(flicker_timer * 15) * 0.5 + 0.5) * flicker_intensity * 0.7
		if randf() < flicker_intensity * 0.1:  # Random full flicker
			flicker = randf_range(0.1, 0.5)
		
		flashlight.light_energy = base_flashlight_energy * brightness_factor * flicker
	else:
		flashlight.light_energy = base_flashlight_energy * brightness_factor
	
	# Turn off when dead
	if battery_life <= 0:
		flashlight.visible = false
		flashlight_on = false

func add_battery(amount: float) -> void:
	battery_life = min(battery_life + amount, max_battery)
	if battery_life > 0 and not flashlight.visible:
		flashlight.visible = true
		flashlight_on = true
		if flashlight_click_sound:
			flashlight_click_sound.play()

func add_key(key_id: int) -> void:
	if key_id not in collected_keys:
		collected_keys.append(key_id)
		update_key_counter()
		print("Key collected! ", collected_keys.size(), "/", KEYS_NEEDED)

func get_key_count() -> int:
	return collected_keys.size()

func has_all_keys() -> bool:
	return collected_keys.size() >= KEYS_NEEDED

func add_lore(lore_id: int) -> void:
	if lore_id not in collected_lore:
		collected_lore.append(lore_id)
		update_lore_counter()
		print("Lore collected! ", collected_lore.size(), "/", LORE_NEEDED)

func get_lore_count() -> int:
	return collected_lore.size()

func has_all_lore() -> bool:
	return collected_lore.size() >= LORE_NEEDED

func update_lore_counter() -> void:
	if lore_counter_label:
		lore_counter_label.text = "Lore: " + str(collected_lore.size()) + "/" + str(LORE_NEEDED)

func can_escape() -> bool:
	return has_all_keys() and has_all_lore()

func set_prisoner_freed(freed: bool) -> void:
	prisoner_freed = freed
	print("Prisoner freed: ", freed)

func has_freed_prisoner() -> bool:
	return prisoner_freed

func on_caught() -> void:
	on_caught_by("george")

func on_caught_by(monster: String) -> void:
	if is_dead:
		return

	caught_by_monster = monster
	is_dead = true
	death_timer = 0.0
	shake_intensity = 1.0

	# Find zombie
	zombie_ref = get_tree().get_first_node_in_group("zombie")
	if zombie_ref == null:
		zombie_ref = get_tree().current_scene.get_node_or_null("CrawlingZombie")
	
	# Turn on flashlight for dramatic effect
	flashlight_on = true
	flashlight.visible = true
	flashlight.light_energy = base_flashlight_energy * 5.0
	
	# Position zombie face right in front of camera
	if zombie_ref:
		var zombie_model = zombie_ref.get_node_or_null("ZombieModel")
		if zombie_model:
			# Stop animation for T-pose
			var anim_player = zombie_model.get_node_or_null("AnimationPlayer")
			if anim_player:
				anim_player.stop()
			
			# Get camera forward direction (horizontal only)
			var forward = -camera.global_transform.basis.z
			forward.y = 0
			forward = forward.normalized()
			
			# Place zombie 2 units in front of player at floor level
			zombie_ref.global_position = global_position + forward * 2.0
			zombie_ref.global_position.y = 0
			
			# Make zombie face the player
			zombie_model.rotation.y = atan2(-forward.x, -forward.z)
			
			# Add very bright light on zombie
			var face_light = OmniLight3D.new()
			face_light.light_energy = 10.0
			face_light.omni_range = 10.0
			face_light.light_color = Color(1, 0.8, 0.8)
			face_light.position = Vector3(0, 1.0, 0)
			zombie_ref.add_child(face_light)
			
			print("Zombie at: ", zombie_ref.global_position, " Player at: ", global_position)
	
	# Play jumpscare sound
	play_jumpscare_sound()
	
	# Create jumpscare UI overlay
	create_jumpscare_ui()

func play_jumpscare_sound() -> void:
	jumpscare_sound = AudioStreamPlayer.new()
	add_child(jumpscare_sound)

	# Use cinematic transition sound for jumpscare
	if ResourceLoader.exists("res://audio/cinematic-transition-boom-high-violin-string-creak-tomas-herudek-1-00-06.mp3"):
		jumpscare_sound.stream = load("res://audio/cinematic-transition-boom-high-violin-string-creak-tomas-herudek-1-00-06.mp3")
		jumpscare_sound.volume_db = 5.0
		jumpscare_sound.play()

	# Also play creature scream
	var creature_scream = AudioStreamPlayer.new()
	add_child(creature_scream)
	if ResourceLoader.exists("res://audio/creature-screaming-tomas-herudek-low-3-00-04.mp3"):
		creature_scream.stream = load("res://audio/creature-screaming-tomas-herudek-low-3-00-04.mp3")
		creature_scream.volume_db = 3.0
		creature_scream.play()

func handle_death(delta: float) -> void:
	death_timer += delta
	
	# Shake the jumpscare image
	var jumpscare_ui = get_node_or_null("JumpscareUI")
	if jumpscare_ui:
		var face_sprite = jumpscare_ui.get_node_or_null("JumpscareFace")
		if face_sprite:
			var viewport_size = get_viewport().get_visible_rect().size
			var shake_amount = 15.0 * shake_intensity
			face_sprite.position = viewport_size / 2 + Vector2(
				randf_range(-shake_amount, shake_amount),
				randf_range(-shake_amount, shake_amount)
			)
	
	# Reduce shake over time
	if shake_intensity > 0.3:
		shake_intensity -= delta * 0.5
	
	# Restart after delay
	if death_timer > 3.0:
		get_tree().reload_current_scene()

func create_jumpscare_ui() -> void:
	var canvas = CanvasLayer.new()
	canvas.name = "JumpscareUI"
	add_child(canvas)
	
	# Get viewport size
	var viewport_size = get_viewport().get_visible_rect().size
	print("Viewport size: ", viewport_size)
	
	# Dark background using Control
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0, 0, 0, 1.0)
	bg.position = Vector2.ZERO
	bg.size = viewport_size
	canvas.add_child(bg)
	
	# Jumpscare image using Sprite2D - different image for each monster
	var face_sprite = Sprite2D.new()
	face_sprite.name = "JumpscareFace"
	var tex_path = "res://jumpscare.jpeg"  # George's jumpscare
	if caught_by_monster == "mother":
		tex_path = "res://bertha.jpeg"  # Mother's jumpscare
	elif caught_by_monster == "frank":
		tex_path = "res://frank jumpscare.jpeg"  # Frank's jumpscare
	elif caught_by_monster == "jane":
		tex_path = "res://jane-jumpscare.jpeg"
	var tex = load(tex_path)
	if tex:
		face_sprite.texture = tex
		print("Texture loaded! Size: ", tex.get_size(), " Monster: ", caught_by_monster)
		# Center on screen and scale to fit
		face_sprite.position = viewport_size / 2
		var tex_size = tex.get_size()
		var scale_x = viewport_size.x / tex_size.x
		var scale_y = viewport_size.y / tex_size.y
		# Use min instead of max to fit the whole image
		var scale_factor = min(scale_x, scale_y) * 0.95
		face_sprite.scale = Vector2(scale_factor, scale_factor)
	else:
		print("ERROR: Could not load ", tex_path)
	canvas.add_child(face_sprite)
	
	# Red overlay
	var overlay = ColorRect.new()
	overlay.name = "RedOverlay"
	overlay.color = Color(0.3, 0, 0, 0.2)
	overlay.position = Vector2.ZERO
	overlay.size = viewport_size
	canvas.add_child(overlay)
	
	# Game over text
	var label = Label.new()
	label.name = "GameOverLabel"
	label.text = "YOU DIED"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2.ZERO
	label.size = viewport_size
	label.add_theme_font_size_override("font_size", 72)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.modulate.a = 0.0
	canvas.add_child(label)
	
	# Fade in game over text
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 1.0).set_delay(1.5)

func update_jumpscare_overlay(alpha: float) -> void:
	var canvas = get_node_or_null("JumpscareUI")
	if canvas:
		var overlay = canvas.get_node_or_null("RedOverlay")
		if overlay:
			overlay.color.a = alpha * 0.7

# Ladder climbing functions
func handle_ladder_movement(delta: float) -> void:
	# No gravity on ladder
	velocity = Vector3.ZERO

	# Get vertical input (W = up, S = down)
	var vertical_input = 0.0
	if Input.is_action_pressed("move_forward"):
		vertical_input = 1.0
	elif Input.is_action_pressed("move_backward"):
		vertical_input = -1.0

	# Move up/down
	velocity.y = vertical_input * CLIMB_SPEED

	move_and_slide()

func start_climbing(ladder_center: Vector3, face_direction: Vector3) -> void:
	is_on_ladder = true
	ladder_direction = face_direction
	# Snap player to ladder center (X and Z only)
	global_position.x = ladder_center.x
	global_position.z = ladder_center.z
	print("Started climbing ladder at ", ladder_center)

func stop_climbing() -> void:
	is_on_ladder = false
	print("Stopped climbing ladder")
