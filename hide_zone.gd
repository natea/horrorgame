extends Area3D

## Hiding spot - zombie can't find player here

signal player_hiding(is_hiding: bool)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_hiding.emit(true)
		# Add player to hiding group
		body.add_to_group("hiding")

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_hiding.emit(false)
		# Remove player from hiding group
		body.remove_from_group("hiding")
