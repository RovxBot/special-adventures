extends Control

signal character_created(character_data)
signal creation_cancelled

# Constants
const STARTING_POINTS = 10
const MIN_STAT_VALUE = 0
const MAX_STAT_VALUE = 20
const BASE_STAT_VALUE = 0

# Variables to track stats
var remaining_points = STARTING_POINTS
var current_race = "Human"
var stats = {
	"strength": BASE_STAT_VALUE,
	"agility": BASE_STAT_VALUE,
	"stamina": BASE_STAT_VALUE,
	"intelligence": BASE_STAT_VALUE
}

# Race modifiers loaded from JSON
var race_modifiers = {}

func _ready():
	# Load race data from JSON
	load_race_data()
	
	# Connect race buttons to selection function
	var race_buttons = {
		"Human": get_node("CenterContainer/Panel/MarginContainer/VBoxContainer/RaceSection/RaceOptions/HumanButton"),
		"Elf": get_node("CenterContainer/Panel/MarginContainer/VBoxContainer/RaceSection/RaceOptions/ElfButton"),
		"Dwarf": get_node("CenterContainer/Panel/MarginContainer/VBoxContainer/RaceSection/RaceOptions/DwarfButton"),
		"Gnome": get_node("CenterContainer/Panel/MarginContainer/VBoxContainer/RaceSection/RaceOptions/GnomeButton")
	}
	
	for race_name in race_buttons:
		race_buttons[race_name].pressed.connect(func(): select_race(race_name))
		
	# Ensure only one race can be selected at a time
	for race_name in race_buttons:
		race_buttons[race_name].toggled.connect(func(button_pressed):
			if button_pressed:
				for other_race in race_buttons:
					if other_race != race_name:
						race_buttons[other_race].button_pressed = false
		)
	
	# Connect stat buttons
	connect_stat_buttons("strength")
	connect_stat_buttons("agility")
	connect_stat_buttons("stamina") 
	connect_stat_buttons("intelligence")
	
	# Connect create and cancel buttons
	var create_button = get_node("CenterContainer/Panel/MarginContainer/VBoxContainer/ButtonsContainer/CreateButton")
	create_button.pressed.connect(create_character)
	
	var cancel_button = get_node("CenterContainer/Panel/MarginContainer/VBoxContainer/ButtonsContainer/CancelButton")
	cancel_button.pressed.connect(func(): creation_cancelled.emit())
	
	# Initialize UI with default values
	update_race_description()
	update_stats_display()
	update_points_label()

# Load race data from JSON file
func load_race_data():
	var json_file = FileAccess.open("res://resources/races/races.json", FileAccess.READ)
	if json_file:
		var json_text = json_file.get_as_text()
		json_file.close()
		
		var json = JSON.new()
		var error = json.parse(json_text)
		
		if error == OK:
			race_modifiers = json.get_data()
		else:
			push_error("Failed to parse races JSON: " + json.get_error_message() + " at line " + str(json.get_error_line()))
			# Fall back to default race data if JSON fails
			_setup_default_race_data()
	else:
		push_error("Failed to open races JSON file")
		_setup_default_race_data()

# Setup default race data as fallback
func _setup_default_race_data():
	race_modifiers = {
		"Human": {
			"name": "Human",
			"description": "Versatile and adaptable (+1 STR, +1 AGI)",
			"modifiers": {"strength": 1, "agility": 1, "stamina": 0, "intelligence": 0}
		},
		"Elf": {
			"name": "Elf",
			"description": "Graceful and wise (+1 AGI, +1 INT)",
			"modifiers": {"strength": 0, "agility": 1, "stamina": 0, "intelligence": 1}
		},
		"Dwarf": {
			"name": "Dwarf",
			"description": "Hardy and resilient (+2 STAM)",
			"modifiers": {"strength": 0, "agility": 0, "stamina": 2, "intelligence": 0}
		},
		"Gnome": {
			"name": "Gnome",
			"description": "Quick and nimble (+2 AGI)",
			"modifiers": {"strength": 0, "agility": 2, "stamina": 0, "intelligence": 0}
		}
	}

func connect_stat_buttons(stat_name):
	var capitalized = stat_name.capitalize()
	
	# Connect plus button
	var plus_button = get_node("CenterContainer/Panel/MarginContainer/VBoxContainer/StatsSection/StatsGrid/%sPlus" % capitalized)
	plus_button.pressed.connect(func(): increase_stat(stat_name))
	
	# Connect minus button
	var minus_button = get_node("CenterContainer/Panel/MarginContainer/VBoxContainer/StatsSection/StatsGrid/%sMinus" % capitalized)
	minus_button.pressed.connect(func(): decrease_stat(stat_name))

func select_race(race_name):
	current_race = race_name
	update_race_description()
	update_stats_display()

func update_race_description():
	var race_desc_label = get_node("CenterContainer/Panel/MarginContainer/VBoxContainer/RaceSection/RaceBonusLabel")
	var race_info = race_modifiers[current_race]
	race_desc_label.text = "%s: %s" % [race_info.name, race_info.description]

func increase_stat(stat_name):
	if remaining_points <= 0:
		return
		
	stats[stat_name] += 1
	remaining_points -= 1
	
	update_stats_display()
	update_points_label()

func decrease_stat(stat_name):
	# Don't allow stats to go below zero (base value)
	if stats[stat_name] <= BASE_STAT_VALUE:
		return
	
	stats[stat_name] -= 1
	remaining_points += 1
	
	update_stats_display()
	update_points_label()

func update_points_label():
	var points_label = get_node("CenterContainer/Panel/MarginContainer/VBoxContainer/StatsSection/PointsLabel")
	points_label.text = "Attribute Points Remaining: %d" % remaining_points

func update_stats_display():
	# Apply race modifiers to display
	for stat_name in stats:
		var race_modifier = race_modifiers[current_race].modifiers[stat_name]
		var displayed_value = stats[stat_name] + race_modifier
		
		# Update the value label
		var value_label = get_node("CenterContainer/Panel/MarginContainer/VBoxContainer/StatsSection/StatsGrid/%sValue" % stat_name.capitalize())
		value_label.text = str(displayed_value)
		
		# Color based on modifier
		if race_modifier > 0:
			value_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
		elif race_modifier < 0:
			value_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
		else:
			value_label.add_theme_color_override("font_color", Color(1, 1, 1))
		
		# Update button enabled states
		var plus_button = get_node("CenterContainer/Panel/MarginContainer/VBoxContainer/StatsSection/StatsGrid/%sPlus" % stat_name.capitalize())
		var minus_button = get_node("CenterContainer/Panel/MarginContainer/VBoxContainer/StatsSection/StatsGrid/%sMinus" % stat_name.capitalize())
		
		plus_button.disabled = (remaining_points <= 0 or displayed_value >= MAX_STAT_VALUE)
		minus_button.disabled = (stats[stat_name] <= BASE_STAT_VALUE)

func create_character():
	# Get character name
	var name_input = get_node("CenterContainer/Panel/MarginContainer/VBoxContainer/NameSection/NameInput")
	var character_name = name_input.text.strip_edges()
	
	# Validate name
	if character_name.is_empty():
		# You could show an error message here
		return
	
	# Calculate final stats with race modifiers
	var final_stats = {}
	for stat_name in stats:
		final_stats[stat_name] = stats[stat_name] + race_modifiers[current_race].modifiers[stat_name]
	
	# Create character data dictionary
	var character_data = {
		"name": character_name,
		"race": current_race,
		"strength": final_stats["strength"],
		"agility": final_stats["agility"],
		"stamina": final_stats["stamina"],
		"intelligence": final_stats["intelligence"]
	}
	
	# Emit signal with character data
	character_created.emit(character_data)
