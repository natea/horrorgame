extends Node3D

func _ready() -> void:
	var anim_player = $AnimationPlayer
	if anim_player:
		# Make sure the animation loops
		var anim = anim_player.get_animation("mixamo_com")
		if anim:
			anim.loop_mode = Animation.LOOP_LINEAR
		
		# Play the crawl animation
		anim_player.play("mixamo_com")
