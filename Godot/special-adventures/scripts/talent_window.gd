extends Window

# Make smaller boxes and reduce horizontal spacing
const TALENT_BUTTON_SIZE = Vector2(60, 60)  # Smaller square boxes
const TALENT_SPACING_X = 85  # Reduced horizontal spacing
const TALENT_SPACING_Y = 100  # Slightly reduced vertical spacing
const TOP_MARGIN = 50
const LEFT_MARGIN = 40

var player = null
var talent_buttons = {}
var talent_lines = {}
var available_points = 0

signal talent_points_spent(talent_id)

# Track mouse position for tooltips
var mouse_position = Vector2.ZERO

# Talent data reference
var warrior_talents = {}
var talent_manager = null

func _ready():
	# Initialize the talent manager
	# Use preloaded script to avoid parsing issues
	var TalentManagerClass = load("res://scripts/talent_manager.gd")
	talent_manager = TalentManagerClass.new()
	add_child(talent_manager)  # Add as child so it gets _ready() called
	
	# Connect close button
	var close_button = get_node("Panel/MarginContainer/VBoxContainer/ButtonsContainer/CloseButton")
	close_button.pressed.connect(func(): hide())
	
	# Wait for talent manager to be ready
	await get_tree().process_frame
	
	# Load warrior talents from the talent manager
	warrior_talents = talent_manager.get_talent_tree("warrior")
	
	# Create talent tree
	create_warrior_talent_tree()

func setup(p_player):
	player = p_player
	update_available_points()
	update_talent_buttons()

func update_available_points():
	if player:
		available_points = player.talent_points if "talent_points" in player else 0
		var points_label = get_node("Panel/MarginContainer/VBoxContainer/TopInfo/PointsLabel")
		points_label.text = "Available Points: " + str(available_points)

func _process(_delta):
	# Only update tooltip position when needed (when tooltip is visible)
	var tooltip_panel = get_node_or_null("Panel/MarginContainer/VBoxContainer/TabContainer/Warrior/TooltipPanel")
	if tooltip_panel and tooltip_panel.visible:
		# Get global mouse position - using proper method for Window node
		var global_mouse_pos = get_viewport().get_mouse_position()
		
		# Position tooltip near mouse but ensure it stays within window bounds
		var tooltip_size = tooltip_panel.size
		var window_size = size
		
		var x_pos = min(global_mouse_pos.x + 20, window_size.x - tooltip_size.x - 20)
		var y_pos = min(global_mouse_pos.y + 20, window_size.y - tooltip_size.y - 20)
		
		tooltip_panel.global_position = Vector2(x_pos, y_pos)

func create_warrior_talent_tree():
	var talent_tree = get_node("Panel/MarginContainer/VBoxContainer/TabContainer/Warrior/TalentTree")
	var lines_control = get_node("Panel/MarginContainer/VBoxContainer/TabContainer/Warrior/TalentTree/Lines")
	
	# Create talent buttons
	for talent_id in warrior_talents:
		var talent = warrior_talents[talent_id]
		
		# Create button
		var button = create_talent_button(talent, talent_id)
		
		# Position the button
		var pos_x = LEFT_MARGIN + talent.position.x * TALENT_SPACING_X
		var pos_y = TOP_MARGIN + talent.position.y * TALENT_SPACING_Y
		button.position = Vector2(pos_x, pos_y)
		
		# Add to tree
		talent_tree.add_child(button)
		talent_buttons[talent_id] = button
	
	# Draw connection lines between talents
	for talent_id in warrior_talents:
		var talent = warrior_talents[talent_id]
		if "prerequisites" in talent:
			for prereq_id in talent.prerequisites:
				# Create connection line
				if prereq_id in talent_buttons and talent_id in talent_buttons:
					var line = Line2D.new()
					line.default_color = Color(0.4, 0.4, 0.4, 0.6)  # Gray, semi-transparent
					line.width = 2.0
					
					# Get positions for the line
					var start_pos = talent_buttons[prereq_id].position + TALENT_BUTTON_SIZE / 2
					var end_pos = talent_buttons[talent_id].position + TALENT_BUTTON_SIZE / 2
					
					line.add_point(start_pos)
					line.add_point(end_pos)
					
					lines_control.add_child(line)
					
					# Store reference to update color later
					if not talent_id in talent_lines:
						talent_lines[talent_id] = {}
					talent_lines[talent_id][prereq_id] = line

func create_talent_button(talent, talent_id):
	var button = Button.new()
	button.custom_minimum_size = TALENT_BUTTON_SIZE
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	
	# Store talent data for tooltip
	button.set_meta("talent_data", talent)
	button.set_meta("talent_id", talent_id)
	
	# Connect mouse events for custom tooltips
	button.mouse_entered.connect(func(): _on_talent_button_mouse_entered(button))
	button.mouse_exited.connect(func(): _on_talent_button_mouse_exited(button))
	
	# Create a container for the main content
	var container = CenterContainer.new()
	container.anchors_preset = Control.PRESET_FULL_RECT
	button.add_child(container)
	
	# Create a vertical layout for icon and rank
	var vbox = VBoxContainer.new()
	container.add_child(vbox)
	
	# Placeholder for icon (will be replaced with TextureRect when icons are available)
	var icon_placeholder = Panel.new()
	icon_placeholder.custom_minimum_size = Vector2(32, 32)
	icon_placeholder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Fixed: Added Control. prefix
	vbox.add_child(icon_placeholder)
	
	# Add rank indicator below the icon
	var rank_label = Label.new()
	rank_label.name = "RankLabel"
	rank_label.text = str(talent.current_rank) + "/" + str(talent.max_rank)
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rank_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Fixed: Added Control. prefix
	vbox.add_child(rank_label)
	
	# Connect button press
	button.pressed.connect(func(): on_talent_button_pressed(talent_id))
	
	# Apply styling based on state
	update_button_state(button, talent)
	
	return button

func update_button_state(button, talent):
	if talent.current_rank >= talent.max_rank:
		# Maxed out - red border and background
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.6, 0.0, 0.0, 0.3)  # Red with transparency
		style.border_color = Color(0.8, 0.2, 0.2, 1)  # Solid red border
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		button.add_theme_stylebox_override("normal", style)
		button.disabled = false
		button.button_pressed = true
	elif can_learn_talent(talent):
		# Can learn - green pulsing border
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.05, 0.6)  # Dark background
		style.border_color = Color(0.2, 0.8, 0.2, 1)  # Green border
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style)
		button.disabled = false
	else:
		# Can't learn - grey out
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.15, 0.5)  # Dark grey with transparency
		style.border_color = Color(0.3, 0.3, 0.3, 0.5)  # Grey border
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		button.add_theme_stylebox_override("normal", style)
		button.disabled = true
		
	# Get the rank label and style it
	var rank_label = button.get_node_or_null("CenterContainer/VBoxContainer/RankLabel")
	if rank_label:
		if talent.current_rank >= talent.max_rank:
			rank_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 1))
		elif can_learn_talent(talent):
			rank_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2, 1))
		else:
			rank_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.8))

func can_learn_talent(talent):
	# Check available points
	if available_points <= 0:
		return false
		
	# Check required total points
	var total_spent = get_total_spent_points()
	if total_spent < talent.required_points:
		return false
	
	# Check prerequisites
	if "prerequisites" in talent:
		for prereq_id in talent.prerequisites:
			if not prereq_id in warrior_talents:
				continue
				
			if warrior_talents[prereq_id].current_rank <= 0:
				return false
				
	return true

func get_total_spent_points():
	var total = 0
	for talent_id in warrior_talents:
		total += warrior_talents[talent_id].current_rank
	return total

func on_talent_button_pressed(talent_id):
	var talent = warrior_talents[talent_id]
	
	# Only allow learning if:
	# 1. Not already maxed
	# 2. Prerequisites met
	# 3. Have points available
	if talent.current_rank < talent.max_rank and can_learn_talent(talent):
		talent.current_rank += 1
		available_points -= 1
		
		# Update UI
		var rank_label = talent_buttons[talent_id].get_node("CenterContainer/VBoxContainer/RankLabel")
		rank_label.text = str(talent.current_rank) + "/" + str(talent.max_rank)
		
		update_available_points()
		update_talent_buttons()
		update_talent_lines()
		
		# Check if this talent unlocks an ability
		check_for_ability_unlock(talent_id)
		
		# Emit signal
		talent_points_spent.emit(talent_id)

# New function to check if the talent unlocks an ability
func check_for_ability_unlock(talent_id):
	# Get the game instance
	var game = get_tree().get_first_node_in_group("game")
	if not game or not "ability_manager" in game:
		return
		
	# Get unlocked abilities from talent manager
	var abilities = talent_manager.get_unlocked_abilities(talent_id)
	
	# Teach each unlocked ability to the player
	for ability_name in abilities:
		if ability_name != "":
			var ability_id = game.ability_manager.get_ability_id_by_name(ability_name)
			if ability_id != "":
				game.ability_manager.teach_ability_to_player(ability_id)

func update_talent_buttons():
	for talent_id in warrior_talents:
		var talent = warrior_talents[talent_id]
		var button = talent_buttons[talent_id]
		update_button_state(button, talent)

func update_talent_lines():
	# Update line colors based on talent status
	for talent_id in talent_lines:
		for prereq_id in talent_lines[talent_id]:
			var line = talent_lines[talent_id][prereq_id]
			
			# If prereq is learned, make line red instead of gold
			if warrior_talents[prereq_id].current_rank > 0 and warrior_talents[talent_id].current_rank > 0:
				line.default_color = Color(0.8, 0.2, 0.2, 1)  # Red
			elif warrior_talents[prereq_id].current_rank > 0:
				line.default_color = Color(0.6, 0.6, 0.6, 0.8)  # Lighter gray
			else:
				line.default_color = Color(0.4, 0.4, 0.4, 0.6)  # Gray

func _on_talent_button_mouse_entered(button):
	# Show tooltip when mouse enters talent button
	var tooltip_panel = get_node("Panel/MarginContainer/VBoxContainer/TabContainer/Warrior/TooltipPanel")
	if tooltip_panel:
		# Update tooltip content
		var talent = button.get_meta("talent_data")
		var _talent_id = button.get_meta("talent_id")
		
		var talent_name = tooltip_panel.get_node("MarginContainer/VBoxContainer/TalentName")
		var description = tooltip_panel.get_node("MarginContainer/VBoxContainer/Description")
		
		talent_name.text = talent.name + " (" + str(talent.current_rank) + "/" + str(talent.max_rank) + ")"
		
		# Create detailed description
		var desc_text = talent.description + "\n\n"
		
		# Add requirements
		if talent.required_points > 0:
			desc_text += "Required Points: " + str(talent.required_points) + "\n"
		
		# Add prerequisites
		if "prerequisites" in talent and talent.prerequisites.size() > 0:
			desc_text += "Prerequisites: "
			for i in range(talent.prerequisites.size()):
				if i > 0:
					desc_text += ", "
				var prereq_id = talent.prerequisites[i]
				if warrior_talents.has(prereq_id):
					desc_text += warrior_talents[prereq_id].name
			desc_text += "\n"
		
		# Add effects
		desc_text += "\nEffects:\n"
		for effect in talent.effects:
			desc_text += "• " + effect + "\n"
		
		description.text = desc_text
		
		tooltip_panel.show()

func _on_talent_button_mouse_exited(_button):
	# Hide tooltip when mouse leaves button
	var tooltip_panel = get_node("Panel/MarginContainer/VBoxContainer/TabContainer/Warrior/TooltipPanel")
	if tooltip_panel:
		tooltip_panel.hide()

func _on_tab_changed(_tab_index):
	# Switch UI to show talents for the selected category
	pass
