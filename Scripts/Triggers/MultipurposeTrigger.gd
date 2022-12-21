extends Node

# Declare enumerator
enum FUNC {
	RELEASE_ROPE_PINS,
	RELEASE_ROPE_PINS_TIMED,
	SET_PLAYER_COLLISION,
	DEACTIVATE_PLAYER_TEMP,
	DEPRESS_BUTTON
	}

# Declare variables
# which objects this trigger affects
export(Array, NodePath) var toAffect
export(NodePath) var player
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
			FUNC.RELEASE_ROPE_PINS_TIMED:
				releaseAllPinsTimed()
			FUNC.SET_PLAYER_COLLISION:
				setPlayerCollision()
			FUNC.DEACTIVATE_PLAYER_TEMP:
				deactivePlayerTemp()
			FUNC.DEPRESS_BUTTON:
				depressButton()
	
	alreadyTriggered = true

# define our basic trigger functions
func releaseAllPins():
	for node in toAffect:
		var obj = get_node(node)
		if (obj.nodes):
			obj.lastPinned = false
			obj.firstPinned = false

func releaseAllPinsTimed():
	for node in toAffect:
		if node:
			var obj = get_node(node)
			if (obj.nodes):
				obj.lastPinned = false
				obj.firstPinned = false
			# now wait until next release
			var t = Timer.new()
			t.set_wait_time(0.2)
			t.set_one_shot(true)
			self.add_child(t)
			t.start()
			yield(t, "timeout")

func setPlayerCollision():
	if player:
		var p = get_node(player)
		p.set_collision_layer_bit(0, true)

func deactivePlayerTemp():
	if player:
		var p = get_node(player)
		p.playerIsActive = false
		var t = Timer.new()
		t.set_wait_time(4.3)
		t.set_one_shot(true)
		self.add_child(t)
		t.start()
		yield(t, "timeout")
		p.playerIsActive = true

func depressButton():
	for node in toAffect:
		if node:
			var btn = get_node(node)
			btn.frame = 1
