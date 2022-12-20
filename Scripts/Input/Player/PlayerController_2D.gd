# inheritance
extends KinematicBody2D


# main code ###########################
# on script load
func _ready():
	# store current position
	positionLastTick = global_transform.origin
	currentPosition = global_transform.origin

func _process(_delta):
	animationHandler()

# fixed update, for physics processing
func _physics_process(delta):
	# capture last frame velocity and position and store it; update current position
	lastTickVelocity = currentVelocity
	positionLastTick = currentPosition
	currentPosition = global_transform.origin
	
	# check if on floor
	if is_on_floor():
		if (states.midair):
			states.midair = false
			states.landed = true
		
		# reset coyote timer
		coyoteTimer = 0
		if (states.waiting):
			playerInput = Vector2()
		
		# update current velocity based on inputs, full ground influence
		currentVelocity += playerInput * moveSpeed / weight
		# apply ground friction
		currentVelocity.x -= (currentVelocity.x * groundFriction) * delta
	else:
		if (currentVelocity.y > gravity * 2):
			states.midair = true
		
		# increment coyote timer
		coyoteTimer += 1
		# update current velocity based on inputs, minimal air influence
		currentVelocity += (playerInput * moveSpeed * airInfluence) / weight
		# apply air friction
		currentVelocity.x -= (currentVelocity.x * airFriction) * delta
	
	# jump logic (checks if is_on_ground or if coyoteTimer is less than allowed coyote time)
	if states.jumped and (is_on_floor() or coyoteTimer < coyoteTime):
		currentVelocity.y = -jumpHeight
		states.midair = true
		states.waiting = false
		emit_signal("jumped")
	
	# apply gravity (perpendicular to floor to stop sliding)
#	var gravityResistance = get_floor_normal() if is_on_floor() else Vector2.UP
#	currentVelocity -= (gravityResistance * (gravity * delta))
	
	# apply gravity (normal)
	currentVelocity.y += (gravity)
		
	# reset states
	states.jumped = false
	states.walking = false
	
	# move kinematic body
	currentVelocity = move_and_slide(currentVelocity, Vector2.UP, true, 4, 0.785398, false)
	
	# get collisions with rigidbodies
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		var body = collision.get_collider()
		if (body is RigidBody2D):
			if currentVelocity.y >= 3 and collision.get_angle() <= 1.55:
				body.apply_impulse(collision.position - body.global_transform.origin, Vector2.DOWN * weight * gravity)
			elif currentVelocity.y < 3 and collision.get_angle() > 1.55:
				body.apply_impulse(collision.position - body.global_transform.origin, Vector2(playerInput.x * 10 + currentVelocity.x, 0))


#######################
# function declarations
func parseExternalInput(extInputs, extStates):
	inputs = extInputs
	playerInput = inputs.movement
	if extStates.justJumped:
		states.jumped = true
	if inputs.movement != Vector2.ZERO and !states.waiting:
		states.walking = true

func animationHandler():
	# handle animation state
	if (is_on_floor()):
		if (states.landed or states.waiting):
			states.landed = false
			if !states.waiting:
				emit_signal("landed")
				states.waiting = true
			
			animator.play("player_landed")
			yield(animator, "animation_finished")
			
			states.waiting = false
		elif (states.walking):
			animator.play("player_walk")
		else:
			animator.play("player_idle")
	else:
		if (currentVelocity.y < 0):
			animator.play("player_jump")
		else:
			animator.play("player_fall")
	
	# handle sprite flip state
	if (playerInput.x < 0):
		sprite.flip_h = true
	elif (playerInput.x > 0):
		sprite.flip_h = false


#######################
# variable declarations
# physics parameters
export var moveSpeed = 20 # player's base movespeed
export(float, 0, 1) var airInfluence = 0.1 # amount of movement influence player retains in midair
export var groundFriction = 4 # ground friction
export var airFriction = 0.5 # air friction
export var weight = 1 # player's weight
export var jumpHeight = 160 # player's jumpheight
export var coyoteTime = 6 # number of ticks a jump is still effective after leaving the ground
export var gravity = 9.8 # effect of gravity on player

# input dict
var inputs = {
	"movement": Vector2(), # store input as Vector2 for future controller support
}

# vectors and tracking variables
var playerInput = Vector2() # store input in 2d vector (forward/backward and left/right)
var lastTickVelocity = Vector2() # store player's velocity from previous update
var currentVelocity = Vector2() # store player's current velocity
var coyoteTimer = 0
var currentPosition = Vector2()
var positionLastTick = Vector2()

# state dictionary containing player state info
var states = {
	"jumped": false,
	"midair": true,
	"landed": false,
	"walking": false,
	"waiting": false,
}

# acquire animator
onready var animator = $AnimationPlayer
onready var sprite = $Sprite

# signal states
signal jumped
signal landed
