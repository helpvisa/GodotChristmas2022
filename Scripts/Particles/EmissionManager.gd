extends Node2D


# set up string to load emission resource
export(String) var emitterResource
var emitter
var root # the root of our scene to instantiate emitter

# load our resource on ready (avoid recursion)
func _ready():
	emitter = load(emitterResource)
	root = get_tree().get_root()

# recieve signal to trigger emission
func _trigger_Emission():
	var newEmitter = emitter.instance()
	root.add_child(newEmitter)
	newEmitter.global_transform.origin = global_transform.origin
	newEmitter.set_emitting(true)
