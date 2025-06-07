class_name TalentManager
extends Node

# Paths to talent data JSON files
const WARRIOR_TALENTS_PATH = "res://resources/talents/warrior_talents.json"

# Dictionary to store all loaded talent trees
var talent_trees = {}
var current_class = "warrior"

func _ready():
	# Load all talent trees
	load_talent_trees()

# Load all talent tree data from JSON files
func load_talent_trees():
	talent_trees["warrior"] = load_talent_tree(WARRIOR_TALENTS_PATH)

# Load a specific talent tree from JSON file
func load_talent_tree(file_path):
	var json_data = {}
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_text)
		
		if error == OK:
			json_data = json.get_data()
		else:
			push_error("JSON Parse Error: " + json.get_error_message() + " at line " + str(json.get_error_line()))
	else:
		push_error("Failed to open talent data file: " + file_path)
	
	# Convert position arrays to Vector2
	for talent_id in json_data:
		if "position" in json_data[talent_id] and json_data[talent_id].position is Array:
			json_data[talent_id].position = Vector2(json_data[talent_id].position[0], json_data[talent_id].position[1])
			
	return json_data

# Get talent tree for the specified class
func get_talent_tree(p_class_name = ""):
	if p_class_name.is_empty():
		p_class_name = current_class
		
	if p_class_name in talent_trees:
		return talent_trees[p_class_name]
	return {}

# Save talent tree data (e.g., when points are spent)
func save_talent_data(player_talent_data, p_class_name = ""):
	if p_class_name.is_empty():
		p_class_name = current_class
		
	if p_class_name in talent_trees:
		# Update ranks from player data
		for talent_id in player_talent_data:
			if talent_id in talent_trees[p_class_name]:
				talent_trees[p_class_name][talent_id].current_rank = player_talent_data[talent_id]
		# Could add actual saving to player save file here
		return true
	return false

# Reset a talent tree to defaults (all talents at 0 except base)
func reset_talent_tree(p_class_name = ""):
	if p_class_name.is_empty():
		p_class_name = current_class
		
	if p_class_name in talent_trees:
		for talent_id in talent_trees[p_class_name]:
			# Base talent remains at 1, all others reset to 0
			if "required_points" in talent_trees[p_class_name][talent_id] and talent_trees[p_class_name][talent_id].required_points == 0:
				talent_trees[p_class_name][talent_id].current_rank = 1
			else:
				talent_trees[p_class_name][talent_id].current_rank = 0
		return true
	return false

# Check if a talent unlocks an ability
func get_unlocked_abilities(talent_id, p_class_name = ""):
	if p_class_name.is_empty():
		p_class_name = current_class
	
	var abilities = []
	
	if p_class_name in talent_trees and talent_id in talent_trees[p_class_name]:
		var talent = talent_trees[p_class_name][talent_id]
		for effect in talent.effects:
			if effect.begins_with("Unlocks"):
				# Extract ability name, assumes format "Unlocks X ability"
				var ability_name = effect.split("Unlocks ")[1].split(" ability")[0].strip_edges()
				abilities.append(ability_name)
	
	return abilities

# Helper method to get ability ID by name
func get_ability_id_by_name(ability_name):
	var game = get_tree().get_first_node_in_group("game")
	if game and game.ability_manager:
		return game.ability_manager.get_ability_id_by_name(ability_name)
	return ""
