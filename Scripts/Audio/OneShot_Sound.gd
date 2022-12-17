extends AudioStreamPlayer2D

# setup
func _ready():
	currentSound = sounds[0] # set a default sound
	stream = currentSound

# function to call with signal
func _on_Sound_Triggered(index):
	if (index < 0 or index > sounds.size() - 1):
		return
	currentSound = sounds[index]
	stream = currentSound

func _on_Player_jumped():
	currentSound = sounds[0]
	stream = currentSound
	play()

#####################
# variable declaration
export(Array, AudioStream) var sounds = [] 
var currentSound = null
