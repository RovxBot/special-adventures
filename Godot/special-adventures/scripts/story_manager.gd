class_name StoryManager
extends RefCounted

signal story_updated(text, clear_text)
signal choices_available(choices)
signal story_event_triggered(event_id)

var current_node_id: String = "start"
var story_data: Dictionary = {}
var player_history: Array = []
var game_node = null
var player = null

# Dictionary to keep track of story flags/variables
var story_flags: Dictionary = {}

func _init(p_game_node):
	game_node = p_game_node
	player = game_node.player if game_node.has_method("get_player") or game_node.player != null else null

func load_story_file(file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		print("Story file doesn't exist: ", file_path)
		return false
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("Failed to open story file: ", file_path)
		return false
		
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		print("JSON Parse Error: ", json.get_error_message())
		return false
	
	story_data = json.data
	if not story_data.has("nodes"):
		print("Invalid story format: missing 'nodes' key")
		return false
	
	# Reset to starting point when loading a new story
	current_node_id = story_data.get("start_node", "start")
	player_history.clear()
	
	print("Story loaded successfully with ", story_data.nodes.size(), " nodes")
	return true

func start_story():
	# Present the first node of the story
	process_node(current_node_id)

func process_node(node_id: String):
	if not story_data.has("nodes") or not story_data.nodes.has(node_id):
		print("Story node not found: ", node_id)
		return
	
	var node = story_data.nodes[node_id]
	current_node_id = node_id
	player_history.append(node_id)
	
	# Process the story text
	var text = node.get("text", "")
	
	# Process any conditions in the text
	text = process_text_conditions(text)
	
	# Emit signal with the processed text - TRUE means clear the text area
	story_updated.emit(text, true)
	
	# Process any actions for this node
	if node.has("actions"):
		process_actions(node.actions)
	
	# Process choices if present, otherwise move to the next node if specified
	if node.has("choices") and node.choices.size() > 0:
		# Filter choices based on conditions
		var available_choices = filter_choices_by_conditions(node.choices)
		choices_available.emit(available_choices)
	elif node.has("next"):
		# Automatic transition to next node
		process_node(node.next)

func select_choice(choice_index: int):
	if not story_data.has("nodes") or not story_data.nodes.has(current_node_id):
		return
	
	var node = story_data.nodes[current_node_id]
	if not node.has("choices") or choice_index >= node.choices.size():
		return
	
	var choice = node.choices[choice_index]
	
	# Process any actions associated with this choice
	if choice.has("actions"):
		process_actions(choice.actions)
	
	# Move to the next node specified by this choice
	if choice.has("next"):
		process_node(choice.next)

func process_actions(actions: Array):
	for action in actions:
		match action.type:
			"set_flag":
				set_story_flag(action.flag, action.value)
			"modify_stat":
				modify_player_stat(action.stat, action.amount)
			"add_item":
				add_item_to_player(action.item_id, action.get("quantity", 1))
			"remove_item":
				remove_item_from_player(action.item_id, action.get("quantity", 1))
			"trigger_combat":
				trigger_combat_event(action.enemy_id)
			"trigger_event":
				story_event_triggered.emit(action.event_id)

func set_story_flag(flag: String, value):
	story_flags[flag] = value
	print("Story flag set: ", flag, " = ", value)

func modify_player_stat(stat: String, amount: int):
	if player == null:
		print("Cannot modify player stat: player is null")
		return
	
	if stat in player:
		player[stat] += amount
		print("Modified player stat: ", stat, " by ", amount)
		
		# Make sure derived stats are updated
		if player.has_method("recalculate_stats"):
			player.recalculate_stats()
			
		# Update UI if needed
		if game_node and game_node.has_method("update_player_stats_display"):
			game_node.update_player_stats_display()

func add_item_to_player(item_id: String, quantity: int = 1):
	# Check if we can access the game node and player
	if game_node == null or player == null:
		print("Cannot add item: game_node or player is null")
		return
	
	# Use the game's give_player_item function if available
	if game_node.has_method("give_player_item"):
		var success = game_node.give_player_item(item_id)
		if success:
			# Notify the player about the item acquisition
			var item_name = game_node.item_db.get_item(item_id).name if game_node.item_db else item_id
			story_updated.emit("You received: [color=#ff55ff]" + item_name + "[/color]", false)
	else:
		# Fallback implementation if game_node doesn't have the method
		print("Warning: game_node doesn't have give_player_item method. Trying direct inventory modification.")
		if game_node.item_db:
			var item = game_node.item_db.get_item(item_id)
			if item != null and player.has("inventory"):
				player.inventory.append(item)
				# Update the HUD if possible
				if game_node.hud and game_node.hud.has_method("update_inventory"):
					game_node.hud.update_inventory(player.inventory)
				
				# Notify the player about the item acquisition
				story_updated.emit("You received: [color=#ff55ff]" + item.name + "[/color]", false)
			else:
				print("Failed to add item: item not found in database or player has no inventory")
		else:
			print("Failed to add item: no item database found")

func remove_item_from_player(item_id: String, quantity: int = 1):
	# Logic to remove an item from player inventory
	pass

func trigger_combat_event(enemy_id: String):
	# Logic to start a combat with a specified enemy
	if game_node and game_node.has_method("start_combat_with_enemy"):
		game_node.start_combat_with_enemy(enemy_id)

func process_text_conditions(text: String) -> String:
	# Process any conditional text like {if flag="value"}Show this{endif}
	# This is a simplified example and could be expanded
	
	# For now, we'll just return the text as is
	return text

func filter_choices_by_conditions(choices: Array) -> Array:
	var available_choices = []
	
	for choice in choices:
		var condition_met = true
		
		# Check conditions if present
		if choice.has("conditions"):
			for condition in choice.conditions:
				# Check various condition types (flag, stat, item, etc.)
				match condition.type:
					"flag":
						if not story_flags.has(condition.flag) or story_flags[condition.flag] != condition.value:
							condition_met = false
							break
					"stat":
						if player == null or not player.has(condition.stat) or player[condition.stat] < condition.min_value:
							condition_met = false
							break
					"item":
						# Would need to check player inventory
						pass
		
		if condition_met:
			available_choices.append({
				"text": choice.text,
				"index": available_choices.size()
			})
	
	return available_choices

func get_story_flag(flag: String, default_value = null):
	return story_flags.get(flag, default_value)
