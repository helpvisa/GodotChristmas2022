extends RigidBody2D


# detect all bodies colliding with this one
func _physics_process(_delta):
	var bodies = get_colliding_bodies()
	for i in bodies:
		if (i is KinematicBody2D):
			print(i.currentVelocity)
