extends Node

# Declare enumerator
enum FUNC {RELEASE_ROPE_PINS}

# Declare variables
# which objects this trigger affects
export(Array, NodePath) var toAffect
export(FUNC) var function = FUNC.RELEASE_ROPE_PINS
export(bool) var oneShot = true
var alreadyTriggered: bool = false

# connect internal signal to our func on ready
func _ready():
	connect("body_entered", self, "_on_body_entered")

# call our func when body enters
func _on_body_entered(body):
	if (!alreadyTriggered or !oneShot):
		match function:
			FUNC.RELEASE_ROPE_PINS:
				releaseAllPins()
	
	alreadyTriggered = true

# define our basic trigger functions
func releaseAllPins():
	for node in toAffect:
		var obj = get_node(node)
		if (obj.nodes):
			obj.lastPinned = false
			obj.firstPinned = false
