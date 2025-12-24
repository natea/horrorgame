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
var stamina_drain = 20.0
var stamina_regen = 15.0
var is_exhausted = false

# References
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var flashlight: SpotLight3D = $Head/Camera3D/Flashlight

# Flashlight state
var flashlight_on = true
var battery_life: float = 100.0  # 0-100
var max_battery: float = 100.0
var battery_drain_rate: float = 100.0 / 120.0  # Drains over 2 minutes (120 seconds)
var base_flashlight_energy: float = 2.0
var flicker_timer: float = 0.0
var flicker_intensity: float = 0.0

# Death state
var is_dead: bool = false
var death_timer: float = 0.0
var shake_intensity: float = 0.0
var zombie_ref: Node3D = null
var jumpscare_sound: AudioStreamPlayer = null

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	base_flashlight_energy = flashlight.light_energy

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
	
	# Exit mouse capture
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event is InputEventMouseButton and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	if is_dead:
		handle_death(delta)
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
	else:
		t_bob = 0.0
		camera.transform.origin.y = move_toward(camera.transform.origin.y, 0.0, delta * 2.0)
	
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

func on_caught() -> void:
	if is_dead:
		return
	
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
	
	# Create a harsh noise burst for jumpscare
	var sample_hz = 22050
	var duration = 1.5
	var samples = int(sample_hz * duration)
	
	var audio = AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_8_BITS
	audio.mix_rate = sample_hz
	audio.stereo = false
	
	var data = PackedByteArray()
	data.resize(samples)
	
	for i in samples:
		var t = float(i) / sample_hz
		# Combine harsh frequencies for scary effect
		var noise = randf_range(-1.0, 1.0)
		var low_freq = sin(t * 100 * TAU) * 0.5
		var mid_freq = sin(t * 300 * TAU) * 0.3
		# Envelope - loud start, fade out
		var envelope = max(0, 1.0 - t / duration)
		envelope = envelope * envelope
		var sample = (noise * 0.6 + low_freq + mid_freq) * envelope
		data[i] = int((sample * 0.5 + 0.5) * 255)
	
	audio.data = data
	jumpscare_sound.stream = audio
	jumpscare_sound.volume_db = 5.0
	jumpscare_sound.play()

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
	
	# Jumpscare image using Sprite2D
	var face_sprite = Sprite2D.new()
	face_sprite.name = "JumpscareFace"
	var tex = load("res://jumpscare.jpeg")
	if tex:
		face_sprite.texture = tex
		print("Texture loaded! Size: ", tex.get_size())
		# Center on screen and scale to fill (slightly smaller)
		face_sprite.position = viewport_size / 2
		var tex_size = tex.get_size()
		var scale_x = viewport_size.x / tex_size.x
		var scale_y = viewport_size.y / tex_size.y
		var scale_factor = max(scale_x, scale_y) * 0.85  # Slightly pulled back
		face_sprite.scale = Vector2(scale_factor, scale_factor)
	else:
		print("ERROR: Could not load jumpscare.jpeg")
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
