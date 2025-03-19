class_name AbilityManager
extends RefCounted

# Load the script to access the enum
const GameEnumsScript = preload("res://scripts/game_enums.gd")

var game
var player
var hud
var ability_cooldowns = {}

# Available abilities loaded from JSON
var available_abilities = {}

func _init(p_game):
	game = p_game
	player = game.player
	hud = game.hud
	
	# Load abilities from JSON file
	load_abilities()

# Load abilities from JSON file
func load_abilities():
	var json_file = FileAccess.open("res://resources/abilities/abilities.json", FileAccess.READ)
	if json_file:
		var json_text = json_file.get_as_text()
		json_file.close()
		
		var json = JSON.new()
		var error = json.parse(json_text)
		
		if error == OK:
			available_abilities = json.get_data()
		else:
			push_error("Failed to parse abilities JSON: " + json.get_error_message() + " at line " + str(json.get_error_line()))
	else:
		push_error("Failed to open abilities JSON file")

# This function has been modified to do nothing since abilities are now only unlocked through talents
func check_ability_unlocks():
	# No longer automatically unlock abilities based on level
	pass

# Add an ability to the player's known abilities
func teach_ability_to_player(ability_id: String):
	if ability_id in available_abilities and player:
		player.learn_ability(ability_id, available_abilities[ability_id].duplicate())
		
		# Notify the player
		game.add_to_game_log("You learned a new ability: [color=#00FFFF]" + 
			available_abilities[ability_id].name + "[/color]!")
		
		# Update the action bar
		game.combat_manager.update_available_actions()
		
		return true
	return false

# Get ability from talent ID
func get_ability_for_talent(talent_id: String) -> String:
	for ability_id in available_abilities:
		if "talent_required" in available_abilities[ability_id] and available_abilities[ability_id].talent_required == talent_id:
			return ability_id
	return ""

# Check if a talent unlocks an ability
func does_talent_unlock_ability(talent_id: String) -> bool:
	return get_ability_for_talent(talent_id) != ""

# Get ability ID by name
func get_ability_id_by_name(ability_name):
	for ability_id in available_abilities:
		if available_abilities[ability_id].name == ability_name:
			return ability_id
	return ""

func use_ability_with_cooldown(ability_id, cooldown_time):
	# Put ability on cooldown
	ability_cooldowns[ability_id] = cooldown_time
	
	# Start a timer to remove the cooldown
	var timer = game.get_tree().create_timer(cooldown_time)
	timer.timeout.connect(func(): ability_cooldowns.erase(ability_id))
	
	# Update action bar to show cooldown
	if "abilities" in player and ability_id in player.abilities:
		var ability = player.abilities[ability_id]
		hud.show_action_cooldown(ability.name, cooldown_time)
	
	# Update available actions to exclude this ability
	game.combat_manager.update_available_actions()

func process_ability_action(action_data):
	# Handle abilities with special effects
	if "ability_id" in action_data:
		var ability_id = action_data.ability_id
		var ability = player.abilities[ability_id]
		
		# Use ability and apply cooldown
		var result = player.use_ability(ability_id, game.current_enemy)
		
		if result.success:
			game.add_to_game_log(result.message)
			
			# Apply cooldown if specified
			if "cooldown" in ability:
				use_ability_with_cooldown(ability_id, ability.cooldown)
			
			# Process damage or other effects
			if "damage" in result:
				if result.type == GameEnums.AttackType.MAGIC:  # Using the autoload singleton
					game.current_enemy.take_magical_damage(result.damage)
				else:
					game.current_enemy.take_damage(result.damage)

				game.add_to_game_log("The ability deals [color=#ff5555]" + 
					str(result.damage) + "[/color] damage!")

				# Update enemy health display
				hud.update_enemy_hp([game.current_enemy])

				# Check if enemy died
				if not game.current_enemy.is_alive():
					game.combat_manager.handle_enemy_defeat()

			# Update player stats after ability use
			hud.update_player_stats(player.health, player.max_health, 
				player.mana, player.max_mana, player.xp, player.max_xp)

			return true
		else:
			game.add_to_game_log("[color=#ff5555]" + result.message + "[/color]")

	return false
