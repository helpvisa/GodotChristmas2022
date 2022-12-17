extends AudioStreamPlayer2D

# setup
func _ready():
	currentSound = sounds[0] # set a default sound
	stream = currentSound

# function to call with signal
func _on_Sound_Triggered():
	var index:int = randi() % sounds.size() # create a random integer
	currentSound = sounds[index]
	stream = currentSound

#####################
# variable declaration
export(Array, AudioStream) var sounds = [] 
var currentSound = null
