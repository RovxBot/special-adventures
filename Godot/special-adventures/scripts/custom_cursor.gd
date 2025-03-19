extends Node2D

var cursor_normal: Texture2D
var cursor_interact: Texture2D
var cursor_attack: Texture2D

var current_cursor: Texture2D
var hover_object: Object = null

func _ready():
	# Load cursor textures
	cursor_normal = preload("res://assets/cursors/cursor_normal.png")
	cursor_interact = preload("res://assets/cursors/cursor_interact.png")
	cursor_attack = preload("res://assets/cursors/cursor_attack.png")
	
	# Hide default cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# Set initial cursor
	current_cursor = cursor_normal

func _process(_delta):
	# Update cursor position
	position = get_viewport().get_mouse_position()
	
	# Check for objects under cursor
	hover_object = get_object_under_cursor()
	
	# Update cursor texture based on what's under it
	if hover_object:
		if hover_object is Button or hover_object is TextEdit:
			current_cursor = cursor_interact
		elif hover_object.has_meta("is_enemy") and hover_object.get_meta("is_enemy") == true:
			current_cursor = cursor_attack
		else:
			current_cursor = cursor_normal
	else:
		current_cursor = cursor_normal
	
	# Force redraw
	queue_redraw()

func _draw():
	# Draw the cursor
	if current_cursor:
		draw_texture(current_cursor, -current_cursor.get_size() / 2)

func get_object_under_cursor() -> Object:
	# Check what's under the cursor using raycasting
	var space_state = get_world_2d().direct_space_state
	if not space_state:
		return null
		
	var mouse_pos = get_global_mouse_position()
	
	# Create a physics query for mouse position
	var query = PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	# Get results
	var results = space_state.intersect_point(query)
	
	if results and results.size() > 0:
		return results[0]["collider"]
		
	return null
