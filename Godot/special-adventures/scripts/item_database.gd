class_name ItemDatabase
extends RefCounted

var _items = {}  # Dictionary to store all items by ID
var _items_by_type = {}  # Dictionary to store items organized by type
var _items_by_level = {}  # Dictionary to store items organized by level requirement
var _items_by_slot = {}  # Dictionary to store items organized by equipment slot
var _items_by_rarity = {}  # Dictionary to store items organized by rarity

func _init():
	load_database()

# Load the database from JSON files
func load_database():
	# Initialize the category dictionaries
	_items_by_type = {}
	_items_by_level = {}
	_items_by_slot = {}
	_items_by_rarity = {}  # Initialize rarity dictionary
	
	var items_loaded = 0
	var dir_path = "res://data/items/"
	
	# Check if the items directory exists
	var dir = DirAccess.open("res://data/")
	if dir and dir.dir_exists("items"):
		# Open the items directory
		var items_dir = DirAccess.open(dir_path)
		if items_dir:
			# Process each JSON file in the directory
			items_dir.list_dir_begin()
			var file_name = items_dir.get_next()
			
			while file_name != "":
				if not items_dir.current_is_dir() and file_name.ends_with(".json"):
					var json_path = dir_path + file_name
					print("Loading items from: " + json_path)
					items_loaded += process_json_file(json_path)
				file_name = items_dir.get_next()
			
			items_dir.list_dir_end()
	
	# Try loading the combined items file for backward compatibility
	if items_loaded == 0:
		items_loaded = process_json_file("res://data/items.json")
	
	print("Loaded " + str(items_loaded) + " items into database from " + str(_items.size()) + " unique items")

# Process a single JSON file and add its items to the database
func process_json_file(file_path: String) -> int:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("Failed to open items file: " + file_path)
		return 0
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		print("JSON Parse Error in " + file_path + ": " + json.get_error_message() + " at line " + str(json.get_error_line()))
		return 0
	
	var item_data = json.data
	if typeof(item_data) != TYPE_ARRAY:
		print("Unexpected data format in " + file_path + ": not an array")
		return 0
	
	var items_processed = 0
	
	# Process each item in the array
	for item_entry in item_data:
		if typeof(item_entry) != TYPE_DICTIONARY:
			continue
		
		var id = item_entry.get("id", "")
		var name = item_entry.get("name", "Unknown Item")
		var type = item_entry.get("type", "misc")
		var slot = item_entry.get("slot", "")
		var stats = item_entry.get("stats", {})
		var desc = item_entry.get("description", "")
		var level_req = item_entry.get("level_requirement", 1)
		var rarity = item_entry.get("rarity", "Common")  # Default to Common if not specified
		
		var item = Item.new(name, type, slot, stats, desc, level_req, rarity)  # Add rarity parameter
		
		 # Skip if we already have this item (in case of duplicates across files)
		if _items.has(id):
			print("Warning: Duplicate item ID found: " + id)
			continue
		
		# Store by ID
		_items[id] = item
		items_processed += 1
		
		# Store by type
		if not _items_by_type.has(type):
			_items_by_type[type] = []
		_items_by_type[type].append(item)
		
		# Store by level
		if not _items_by_level.has(level_req):
			_items_by_level[level_req] = []
		_items_by_level[level_req].append(item)
		
		# Store by slot
		if slot != "" and not _items_by_slot.has(slot):
			_items_by_slot[slot] = []
		if slot != "":
			_items_by_slot[slot].append(item)
			
		# Store by rarity
		if not _items_by_rarity.has(rarity):
			_items_by_rarity[rarity] = []
		_items_by_rarity[rarity].append(item)
	
	return items_processed

# Get item by ID
func get_item(id: String) -> Item:
	if _items.has(id):
		return _items[id]
	return null

# Get all items of a specific type
func get_items_by_type(type: String) -> Array:
	if _items_by_type.has(type):
		return _items_by_type[type]
	return []

# Get all items for a specific equipment slot
func get_items_by_slot(slot: String) -> Array:
	if _items_by_slot.has(slot):
		return _items_by_slot[slot]
	return []

# Get all items with level requirement <= specified level
func get_items_by_level(level: int) -> Array:
	var result = []
	for req_level in _items_by_level.keys():
		if req_level <= level:
			result.append_array(_items_by_level[req_level])
	return result

# Get items by rarity
func get_items_by_rarity(rarity: String) -> Array:
	if _items_by_rarity.has(rarity):
		return _items_by_rarity[rarity]
	return []

# Get random item of specified type with level <= player_level
func get_random_item(type: String = "", max_level: int = 100) -> Item:
	var eligible_items = []
	
	# If type is specified, only get items of that type
	if type != "":
		if not _items_by_type.has(type):
			return null
		
		for item in _items_by_type[type]:
			if item.level_requirement <= max_level:
				eligible_items.append(item)
	else:
		# If no type specified, get all items with level <= max_level
		for item_id in _items:
			var item = _items[item_id]
			if item.level_requirement <= max_level:
				eligible_items.append(item)
	
	if eligible_items.size() == 0:
		return null
	
	# Return random item from eligible items
	return eligible_items[randi() % eligible_items.size()]

# Generate loot for an enemy based on its level
# For testing purposes, this will generate random items from all categories
func generate_enemy_loot(enemy_level: int) -> Array:
	var loot = []
	
	# Determine number of items to drop (1-3)
	var num_items = 1 + randi() % 3
	
	# Categories of items
	var item_types = ["Weapon", "Shield", "Cloth Armor", "Leather Armor", "Plate Armor", "Potion", "Ring", "Necklace"]
	
	# Drop logic for testing - completely random selection
	for i in range(num_items):
		# 1. Random approach - get any item from the database
		var item = null
		
		# Decide whether to filter by type or not (50% chance)
		if randf() > 0.5:
			# Select random item type
			var type = item_types[randi() % item_types.size()]
			item = get_random_item(type, 100)  # Get any level item
		else:
			# Get any random item
			item = get_random_item("", 100)  # Get any level item
		
		if item:
			loot.append(item)
	
	# Always ensure at least one potion drops (for healing during testing)
	var potion_dropped = false
	for item in loot:
		if item.type == "Potion":
			potion_dropped = true
			break
	
	if not potion_dropped:
		var potion = get_random_item("Potion", 100)
		if potion:
			loot.append(potion)
	
	return loot
