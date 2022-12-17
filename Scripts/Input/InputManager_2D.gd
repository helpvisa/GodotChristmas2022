extends Node

###########
# main code
# execute on script load
func _ready():
	# find player node
	player = get_tree().get_root().find_node(playerName, true, false)
	# connect player node to this inputmanager
	if (player):
		self.connect("sendInput", player, "parseExternalInput")


# process input and send this info to the player controller
func _process(delta):
	# acquire their current state
	processKeyboard()
	
	# emit input signal if player is being controlled
	if managerStates.controllingPlayer:
		emit_signal("sendInput", inputs, states)
	
	# blank the inputs
	resetVars()


###########
# functions
func resetVars():
	# reset vectors
	inputs.movement = Vector2()
	# reset vars in dict
	states.justJumped = false

# process keyboard inputs
func processKeyboard():
	# handle directional movement
	if Input.is_action_pressed(moveLeft):
		inputs.movement.x = -1
	if Input.is_action_pressed(moveRight):
		inputs.movement.x = 1
	
	# handle jumping
	if Input.is_action_just_pressed(jump):
		states.justJumped = true
	
	# handle UI inputs
	if Input.is_action_just_pressed(menuEscape):
		managerStates.controllingPlayer = !managerStates.controllingPlayer

###############
# variables
var inputs = {
	"movement": Vector2(),
}
var states = {
	"justJumped": false,
}
var managerStates = {
	"controllingPlayer": true,
}


# key settings (set which project input map keys to assign to input manager vars)
export var moveLeft = "move_left"
export var moveRight = "move_right"
export var jump = "jump"
export var menuEscape = "ui_cancel"


# signal definitions
signal sendInput


################
# get components
export var playerName = "Player"
var player
