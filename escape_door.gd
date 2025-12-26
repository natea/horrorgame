extends Node3D

## The escape door - requires 10 keys to open and escape the mansion

var player_nearby: bool = false
var player_ref: Node3D = null
var is_open: bool = false
var has_escaped: bool = false

@onready var door_mesh: CSGBox3D = $DoorPivot/DoorMesh
@onready var door_pivot: Node3D = $DoorPivot
@onready var door_frame: CSGBox3D = $DoorFrame
@onready var interaction_area: Area3D = $InteractionArea

func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

func _input(event: InputEvent) -> void:
	if has_escaped or is_open:
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		if player_nearby and player_ref:
			try_open_door()

func try_open_door() -> void:
	if player_ref.has_all_keys():
		open_door()
	else:
		var keys_have = player_ref.get_key_count()
		var keys_need = player_ref.KEYS_NEEDED
		print("Door is locked! You need ", keys_need - keys_have, " more keys. (", keys_have, "/", keys_need, ")")

func open_door() -> void:
	is_open = true
	print("The door opens! You can escape!")

	# Disable collision on the door and frame so player can walk through
	door_mesh.use_collision = false
	door_frame.use_collision = false

	# Animate door opening (rotate the pivot so door swings on hinge)
	var tween = create_tween()
	tween.tween_property(door_pivot, "rotation:y", deg_to_rad(-110), 1.0)
	tween.tween_callback(allow_escape)

func allow_escape() -> void:
	# Create escape trigger zone far outside the mansion
	var escape_zone = Area3D.new()
	escape_zone.name = "EscapeZone"

	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(10, 5, 5)
	collision.shape = shape

	escape_zone.add_child(collision)
	escape_zone.global_position = global_position + Vector3(0, 2, -30)  # Far outside
	escape_zone.body_entered.connect(_on_escape_zone_entered)

	get_parent().add_child(escape_zone)

func _on_escape_zone_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not has_escaped:
		has_escaped = true
		trigger_escape(body)

func trigger_escape(player: Node3D) -> void:
	print("You escaped the mansion!")

	# Create win screen
	var canvas = CanvasLayer.new()
	canvas.name = "WinUI"
	player.add_child(canvas)

	var viewport_size = player.get_viewport().get_visible_rect().size

	# Black background
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0)
	bg.size = viewport_size
	canvas.add_child(bg)

	# Fade to black
	var tween = create_tween()
	tween.tween_property(bg, "color:a", 1.0, 2.0)

	# "You Escaped" text
	var label = Label.new()
	label.text = "YOU ESCAPED"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = viewport_size
	label.add_theme_font_size_override("font_size", 72)
	label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
	label.modulate.a = 0.0
	canvas.add_child(label)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "You collected all 10 keys and escaped the horror..."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle.size = viewport_size
	subtitle.position.y = 60
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	subtitle.modulate.a = 0.0
	canvas.add_child(subtitle)

	# Fade in text
	tween.tween_property(label, "modulate:a", 1.0, 1.0).set_delay(1.0)
	tween.tween_property(subtitle, "modulate:a", 1.0, 1.0)

	# Stop player movement
	player.is_dead = true  # Reuse death flag to stop movement

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		player_ref = body

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		player_ref = null
