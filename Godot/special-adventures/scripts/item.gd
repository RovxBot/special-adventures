class_name Item
extends RefCounted

var name: String
var type: String  # weapon, armor, trinket, etc.
var slot: String  # where it's equipped: head, chest, etc.
var stats: Dictionary = {}  # bonuses like {'STR': 2, 'defense': 5}
var description: String
var level_requirement: int = 1
var rarity: String = "Common"  # Default is Common

# Update constructor to ensure we can create items with all parameters
func _init(p_name: String, p_type: String, p_slot: String, p_stats: Dictionary = {}, p_description: String = "", p_level_req: int = 1, p_rarity: String = "Common"):
	name = p_name
	type = p_type
	slot = p_slot
	stats = p_stats
	description = p_description
	level_requirement = p_level_req
	rarity = p_rarity

func get_stats_text() -> String:
	var text = ""
	for stat in stats.keys():
		text += stat + ": +" + str(stats[stat]) + "\n"
	return text

# Returns a Color object based on the item's rarity
func get_rarity_color() -> Color:
	match rarity.to_lower():
		"common":
			return Color(0.8, 0.8, 0.8)  # White/Light gray
		"uncommon":
			return Color(0.2, 0.8, 0.2)  # Green
		"rare":
			return Color(0.2, 0.4, 0.8)  # Blue
		"epic":
			return Color(0.6, 0.2, 0.8)  # Purple
		"magic":
			return Color(0.2, 0.6, 0.8)  # Light Blue
		"legendary":
			return Color(1.0, 0.6, 0.1)  # Orange
		"artifact":
			return Color(0.9, 0.1, 0.1)  # Red
		"unique":
			return Color(0.8, 0.6, 0.1)  # Gold
		_:  # Default case for unknown rarities
			return Color(0.8, 0.8, 0.8)  # Default to white/light gray
