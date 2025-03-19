class_name CombatManager
extends RefCounted

# Reference to GameEnums class
const GameEnumsRef = preload("res://scripts/game_enums.gd")

var game
var player
var current_enemy
var combat_effects
var hud

signal combat_ended(victory)
signal xp_gained(amount, leveled_up)

func _init(p_game):
	game = p_game
	player = game.player
	combat_effects = game.combat_effects
	hud = game.hud

func start_battle(enemy = null):
	if enemy:
		current_enemy = enemy
	else:
		# Create default enemy if none provided
		current_enemy = Enemy.new()
	
	game.add_to_game_log("A wild " + current_enemy.name + " appears!")
	
	var enemies = [current_enemy]
	hud.update_enemy_hp(enemies)
	
	# Show the combat UI
	game.show_combat_ui(true)
	
	# Update the action bar with available actions
	update_available_actions()

func update_available_actions():
	var actions = []
	
	# Basic weapon actions
	if player.equipped_items["Weapon"] != null:
		var weapon = player.equipped_items["Weapon"]
		
		# Determine weapon type and add appropriate action
		if weapon.type in ["Sword", "Dagger", "Axe", "Hammer", "Mace"]:
			actions.append({
				"name": "Strike",
				"type": "MELEE",
				"category": hud.ActionCategory.COMBAT,
				"shortcut": "1",
				"tooltip": "Attack with your melee weapon"
			})
		elif weapon.type in ["Bow", "Crossbow", "Gun"]:
			actions.append({
				"name": "Shoot", 
				"type": "RANGED",
				"category": hud.ActionCategory.COMBAT,
				"shortcut": "1",
				"tooltip": "Attack with your ranged weapon"
			})
		elif weapon.type in ["Staff", "Wand"]:
			actions.append({
				"name": "Cast", 
				"type": "MAGIC",
				"category": hud.ActionCategory.MAGIC,
				"shortcut": "1",
				"tooltip": "Cast a spell with your magical implement"
			})
	else:
		# No weapon equipped
		actions.append({
			"name": "Punch", 
			"type": "MELEE",
			"category": hud.ActionCategory.COMBAT,
			"shortcut": "1",
			"tooltip": "Attack with your bare hands"
		})
	
	# Add learned abilities from player's ability list
	if "abilities" in player and player.abilities:
		for ability_id in player.abilities:
			var ability = player.abilities[ability_id]
			# Only add abilities that aren't on cooldown
			if not game.ability_cooldowns.has(ability_id):
				actions.append({
					"name": ability.name,
					"type": ability.type,
					"category": ability.category,
					"shortcut": ability.shortcut if "shortcut" in ability else "",
					"tooltip": ability.description,
					"ability_id": ability_id
				})
	
	# Update the action bar
	hud.update_action_bar(actions)

func process_combat_action(action_data):
	var action_name = action_data.name
	var action_type_str = action_data.type
	var attack_type = GameEnums.AttackType.MELEE  # Using the autoload singleton
	
	# Convert string to enum
	match action_type_str:
		"MELEE":
			attack_type = GameEnums.AttackType.MELEE  # Using the autoload singleton
		"RANGED":
			attack_type = GameEnums.AttackType.RANGED  # Using the autoload singleton
		"MAGIC":
			attack_type = GameEnums.AttackType.MAGIC  # Using the autoload singleton
	
	# Display action text
	game.add_to_game_log("You use " + action_name + "!")
	
	# Execute the attack
	var attack_result = player.attack_enemy(current_enemy, attack_type)
	var damage = attack_result["damage"]
	
	if current_enemy.is_alive():
		var enemy_damage = current_enemy.attack_enemy(player)
		
		# Add player attack text
		if attack_result["critical"]:
			game.add_to_game_log("[color=#ffff00]Critical hit! [/color]")  # Yellow for crits
			# Add critical hit effects
			combat_effects.screen_shake(1.5)
			combat_effects.flash_screen(Color(1, 1, 0, 0.2))
		game.add_to_game_log("Your " + action_name.to_lower() + " hits " + current_enemy.name + 
			" for [color=#ff5555]" + str(damage) + "[/color] damage!")
		
		# Show blood particles for enemy hit
		var enemy_position = Vector2(1280, 400)  # Use approximate position
		combat_effects.show_blood(enemy_position, damage / 10.0)
		
		# Add enemy attack text
		game.add_to_game_log(current_enemy.name + " hits you for [color=#ff5555]" + 
			str(enemy_damage) + "[/color] damage!")
		
		# Show player damage effects if significant damage
		if enemy_damage > player.max_health / 10:
			combat_effects.screen_shake(0.8)
			combat_effects.flash_screen(Color(1, 0, 0, 0.15))
		
		hud.update_player_stats(player.health, player.max_health, player.mana, 
			player.max_mana, player.xp, player.max_xp)
		hud.update_enemy_hp([current_enemy])
	else:
		handle_enemy_defeat()

func handle_enemy_defeat():
	game.add_to_game_log("You defeated the " + current_enemy.name + "!")
	
	# Give XP and possibly loot
	var earned_xp = 10  # Changed variable name to avoid shadowing the signal
	var leveled_up = player.gain_xp(earned_xp)
	game.add_to_game_log("\nYou gained [color=#ffff55]" + str(earned_xp) + " XP[/color]!")
	
	# Emit the xp_gained signal
	xp_gained.emit(earned_xp, leveled_up)
	
	if leveled_up:
		game.add_to_game_log("\n[color=#ffff00]Level up! You are now level " + str(player.level) + "![/color]")
		game.add_to_game_log("\n[color=#00ffff]You gained a talent point![/color]")
		game.add_to_game_log("\n[color=#00ffff]You gained 3 stat points![/color]")
		
		# Call the game's level up handler
		game.handle_player_level_up()
	
	# Generate loot
	var enemy_level = 1  # This would come from the enemy's actual level
	var loot = game.item_db.generate_enemy_loot(enemy_level)
	
	if loot.size() > 0:
		game.add_to_game_log("\nThe enemy dropped:")
		for item in loot:
			game.add_to_game_log("\n- " + item.name)
			player.inventory.append(item)
	
	# Update the HUD with current values
	hud.update_player_stats(player.health, player.max_health, player.mana, 
		player.max_mana, player.xp, player.max_xp)
	hud.update_inventory(player.inventory)
	
	emit_signal("combat_ended", true)

func end_battle(victory: bool):
	# Hide the combat UI
	game.show_combat_ui(false)
	
	# Clear enemy display
	hud.update_enemy_hp([])
	
	# Emit combat ended signal
	combat_ended.emit(victory)
	
	current_enemy = null
