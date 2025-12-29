extends CanvasLayer

## Intro cutscene with blood text lore and creepy voice narration

# Audio players for voice narration
var lore_voice: AudioStreamPlayer
var instructions_voice: AudioStreamPlayer

var lore_lines: Array[String] = [
	"YOU ARE THE ONE THEY SENT...",
	"",
	"YOU ARE THE ONE THEY SENT TO INVESTIGATE",
	"THE DEATH OF THE CRAWLERS FAMILY.",
	"",
	"A SCIENTIST USED THEM AS HIS SUBJECTS.",
	"",
	"THE SCIENTIST TURNED THEM INTO",
	"HORRIFYING CREATURES AND THEY DO NOT",
	"SEEM RIGHT ANYMORE.",
	"",
	"THEY KILLED HIM AND WILL KILL ANYONE",
	"WHO CROSSES THEIR PATH...",
	"",
	"GOOD LUCK.",
]

var current_line: int = 0
var current_char: int = 0
var char_timer: float = 0.0
var char_delay: float = 0.05  # Time between each character
var line_delay: float = 0.3   # Extra delay between lines
var line_timer: float = 0.0
var waiting_for_line: bool = false
var lore_done: bool = false

var phase: int = 0  # 0 = lore, 1 = title, 2 = instructions, 3 = fade out, 4 = done
var title_timer: float = 0.0
var fade_timer: float = 0.0
var instructions_timer: float = 0.0

var displayed_text: String = ""

var background: ColorRect
var lore_label: Label
var title_label: Label
var instructions_label: Label
var skip_label: Label
var container: Control

func _ready() -> void:
	print("Intro cutscene starting...")

	# Setup voice narration audio players
	lore_voice = AudioStreamPlayer.new()
	lore_voice.volume_db = 3.0  # Slightly louder for narration
	add_child(lore_voice)

	instructions_voice = AudioStreamPlayer.new()
	instructions_voice.volume_db = 3.0
	add_child(instructions_voice)

	# Load voice narration if available
	if ResourceLoader.exists("res://audio/lore_voice.mp3"):
		lore_voice.stream = load("res://audio/lore_voice.mp3")
		print("Loaded lore voice narration")
	elif ResourceLoader.exists("res://audio/lore_voice.wav"):
		lore_voice.stream = load("res://audio/lore_voice.wav")
		print("Loaded lore voice narration")
	elif ResourceLoader.exists("res://audio/lore_voice.ogg"):
		lore_voice.stream = load("res://audio/lore_voice.ogg")
		print("Loaded lore voice narration")

	if ResourceLoader.exists("res://audio/instructions_voice.mp3"):
		instructions_voice.stream = load("res://audio/instructions_voice.mp3")
		print("Loaded instructions voice narration")
	elif ResourceLoader.exists("res://audio/instructions_voice.wav"):
		instructions_voice.stream = load("res://audio/instructions_voice.wav")
		print("Loaded instructions voice narration")
	elif ResourceLoader.exists("res://audio/instructions_voice.ogg"):
		instructions_voice.stream = load("res://audio/instructions_voice.ogg")
		print("Loaded instructions voice narration")

	# Create container that fills the screen
	container = Control.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)

	# Create black background
	background = ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0, 0, 0, 1)
	container.add_child(background)

	# Create centered container for lore text
	var lore_center = CenterContainer.new()
	lore_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_child(lore_center)

	lore_label = Label.new()
	lore_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lore_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lore_label.add_theme_font_size_override("font_size", 28)
	lore_label.add_theme_color_override("font_color", Color(0.7, 0.05, 0.05))
	lore_label.custom_minimum_size = Vector2(800, 400)
	lore_center.add_child(lore_label)

	# Create centered container for title
	var title_center = CenterContainer.new()
	title_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_child(title_center)

	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 72)
	title_label.add_theme_color_override("font_color", Color(0.8, 0.02, 0.02))
	title_label.text = "THE CRAWLERS"
	title_label.modulate.a = 0
	title_center.add_child(title_label)

	# Create centered container for instructions
	var instructions_center = CenterContainer.new()
	instructions_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_child(instructions_center)

	instructions_label = Label.new()
	instructions_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instructions_label.add_theme_font_size_override("font_size", 32)
	instructions_label.add_theme_color_override("font_color", Color(0.7, 0.05, 0.05))
	instructions_label.text = "TAKE THIS FLASHLIGHT.\n\nCOLLECT BATTERIES TO KEEP POWER\nAND GET KEYS TO ESCAPE."
	instructions_label.modulate.a = 0
	instructions_center.add_child(instructions_label)

	# Create skip label in bottom right corner
	skip_label = Label.new()
	skip_label.text = "Press SPACE to skip"
	skip_label.add_theme_font_size_override("font_size", 18)
	skip_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.7))
	skip_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	skip_label.position = Vector2(-180, -40)
	container.add_child(skip_label)

	# Pause the game during cutscene
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Hide player during cutscene
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.visible = false

	# Start lore voice narration
	if lore_voice.stream:
		lore_voice.play()

	print("Intro cutscene ready, phase: ", phase)

func _input(event: InputEvent) -> void:
	# Skip cutscene on space bar
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		skip_cutscene()

func skip_cutscene() -> void:
	# Stop any playing audio
	if lore_voice and lore_voice.playing:
		lore_voice.stop()
	if instructions_voice and instructions_voice.playing:
		instructions_voice.stop()

	# Jump to end
	phase = 4

func _process(delta: float) -> void:
	match phase:
		0:  # Lore phase
			process_lore(delta)
		1:  # Title phase
			process_title(delta)
		2:  # Instructions phase
			process_instructions(delta)
		3:  # Fade out phase
			process_fade(delta)
		4:  # Done
			end_cutscene()

func process_lore(delta: float) -> void:
	if lore_done:
		return

	if waiting_for_line:
		line_timer += delta
		if line_timer >= line_delay:
			waiting_for_line = false
			line_timer = 0.0
			current_line += 1
			if current_line >= lore_lines.size():
				# Lore finished, move to title after delay
				lore_done = true
				lore_label.modulate.a = 0
				phase = 1
				print("Moving to title phase")
				return
			current_char = 0
		return

	if current_line < lore_lines.size():
		var line = lore_lines[current_line]

		if line == "":
			# Empty line, add newline and move to next
			displayed_text += "\n"
			lore_label.text = displayed_text
			waiting_for_line = true
			return

		char_timer += delta
		if char_timer >= char_delay:
			char_timer = 0.0
			if current_char < line.length():
				displayed_text += line[current_char]
				lore_label.text = displayed_text
				current_char += 1
			else:
				# Line finished
				displayed_text += "\n"
				lore_label.text = displayed_text
				waiting_for_line = true

func process_title(delta: float) -> void:
	title_timer += delta

	# Fade in title
	if title_timer < 2.0:
		title_label.modulate.a = title_timer / 2.0
	elif title_timer < 4.0:
		title_label.modulate.a = 1.0
	else:
		# Move to instructions phase
		phase = 2
		title_label.modulate.a = 0
		instructions_timer = 0.0
		# Start instructions voice narration
		if instructions_voice.stream:
			instructions_voice.play()
		print("Moving to instructions phase")

func process_instructions(delta: float) -> void:
	instructions_timer += delta

	# Fade in instructions
	if instructions_timer < 1.5:
		instructions_label.modulate.a = instructions_timer / 1.5
	elif instructions_timer < 5.0:
		instructions_label.modulate.a = 1.0
	else:
		# Move to fade out phase
		phase = 3
		fade_timer = 0.0
		print("Moving to fade out phase")

func process_fade(delta: float) -> void:
	fade_timer += delta

	# Fade out everything
	var alpha = 1.0 - (fade_timer / 1.5)
	background.modulate.a = alpha
	instructions_label.modulate.a = alpha

	if fade_timer >= 1.5:
		phase = 4
		print("Cutscene ending")

func end_cutscene() -> void:
	# Unpause and show player
	get_tree().paused = false

	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.visible = true

	print("Intro cutscene finished!")

	# Remove cutscene
	queue_free()
