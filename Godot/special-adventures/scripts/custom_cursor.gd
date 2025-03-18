extends Node2D

var cursor_normal: Texture
var cursor_interact: Texture
var cursor_attack: Texture

var current_cursor: Texture
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

func _process(delta):
	# Update cursor position
	position = get_global_mouse_position()
	
	# Check for objects under cursor
	hover_object = get_object_under_cursor()
	
	# Update cursor texture based on what's under it
	if hover_object is Button or hover_object is TextEdit:
		current_cursor = cursor_interact
	elif hover_object and hover_object.get_meta("is_enemy", false):
		current_cursor = cursor_attack
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
	var mouse_pos = get_global_mouse_position()
	
	# Create a physics query for mouse position
	var query = PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	query.collide_with_areas = true
	
	# Get results
	var result = space_state.intersect_point(query)
	
	if result.size() > 0:
		return result[0].collider
	return null
