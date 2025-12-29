extends Node3D

## Blood dripping from the ceiling - creates creepy atmosphere

@export var drip_interval_min: float = 2.0
@export var drip_interval_max: float = 8.0
@export var drip_speed: float = 3.0

var drip_timer: float = 0.0
var next_drip_time: float = 3.0
var active_drips: Array[MeshInstance3D] = []

# Blood material
var blood_material: StandardMaterial3D

func _ready() -> void:
	# Create blood material
	blood_material = StandardMaterial3D.new()
	blood_material.albedo_color = Color(0.4, 0.02, 0.02, 0.9)
	blood_material.metallic = 0.3
	blood_material.roughness = 0.4
	blood_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	next_drip_time = randf_range(drip_interval_min, drip_interval_max)

func _process(delta: float) -> void:
	drip_timer += delta

	if drip_timer >= next_drip_time:
		spawn_drip()
		drip_timer = 0.0
		next_drip_time = randf_range(drip_interval_min, drip_interval_max)

	# Update active drips
	var drips_to_remove: Array[MeshInstance3D] = []
	for drip in active_drips:
		if is_instance_valid(drip):
			drip.position.y -= drip_speed * delta
			# Remove drip when it hits the floor (relative to spawn point)
			if drip.position.y < -4.0:
				drips_to_remove.append(drip)

	for drip in drips_to_remove:
		active_drips.erase(drip)
		drip.queue_free()

func spawn_drip() -> void:
	var drip = MeshInstance3D.new()

	# Create elongated droplet shape
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.02
	capsule.height = 0.15
	drip.mesh = capsule
	drip.material_override = blood_material

	# Spawn at ceiling (local position)
	drip.position = Vector3(0, 0, 0)

	add_child(drip)
	active_drips.append(drip)
