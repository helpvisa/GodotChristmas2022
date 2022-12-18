extends CPUParticles2D


func _physics_process(_delta):
	# remove from scene once emission has stopped
	if !is_emitting():
		queue_free()
