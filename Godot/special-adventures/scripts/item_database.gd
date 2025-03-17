class_name ItemDatabase
extends RefCounted

var _items = {}  # Dictionary to store all items by ID
var _items_by_type = {}  # Dictionary to store items organized by type
var _items_by_level = {}  # Dictionary to store items organized by level requirement
var _items_by_slot = {}  # Dictionary to store items organized by equipment slot
var _items_by_rarity = {}  # Dictionary to store items organized by rarity

func _init():
	load_database()

# Load the database from JSON file
func load_database():
	var file = FileAccess.open("res://data/items.json", FileAccess.READ)
	if not file:
		print("Failed to open items database file")
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		print("JSON Parse Error: ", json.get_error_message(), " at line ", json.get_error_line())
		return
	
	var item_data = json.data
	if typeof(item_data) != TYPE_ARRAY:
		print("Unexpected data format in items.json")
		return
	
	# Initialize the category dictionaries
	_items_by_type = {}
	_items_by_level = {}
	_items_by_slot = {}
	_items_by_rarity = {}  # Initialize rarity dictionary
	
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
		
		# Store by ID
		_items[id] = item
		
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
	
	print("Loaded ", _items.size(), " items into database")

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
	var filtered_items = []
	
	# Filter by type and level
	for item in _items.values():
		if (type == "" or item.type == type) and item.level_requirement <= max_level:
			filtered_items.append(item)
	
	if filtered_items.size() > 0:
		return filtered_items[randi() % filtered_items.size()]
	
	return null

# Generate loot for an enemy based on level
func generate_enemy_loot(enemy_level: int, min_items: int = 1, max_items: int = 3) -> Array:
	var loot = []
	var num_items = min_items + randi() % (max_items - min_items + 1)
	
	for i in range(num_items):
		# Higher chance for common items, lower for rare/epic
		var item_type = ""
		var rand = randf()
		
		if rand < 0.6:  # 60% chance for weapon/armor
			item_type = ["Weapon", "Armor"][randi() % 2]
		else:  # 40% chance for other item types
			item_type = ["Potion", "Ring", "Trinket"][randi() % 3]
		
		var item = get_random_item(item_type, enemy_level + 5)
		if item != null:
			loot.append(item)
	
	return loot
