@tool
extends EditorScript

func _run():
	var size = 512
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# Base wallpaper color (dark brownish)
	var base_color = Color(0.35, 0.28, 0.22)
	var pattern_color = Color(0.28, 0.22, 0.18)
	var blood_color = Color(0.4, 0.08, 0.05)
	var chip_color = Color(0.5, 0.45, 0.4)
	
	# Fill with base and pattern
	for y in range(size):
		for x in range(size):
			var color = base_color
			
			# Victorian damask-like pattern
			var px = float(x) / size * 8.0
			var py = float(y) / size * 8.0
			
			var grid_x = fmod(px, 1.0) - 0.5
			var grid_y = fmod(py, 1.0) - 0.5
			var diamond = 1.0 - (abs(grid_x) + abs(grid_y)) * 2.0
			
			if diamond > 0.2:
				color = color.lerp(pattern_color, diamond * 0.5)
			
			# Add noise for texture
			var noise_val = _hash(Vector2(x * 0.1, y * 0.1)) * 0.1
			color = color.darkened(noise_val)
			
			# Chipped areas
			var chip_noise = _fbm(Vector2(x * 0.02, y * 0.02))
			if chip_noise > 0.65:
				color = color.lerp(chip_color, (chip_noise - 0.65) * 2.0)
			
			# Blood stains
			var blood_noise = _fbm(Vector2(x * 0.01 + 50, y * 0.01 + 30))
			if blood_noise > 0.75:
				var blood_intensity = (blood_noise - 0.75) * 4.0
				# Drip effect - more likely lower on wall
				var drip = _fbm(Vector2(x * 0.05, y * 0.005))
				if drip > 0.5:
					blood_intensity *= 1.5
				color = color.lerp(blood_color, clamp(blood_intensity, 0, 1))
			
			# Dirt/age spots
			var dirt = _fbm(Vector2(x * 0.03 + 100, y * 0.03 + 100))
			color = color.darkened(dirt * 0.15)
			
			image.set_pixel(x, y, color)
	
	# Save the texture
	image.save_png("res://textures/creepy_wallpaper.png")
	print("Wallpaper texture saved to res://textures/creepy_wallpaper.png")

func _hash(p: Vector2) -> float:
	return fmod(sin(p.x * 127.1 + p.y * 311.7) * 43758.5453, 1.0)

func _noise(p: Vector2) -> float:
	var i = Vector2(floor(p.x), floor(p.y))
	var f = Vector2(fmod(p.x, 1.0), fmod(p.y, 1.0))
	if f.x < 0: f.x += 1.0
	if f.y < 0: f.y += 1.0
	
	f = f * f * (Vector2(3, 3) - 2.0 * f)
	
	var a = _hash(i)
	var b = _hash(i + Vector2(1, 0))
	var c = _hash(i + Vector2(0, 1))
	var d = _hash(i + Vector2(1, 1))
	
	return lerp(lerp(a, b, f.x), lerp(c, d, f.x), f.y)

func _fbm(p: Vector2) -> float:
	var value = 0.0
	var amplitude = 0.5
	var pp = p
	for i in range(4):
		value += amplitude * _noise(pp)
		pp *= 2.0
		amplitude *= 0.5
	return value
