class_name Item
extends RefCounted

var name: String
var type: String  # weapon, armor, trinket, etc.
var slot: String  # where it's equipped: head, chest, etc.
var stats: Dictionary = {}  # bonuses like {'STR': 2, 'defense': 5}
var description: String
var level_requirement: int = 1

func _init(p_name: String, p_type: String, p_slot: String, p_stats: Dictionary = {}, p_description: String = "", p_level_req: int = 1):
	name = p_name
	type = p_type
	slot = p_slot
	stats = p_stats
	description = p_description
	level_requirement = p_level_req

func get_stats_text() -> String:
	var text = ""
	for stat in stats.keys():
		text += stat + ": +" + str(stats[stat]) + "\n"
	return text
