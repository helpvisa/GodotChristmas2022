extends Node2D


# variable declarations
export var firstPinned = true
export var lastPinned = true
export var startingPosition: Vector2 = Vector2(0,0)
export var offsetDirection: Vector2 = Vector2(0,1)
export var pinnedSlack = 1.8
export var nodeDistance: float = 16

export var iterations: int = 80
export var totalNodes: int = 30

export var gravity: Vector2 = Vector2(0, 980)
export var friction: float = 0

export var ropeColour: Color = Color(1,1,1,1)
export(Array, Texture) var ropeTextures
export(bool) var animateTexture = false
export(int) var animTick = 30
export var ropeWidth: float = 1
export var forceMultiplier = 0.002

var nodes = []
var lineRenderer: Line2D
var ticks = 0
var animIndex = 0


###########
# main body
# on load
func _ready():
	# create child nodes
	for i in totalNodes:
		var newNode = {"currentPosition": Vector2(), "oldPosition": Vector2(), "collisions": [], "isTouching": false}
		newNode.currentPosition = startingPosition
		newNode.currentPosition += (offsetDirection) * (nodeDistance * i)
		nodes.push_back(newNode)
	
	# create line renderer as child
	lineRenderer = Line2D.new()
	if ropeTextures:
			lineRenderer.set_texture_mode(1)
			lineRenderer.set_texture(ropeTextures[animIndex])
	else:
		lineRenderer.set_default_color(ropeColour)
	lineRenderer.set_width(ropeWidth)
	lineRenderer.set_antialiased(false)
	lineRenderer.set_begin_cap_mode(2)
	lineRenderer.set_end_cap_mode(2)
	lineRenderer.set_joint_mode(2)
	for i in nodes.size():
		lineRenderer.add_point(nodes[i].currentPosition)
	add_child(lineRenderer)


# physics loop
func _physics_process(delta):
	ticks += 1
	simulate(delta)
	snapshot_collisions()
	for i in iterations:
		apply_constraints()
		resolve_collisions_complex()
	update_line()


##################
# custom functions
# simulate verlet integration
func simulate(delta):
	for i in nodes.size():
		var temp: Vector2 = nodes[i].currentPosition
		var amountMoved = 0
		if (nodes[i].isTouching):
			amountMoved = ((nodes[i].currentPosition - nodes[i].oldPosition) * friction) + (gravity * delta * delta)
		else:
			amountMoved = (nodes[i].currentPosition - nodes[i].oldPosition) + (gravity * delta * delta)
		nodes[i].currentPosition += amountMoved
		nodes[i].oldPosition = temp


# enforce distance constraints between points
func apply_constraints():
	for i in nodes.size() - 1:
		var node1 = nodes[i]
		var node2 = nodes[i + 1]
		
		if i == 0 and firstPinned:
			node1.currentPosition = startingPosition
		elif i + 1 == nodes.size() - 1 and lastPinned:
			if pinnedSlack == 0:
				pinnedSlack = 0.01
			node2.currentPosition = startingPosition + (offsetDirection * (nodeDistance * (nodes.size() / pinnedSlack)))
		
		# get current distance between the two nodes
		var diffX = node1.currentPosition.x - node2.currentPosition.x
		var diffY = node1.currentPosition.y - node2.currentPosition.y
		var distance = node1.currentPosition.distance_to(node2.currentPosition)
		var difference = 0
		
		# avoid a division by zero
		if distance > 0:
			difference = (nodeDistance - distance) / distance
		
		var translation = Vector2(diffX, diffY) * (0.5 * difference)
		
		node1.currentPosition += translation
		node2.currentPosition -= translation


# func to snapshot nearby collisions for rope
func snapshot_collisions():
	# prepare for intersection test w sphere shape
	var physics := get_world_2d().direct_space_state
	var colShape = CircleShape2D.new()
	colShape.radius = 1
	var query = Physics2DShapeQueryParameters.new() # prepare the intersection query into the physics world
	
	for i in nodes.size():
		# reset collisions array
		nodes[i].collisions = []
		
		# create a temp transform for intersection test
		var newTransform = Transform2D()
		newTransform.origin = global_transform.origin + nodes[i].currentPosition # update its position to match node
		query.set_shape(colShape) # set shape for query
		query.transform = newTransform # set transform to query
		var collisions = physics.intersect_shape(query) # perform the query and store its results
		
		nodes[i].collisions = collisions

# resolve collisions w player and disturb rope
func resolve_collisions_simple():
	for i in nodes.size():
		for k in nodes[i].collisions.size():
			var body = nodes[i].collisions[k].collider
			if body.name == "Player":
				nodes[i].currentPosition += body.currentVelocity * forceMultiplier

# old func to resolve collisions based on snapshot
func resolve_collisions_complex():
	for i in nodes.size():
		nodes[i].isTouching = false
		for k in nodes[i].collisions.size():
			var body = nodes[i].collisions[k].collider
			
			if body.name == "Player":
				# skip complex calculation for player
				nodes[i].currentPosition += body.currentVelocity * forceMultiplier
			else:
				# otherwise do regular circle / rect collision
				var shape = body.find_node("CollisionShape*").get_shape()
				if shape is CircleShape2D:
					var radius = shape.get_radius()
					var distance = body.global_transform.origin.distance_to(global_transform.origin + nodes[i].currentPosition)
					
					if distance - radius <= 0:
						# push point outside circle
						var dir = (global_transform.origin + nodes[i].currentPosition) - body.global_transform.origin
						dir = dir.normalized()
						var hitPos = body.global_transform.origin + dir * radius
						nodes[i].currentPosition = hitPos - global_transform.origin
						nodes[i].isTouching = true
				elif shape is RectangleShape2D:
					# get nodes position in local space of collider's transform
					var localPoint = body.to_local(global_transform.origin + nodes[i].currentPosition)
					# get its extents and scale
					var half = shape.get_extents()
					var scalar = body.transform.get_scale()
					var dx = localPoint.x
					var px = half.x - abs(dx)
					
					var dy = 0
					var py = 0
					if px > 0:
						dy = localPoint.y
						py = half.y - abs(dy)
					if py > 0:
						# push node along closest edge
						# multiply distance by scale
						if (px * scalar.x < py * scalar.y):
							var sx = sign(dx)
							localPoint.x = half.x * sx
						else:
							var sy = sign(dy)
							localPoint.y = half.y * sy
						
						var hitPos = body.to_global(localPoint)
						nodes[i].currentPosition = hitPos - global_transform.origin
						nodes[i].isTouching = true

# graphically update line
func update_line():
	for i in nodes.size():
		lineRenderer.set_point_position(i, nodes[i].currentPosition)
	
	if animateTexture and ticks % animTick == 0:
		animIndex += 1
		if animIndex > ropeTextures.size() - 1:
			animIndex = 0
		lineRenderer.set_texture(ropeTextures[animIndex])
