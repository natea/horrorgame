extends Node3D

## A prisoner trapped in the dungeon - can be rescued for 1 key

var player_nearby: bool = false
var player_ref: Node3D = null
var is_freed: bool = false

@onready var interaction_area: Area3D = $InteractionArea
@onready var model: Node3D = $PrisonerModel

func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

	# Play idle/sitting animation if available
	if model:
		var anim_player = model.get_node_or_null("AnimationPlayer")
		if anim_player:
			var anims = anim_player.get_animation_list()
			print("Prisoner animations: ", anims)
			if anims.size() > 0:
				# Play the first animation (usually idle or the imported anim)
				var anim_name = anims[0]
				if "mixamo" in anim_name.to_lower() or anims.size() == 1:
					anim_name = anims[0]
				var anim = anim_player.get_animation(anim_name)
				if anim:
					anim.loop_mode = Animation.LOOP_LINEAR
				anim_player.play(anim_name)
				anim_player.speed_scale = 1.0

func _input(event: InputEvent) -> void:
	if is_freed:
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		if player_nearby and player_ref:
			try_free_prisoner()

func try_free_prisoner() -> void:
	if player_ref.get_key_count() < 1:
		print("You need at least 1 key to free the prisoner!")
		show_message("You need a key to unlock the cell...")
		return

	# Remove one key from player
	if player_ref.collected_keys.size() > 0:
		player_ref.collected_keys.pop_back()
		player_ref.update_key_counter()

	free_prisoner()

func free_prisoner() -> void:
	is_freed = true
	print("You freed the prisoner!")

	# Tell player they freed the prisoner
	if player_ref.has_method("set_prisoner_freed"):
		player_ref.set_prisoner_freed(true)
	else:
		player_ref.set("prisoner_freed", true)

	# Play sound
	if ResourceLoader.exists("res://audio/door_creak.mp3"):
		var sound = AudioStreamPlayer3D.new()
		sound.stream = load("res://audio/door_creak.mp3")
		sound.volume_db = 3.0
		add_child(sound)
		sound.play()

	# Show thank you message
	show_rescue_message()

	# Make prisoner disappear (he escapes)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 2.0)
	tween.tween_callback(queue_free)

func show_message(text: String) -> void:
	if not player_ref:
		return

	var canvas = CanvasLayer.new()
	canvas.name = "PrisonerMessage"
	canvas.layer = 50
	player_ref.add_child(canvas)

	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	canvas.add_child(label)

	# Fade out after 2 seconds
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(canvas):
		canvas.queue_free()

func show_rescue_message() -> void:
	if not player_ref:
		return

	var canvas = CanvasLayer.new()
	canvas.name = "RescueMessage"
	canvas.layer = 50
	player_ref.add_child(canvas)

	var viewport_size = player_ref.get_viewport().get_visible_rect().size

	var label = Label.new()
	label.text = "Thank you... I'll find my own way out.\nYou are a good person."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = viewport_size
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	canvas.add_child(label)

	# Fade out after 3 seconds using player's tween (so it persists)
	var tween = player_ref.create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func():
		if is_instance_valid(canvas):
			canvas.queue_free()
	)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		player_ref = body

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		player_ref = null
