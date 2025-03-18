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

signal talent_selected(talent_id)
signal talent_points_spent(talent_id)

# Track mouse position for tooltips
var mouse_position = Vector2.ZERO

# Warrior talent tree data based on Talents.md
var warrior_talents = {
	"warrior_base": {
		"name": "Warrior",
		"description": "Base warrior class. Increases strength and stamina.",
		"position": Vector2(3, 0),
		"icon": "",
		"max_rank": 1,
		"current_rank": 1,  # Initial talent always active
		"required_points": 0,
		"prerequisites": [],
		"effects": ["STR +1", "STAM +1"]
	},
	"physical_conditioning": {
		"name": "Physical Conditioning",
		"description": "Improves your physical resilience.",
		"position": Vector2(3, 1),
		"icon": "",
		"max_rank": 3,
		"current_rank": 0,
		"required_points": 0,
		"prerequisites": ["warrior_base"],
		"effects": ["STAM +1 per rank"]
	},
	"defensive_stance": {
		"name": "Defensive Stance",
		"description": "Assume a defensive stance that reduces damage taken.",
		"position": Vector2(2, 2),
		"icon": "",
		"max_rank": 2,
		"current_rank": 0,
		"required_points": 3,
		"prerequisites": ["physical_conditioning"],
		"effects": ["Damage reduction +5% per rank"]
	},
	"iron_skin": {
		"name": "Iron Skin",
		"description": "Your skin becomes as tough as iron.",
		"position": Vector2(2, 3),
		"icon": "",
		"max_rank": 3,
		"current_rank": 0,
		"required_points": 5,
		"prerequisites": ["defensive_stance"],
		"effects": ["ARMOR +2 per rank"]
	},
	"fortress": {
		"name": "Fortress",
		"description": "You become an immovable object.",
		"position": Vector2(2, 4),
		"icon": "",
		"max_rank": 1,
		"current_rank": 0,
		"required_points": 8,
		"prerequisites": ["iron_skin"],
		"effects": ["Cannot be knocked back", "STAM +5"]
	},
	"reflective_barrier": {
		"name": "Reflective Barrier",
		"description": "Your defensive prowess allows you to reflect some damage back to attackers.",
		"position": Vector2(2, 5),
		"icon": "",
		"max_rank": 2,
		"current_rank": 0,
		"required_points": 10,
		"prerequisites": ["fortress"],
		"effects": ["Reflect 10% damage per rank"]
	},
	"avatar_of_war": {
		"name": "Avatar of War",
		"description": "Transform into an unstoppable avatar of battle.",
		"position": Vector2(2, 6),
		"icon": "",
		"max_rank": 1,
		"current_rank": 0,
		"required_points": 15,
		"prerequisites": ["reflective_barrier"],
		"effects": ["STR +10", "STAM +10", "ARMOR +10"]
	},
	"strength_of_giants": {
		"name": "Strength of Giants",
		"description": "Increase your strength to superhuman levels.",
		"position": Vector2(1, 4),
		"icon": "",
		"max_rank": 3,
		"current_rank": 0,
		"required_points": 8,
		"prerequisites": ["iron_skin"],
		"effects": ["STR +2 per rank"]
	},
	"combat_recovery": {
		"name": "Combat Recovery",
		"description": "Recover health during combat.",
		"position": Vector2(1, 3),
		"icon": "",
		"max_rank": 2,
		"current_rank": 0,
		"required_points": 5,
		"prerequisites": ["defensive_stance"],
		"effects": ["Heal 1% of max health per second per rank"]
	},
	"agile_footwork": {
		"name": "Agile Footwork",
		"description": "Improve your agility in combat.",
		"position": Vector2(4, 2),
		"icon": "",
		"max_rank": 3,
		"current_rank": 0,
		"required_points": 3,
		"prerequisites": ["physical_conditioning"],
		"effects": ["AGI +1 per rank"]
	},
	"lightning_reflexes": {
		"name": "Lightning Reflexes",
		"description": "React with incredible speed.",
		"position": Vector2(4, 3),
		"icon": "",
		"max_rank": 2,
		"current_rank": 0,
		"required_points": 5,
		"prerequisites": ["agile_footwork"],
		"effects": ["Dodge chance +5% per rank"]
	},
	"counterattack": {
		"name": "Counterattack",
		"description": "Counter enemy attacks with your own.",
		"position": Vector2(4, 4),
		"icon": "",
		"max_rank": 2,
		"current_rank": 0,
		"required_points": 8,
		"prerequisites": ["lightning_reflexes"],
		"effects": ["20% chance to counter per rank"]
	},
	"shield_proficiency": {
		"name": "Shield Proficiency",
		"description": "Improve your ability to use shields.",
		"position": Vector2(3, 2),
		"icon": "",
		"max_rank": 3,
		"current_rank": 0,
		"required_points": 3,
		"prerequisites": ["warrior_base"],
		"effects": ["Block chance +3% per rank"]
	},
	"shield_block": {
		"name": "Shield Block",
		"description": "Actively block incoming attacks with your shield.",
		"position": Vector2(3, 3),
		"icon": "",
		"max_rank": 2,
		"current_rank": 0,
		"required_points": 5,
		"prerequisites": ["shield_proficiency"],
		"effects": ["Block value +10% per rank"]
	},
	"whirlwind_attack": {
		"name": "Whirlwind Attack",
		"description": "Spin in a circle, striking all nearby enemies.",
		"position": Vector2(3, 4),
		"icon": "",
		"max_rank": 1,
		"current_rank": 0,
		"required_points": 8,
		"prerequisites": ["shield_block"],
		"effects": ["AoE damage based on STR"]
	}
}

func _ready():
	# Connect close button
	var close_button = get_node("Panel/MarginContainer/VBoxContainer/ButtonsContainer/CloseButton")
	close_button.pressed.connect(func(): hide())
	
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

func _process(delta):
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
		var rank_label = talent_buttons[talent_id].get_node("RankLabel")
		rank_label.text = str(talent.current_rank) + "/" + str(talent.max_rank)
		
		update_available_points()
		update_talent_buttons()
		update_talent_lines()
		
		# Emit signal
		talent_points_spent.emit(talent_id)

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
	# Get talent data from button metadata
	var talent = button.get_meta("talent_data")
	var talent_id = button.get_meta("talent_id")
	
	# Update tooltip content
	var tooltip_panel = get_node("Panel/MarginContainer/VBoxContainer/TabContainer/Warrior/TooltipPanel")
	var talent_name = tooltip_panel.get_node("MarginContainer/VBoxContainer/TalentName")
	var description = tooltip_panel.get_node("MarginContainer/VBoxContainer/Description")
	
	talent_name.text = talent.name + " (" + str(talent.current_rank) + "/" + str(talent.max_rank) + ")"
	
	# Create detailed description
	var desc_text = talent.description + "\n\n"
	
	# Add requirements
	if talent.required_points > 0:
		desc_text += "Required Points: " + str(talent.required_points) + "\n"
	
	# Add prerequisites
	if talent.prerequisites.size() > 0:
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
	
	# Show the tooltip
	tooltip_panel.show()

func _on_talent_button_mouse_exited(button):
	# Hide tooltip when mouse leaves button
	var tooltip_panel = get_node("Panel/MarginContainer/VBoxContainer/TabContainer/Warrior/TooltipPanel")
	tooltip_panel.hide()
