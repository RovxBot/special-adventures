extends Control

var player
var enemy
var item_db  # Reference to the item database
var character_creation_scene

@onready var hud = $Hud  # Get the HUD instance
# Update paths to match new HUD structure
@onready var game_label = $Hud/MainLayout/TopSection/MainTextPanel/MarginContainer/VBoxContainer/TextZone
@onready var submit_button = $Hud/MainLayout/ActionButtonsContainer/SubmitButton
@onready var game_text_input = $Hud/MainLayout/InputPanel/MarginContainer/HBoxContainer/GameTextInput
@onready var input_panel = $Hud/MainLayout/InputPanel
@onready var item_dialog = $Hud/ItemDialog

# Store ability cooldowns
var ability_cooldowns = {}

func _ready():
	# Initialize the item database
	item_db = ItemDatabase.new()
	
	# Connect signals for item interaction
	hud.inventory_item_selected.connect(_on_inventory_item_selected)
	hud.equipped_item_selected.connect(_on_equipped_item_selected)
	
	# Connect talent button
	var talent_button = hud.get_node_or_null("MainLayout/BottomSection/PlayerStatsSection/PlayerStatusPanel/MarginContainer/PlayerStats/TalentButton")
	if talent_button:
		talent_button.pressed.connect(func(): _on_talent_button_pressed())
	
	# Connect item dialog button signals - update paths
	var dialog_container = item_dialog.get_node_or_null("Panel/MarginContainer/VBoxContainer")
	if dialog_container:
		var buttons_container = dialog_container.get_node_or_null("ButtonsContainer")
		if buttons_container:
			var equip_btn = buttons_container.get_node_or_null("EquipButton")
			var unequip_btn = buttons_container.get_node_or_null("UnequipButton")
			var use_btn = buttons_container.get_node_or_null("UseButton")
			var destroy_btn = buttons_container.get_node_or_null("DestroyButton")
			var cancel_btn = dialog_container.get_node_or_null("CancelButton")
			
			if equip_btn:
				equip_btn.pressed.connect(_on_equip_button_pressed)
			if unequip_btn:
				unequip_btn.pressed.connect(_on_unequip_button_pressed)
			if use_btn:
				use_btn.pressed.connect(_on_use_button_pressed)
			if destroy_btn:
				destroy_btn.pressed.connect(_on_destroy_button_pressed)
			if cancel_btn:
				cancel_btn.pressed.connect(_on_cancel_button_pressed)
	
	# Connect stats button
	var stats_button = hud.get_node_or_null("MainLayout/BottomSection/PlayerStatsSection/PlayerStatusPanel/MarginContainer/PlayerStats/StatsButton")
	if stats_button:
		stats_button.pressed.connect(func(): _on_stats_button_pressed())
	
	# Connect action button signal
	hud.action_button_pressed.connect(_on_action_button_pressed)
	
	# Start with character creation
	start_character_creation()
	
	# Hide HUD initially
	hud.visible = false

func start_character_creation():
	# Load and instantiate the character creation scene
	character_creation_scene = load("res://scenes/CharacterCreation.tscn").instantiate()
	add_child(character_creation_scene)
	
	# Connect signals
	character_creation_scene.character_created.connect(_on_character_created)
	character_creation_scene.creation_cancelled.connect(_on_creation_cancelled)

func _on_character_created(character_data):
	# Clean up character creation scene
	if character_creation_scene:
		character_creation_scene.queue_free()
		character_creation_scene = null
	
	# Create player with the provided data
	player = Player.new(character_data.name)
	
	# Set custom stats from character creation
	player.strength = character_data.strength
	player.agility = character_data.agility
	player.stamina = character_data.stamina
	player.intelligence = character_data.intelligence
	player.race = character_data.race  # Store race information
	
	# Recalculate stats after customization
	player.recalculate_stats()
	
	# Create enemy
	enemy = Enemy.new()
	
	# Set player name in the UI
	var player_name_label = hud.get_node_or_null("MainLayout/BottomSection/PlayerStatsSection/PlayerStatusPanel/MarginContainer/PlayerStats/Player")
	if player_name_label:
		player_name_label.text = player.name
		
		# Add race in parentheses
		if player.race:
			player_name_label.text += " (" + player.race + ")"
	
	# Update stats display
	var stats = {
		"STR": player.strength,
		"STAM": player.stamina,
		"INT": player.intelligence,
		"AGI": player.agility,
		 "armor": player.armor,
		"resistance": player.resistance
	}
	hud.update_stats(stats)
	
	# Update HUD with initial player stats and equipment
	hud.update_player_stats(player.health, player.max_health, player.mana, player.max_mana, player.xp, player.max_xp)
	hud.update_inventory(player.inventory)
	hud.update_equipped_from_player(player)
	hud.update_talent_points(player.talent_points)
	hud.update_stat_points(player.stat_points)
	
	# Show HUD
	hud.visible = true
	
	# Start the game with a battle
	start_battle()

func _on_creation_cancelled():
	# Handle creation cancelled (return to main menu or exit)
	# For now, we'll just restart character creation
	if character_creation_scene:
		character_creation_scene.queue_free()
		character_creation_scene = null
	
	# Restart character creation
	call_deferred("start_character_creation")

func _on_SubmitButton_pressed():
	var player_name = game_text_input.text.strip_edges()  # Get input text
	if player_name == "":
		game_label.text = "Please enter a valid name!"  # Prevent empty names
		return
	
	player = Player.new(player_name)
	enemy = Enemy.new()
	
	# Set player name and hide input panel
	if player_name != "":
		# Make sure player name is set in the UI
		var player_name_label = hud.get_node_or_null("MainLayout/BottomSection/PlayerStatsSection/PlayerStatusPanel/MarginContainer/PlayerStats/Player")
		if player_name_label:
			player_name_label.text = player_name
	
	var stats = {
		"STR": player.strength,
		"STAM": player.stamina,
		"INT": player.intelligence,
		"AGI": player.agility,
		"ARMOR": player.armor
	}
	hud.update_stats(stats)
	
	# Hide input field
	if input_panel:
		input_panel.visible = false
		input_panel.custom_minimum_size = Vector2(0, 0)  # Remove height when not visible
	game_text_input.hide()
	submit_button.hide()
	
	# Update HUD with initial player stats and equipment
	hud.update_player_stats(player.health, player.max_health, player.mana, player.max_mana, player.xp, player.max_xp)
	hud.update_inventory(player.inventory)
	hud.update_equipped_from_player(player)
	
	start_battle()

func start_battle():
	game_label.text = "A wild " + enemy.name + " appears!"
	
	var enemies = [enemy]  # Replace this with actual enemy array if multiple
	hud.update_enemy_hp(enemies)
	
	# Update the action bar with available actions
	update_available_actions()
	
	if input_panel:
		input_panel.visible = false
		input_panel.custom_minimum_size = Vector2(0, 0)

# Determine available actions based on player equipment and learned abilities
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
			if not ability_id in ability_cooldowns:
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

# Handle ability with cooldown
func use_ability_with_cooldown(ability_id, cooldown_time):
	# Put ability on cooldown
	ability_cooldowns[ability_id] = cooldown_time
	
	# Start a timer to remove the cooldown
	var timer = get_tree().create_timer(cooldown_time)
	timer.timeout.connect(func(): ability_cooldowns.erase(ability_id))
	
	# Update action bar to show cooldown
	if "abilities" in player and ability_id in player.abilities:
		var ability = player.abilities[ability_id]
		hud.show_action_cooldown(ability.name, cooldown_time)
	
	# Update available actions to exclude this ability
	update_available_actions()

# Handle action button press
func _on_action_button_pressed(action_data):
	var action_name = action_data.name
	var action_type_str = action_data.type
	var attack_type = Player.AttackType.MELEE  # Default
	
	# Convert string to enum
	match action_type_str:
		"MELEE":
			attack_type = Player.AttackType.MELEE
		"RANGED":
			attack_type = Player.AttackType.RANGED
		"MAGIC":
			attack_type = Player.AttackType.MAGIC
	
	# Display action text
	game_label.text = "You use " + action_name + "!"
	
	# Execute the attack
	var attack_result = player.attack_enemy(enemy, attack_type)
	var damage = attack_result["damage"]
	
	if enemy.is_alive():
		var enemy_damage = enemy.attack_enemy(player)
		
		# Clear previous text and append combat results
		game_label.text = ""
		
		# Add player attack text
		if attack_result["critical"]:
			game_label.append_text("[color=#ffff00]Critical hit! [/color]")  # Yellow for crits
		game_label.append_text("Your " + action_name.to_lower() + " hits " + enemy.name + " for [color=#ff5555]" + str(damage) + "[/color] damage!\n")
		
		# Add enemy attack text
		game_label.append_text(enemy.name + " hits you for [color=#ff5555]" + str(enemy_damage) + "[/color] damage!")
		
		hud.update_player_stats(player.health, player.max_health, player.mana, player.max_mana, player.xp, player.max_xp)
		hud.update_enemy_hp([enemy])
	else:
		handle_enemy_defeat()

# Add this function to give player a new item from database
func give_player_item(item_id: String):
	if player and item_db:
		var item = item_db.get_item(item_id)
		if item:
			player.inventory.append(item)
			game_label.text = "You received: " + item.name
			hud.update_inventory(player.inventory)
			return true
	return false

# Example function for enemy drops
func handle_enemy_defeat():
	game_label.text = "You defeated the " + enemy.name + "!"
	
	# Give XP and possibly loot
	var xp_gained = 10
	var leveled_up = player.gain_xp(xp_gained)
	game_label.append_text("\nYou gained [color=#ffff55]" + str(xp_gained) + " XP[/color]!")
	
	if leveled_up:
		game_label.append_text("\n[color=#ffff00]Level up! You are now level " + str(player.level) + "![/color]")
		game_label.append_text("\n[color=#00ffff]You gained a talent point![/color]")
		game_label.append_text("\n[color=#00ffff]You gained 3 stat points![/color]")
		hud.update_talent_points(player.talent_points)
		hud.update_stat_points(player.stat_points)
	
	# Generate loot
	var enemy_level = 1  # This would come from the enemy's actual level
	var loot = item_db.generate_enemy_loot(enemy_level)
	
	if loot.size() > 0:
		game_label.text += "\nThe enemy dropped:"
		for item in loot:
			game_label.text += "\n- " + item.name
			player.inventory.append(item)
	
	# Update the HUD with current values (don't reset health/mana)
	hud.update_player_stats(player.health, player.max_health, player.mana, player.max_mana, player.xp, player.max_xp)
	hud.update_inventory(player.inventory)
	
	# Change submit button to "Continue" to start a new battle
	submit_button.text = "Continue"
	submit_button.show()
	
	# Remove attack connection and connect to start_next_battle
	if submit_button.pressed.is_connected(_on_attack_pressed):
		submit_button.pressed.disconnect(_on_attack_pressed)
	submit_button.pressed.connect(_on_continue_pressed)

# Add new function to handle continuing to next battle
func _on_continue_pressed():
	# Create a new enemy but keep the same player
	enemy = Enemy.new()
	
	# Disconnect continue button and prepare for next battle
	if submit_button.pressed.is_connected(_on_continue_pressed):
		submit_button.pressed.disconnect(_on_continue_pressed)
	
	# Start a new battle with the same player (preserving health/mana)
	start_battle()

# Add a test function that you can call to verify progress bars
func test_progress_bars():
	if player:
		# Set some test values
		player.health = 75
		player.mana = 25
		player.xp = 50
		
		# Update the HUD
		hud.update_player_stats(player.health, player.max_health, player.mana, player.max_mana, player.xp, player.max_xp)
		
		# Also update the console
		print("Test values applied: HP=75, Mana=25, XP=50")

# Debug function to help diagnose equipping issues
func print_item_debug_info(item):
	print("Item Debug Info:")
	print("- Name: ", item.name)
	print("- Type: ", item.type)
	print("- Slot: ", item.slot)
	print("- Level Req: ", item.level_requirement)
	print("- Stats: ", item.stats)
	print("- Player level: ", player.level)

# Item interaction handlers
func _on_inventory_item_selected(index):
	if player and index >= 0 and index < player.inventory.size():
		var item = player.inventory[index]
		var can_equip = item.slot != ""  # Can only equip items with valid slots
		
		# Show the item dialog with item data
		var item_data = {
			"type": item.type,
			"description": item.description,
			"rarity": item.rarity,  # Pass rarity to the dialog
			"value": 10,  # Example value, you can add this to your Item class
			"effects": []  # Build effects list from item stats
		}
		
		# Fill effects array with stat bonuses
		for stat_name in item.stats:
			item_data.effects.append(stat_name + ": +" + str(item.stats[stat_name]))
		
		hud.show_item_dialog(false, item.name, can_equip, item_data)

func _on_equipped_item_selected(slot):
	if player and player.equipped_items.has(slot) and player.equipped_items[slot] != null:
		var item = player.equipped_items[slot]
		
		# Show the item dialog with item data
		var item_data = {
			"type": item.type,
			"description": item.description,
			"rarity": item.rarity,  # Pass rarity to dialog
			"value": 10,  # Example value
			"effects": []
		}
		
		# Fill effects array with stat bonuses
		for stat_name in item.stats:
			item_data.effects.append(stat_name + ": +" + str(item.stats[stat_name]))
		
		hud.show_item_dialog(true, item.name, true, item_data)

# Handle equip button
func _on_equip_button_pressed():
	var index = hud.selected_inventory_index
	if player and index >= 0 and index < player.inventory.size():
		var item = player.inventory[index]
		
		# Debug output
		print_item_debug_info(item)
		
		if item.slot != "":  # Make sure it's an equippable item
			if player.equip_item(item):
				game_label.text = "Equipped: " + item.name
				
				# Update the HUD
				hud.update_inventory(player.inventory)
				hud.update_equipped_from_player(player)
				
				# Update player stats display
				var stats = {
					"STR": player.strength,
					"STAM": player.stamina,
					"INT": player.intelligence,
					"AGI": player.agility,
					 "armor": player.armor,
					"resistance": player.resistance
				}
				hud.update_stats(stats)
				
				# Reset selection
				hud.selected_inventory_index = -1
			else:
				game_label.text = "Cannot equip: " + item.name + " (Level requirement: " + str(item.level_requirement) + ")"
		else:
			game_label.text = "This item cannot be equipped."
	
	item_dialog.hide()

# Handle unequip button
func _on_unequip_button_pressed():
	var slot = hud.selected_equipped_slot
	if player and slot != "":
		var item = player.unequip_item(slot)
		if item:
			game_label.text = "Unequipped: " + item.name
			
			# Update the HUD
			hud.update_inventory(player.inventory)
			hud.update_equipped_from_player(player)
			
			# Update player stats display
			var stats = {
				"STR": player.strength,
				"STAM": player.stamina,
				"INT": player.intelligence,
				"AGI": player.agility,
				 "armor": player.armor,
				"resistance": player.resistance
			}
			hud.update_stats(stats)
			
			# Reset selection
			hud.selected_equipped_slot = ""
	
	item_dialog.hide()

# Handle destroy button
func _on_destroy_button_pressed():
	if hud.selected_inventory_index >= 0:
		# Destroy from inventory
		var index = hud.selected_inventory_index
		if player and index >= 0 and index < player.inventory.size():
			var item = player.inventory[index]
			player.inventory.remove_at(index)
			game_label.text = "Destroyed: " + item.name
			
			# Update the HUD
			hud.update_inventory(player.inventory)
			
			# Reset selection
			hud.selected_inventory_index = -1
	
	elif hud.selected_equipped_slot != "":
		# Destroy equipped item
		var slot = hud.selected_equipped_slot
		if player and player.equipped_items.has(slot) and player.equipped_items[slot] != null:
			var item = player.equipped_items[slot]
			player.equipped_items[slot] = null
			
			game_label.text = "Destroyed: " + item.name
			
			# Update the HUD
			hud.update_equipped_from_player(player)
			
			# Update player stats display
			var stats = {
				"STR": player.strength,
				"STAM": player.stamina,
				"INT": player.intelligence,
				"AGI": player.agility,
				 "armor": player.armor,
				"resistance": player.resistance
			}
			hud.update_stats(stats)
			
			# Reset selection
			hud.selected_equipped_slot = ""
	
	item_dialog.hide()

# Add this function to handle using items (like potions)
func _on_use_button_pressed():
	var index = hud.selected_inventory_index
	if player and index >= 0 and index < player.inventory.size():
		var item = player.inventory[index]
		
		# Check for both Consumable and Potion types
		if item.type == "Consumable" or item.type == "Potion":
			var used = false
			
			# Handle healing potions - check for both "heal" and "health_restore" properties
			if "heal" in item.stats:
				var heal_amount = item.stats["heal"]
				player.health = min(player.health + heal_amount, player.max_health)
				game_label.text = "Used " + item.name + " and restored [color=#55ff55]" + str(heal_amount) + " health[/color]!"
				used = true
			elif "health_restore" in item.stats:
				var heal_amount = item.stats["health_restore"]
				player.health = min(player.health + heal_amount, player.max_health)
				game_label.text = "Used " + item.name + " and restored [color=#55ff55]" + str(heal_amount) + " health[/color]!"
				used = true
			
			# Handle mana potions - check for mana property
			if "mana" in item.stats:
				var mana_amount = item.stats["mana"]
				player.mana = min(player.mana + mana_amount, player.max_mana)
				game_label.text = "Used " + item.name + " and restored [color=#5555ff]" + str(mana_amount) + " mana[/color]!"
				used = true
			
			if used:
				# Remove the item after use
				player.inventory.remove_at(index)
				
				# Update the HUD
				hud.update_inventory(player.inventory)
				hud.update_player_stats(player.health, player.max_health, player.mana, player.max_mana, player.xp, player.max_xp)
				
				# Reset selection
				hud.selected_inventory_index = -1
	
	item_dialog.hide()

# Handle cancel button
func _on_cancel_button_pressed():
	item_dialog.hide()
	
	# Reset selections
	hud.selected_inventory_index = -1
	hud.selected_equipped_slot = ""

# Update stats display in the new location
func update_player_stats_display():
	if player:
		var stats_grid = hud.get_node_or_null("MainLayout/BottomSection/PlayerStatsSection/PlayerStatusPanel/MarginContainer/PlayerStats/StatsGridContainer")
		if stats_grid:
			stats_grid.get_node_or_null("STRValue").text = str(player.strength)
			stats_grid.get_node_or_null("STAMValue").text = str(player.stamina)
			stats_grid.get_node_or_null("INTValue").text = str(player.intelligence)
			stats_grid.get_node_or_null("AGIValue").text = str(player.agility)
			stats_grid.get_node_or_null("DEFValue").text = str(player.armor)
			stats_grid.get_node_or_null("RESValue").text = str(player.resistance)

func _on_talent_button_pressed():
	if player:
		hud.open_talent_window(player)

func _on_stats_button_pressed():
	if player:
		hud.open_stats_window(player)

# Use rich text tags for colored text in game label
func update_game_text(text, text_type = "normal"):
	var colored_text = ""
	
	match text_type:
		"damage":
			colored_text = "[color=#ff5555]" + text + "[/color]"  # Red for damage
		"healing":
			colored_text = "[color=#55ff55]" + text + "[/color]"  # Green for healing
		"mana":
			colored_text = "[color=#5555ff]" + text + "[/color]"  # Blue for mana
		"xp":
			colored_text = "[color=#ffff55]" + text + "[/color]"  # Yellow for XP
		"item":
			colored_text = "[color=#ff55ff]" + text + "[/color]"  # Purple for items
		_:
			colored_text = text
	
	game_label.text = colored_text

# Process keyboard shortcuts for abilities
func _input(event):
	if not player or not player.is_alive():
		return
		
	if event is InputEventKey and event.pressed:
		var key_pressed = OS.get_keycode_string(event.keycode)
		
		# Number keys 1-9 for ability shortcuts
		if key_pressed in ["1", "2", "3", "4", "5", "6", "7", "8", "9"]:
			var action_bar = hud.get_node_or_null("MainLayout/ActionButtonsContainer/ActionBarScroll/ActionBar")
			if action_bar:
				# Find button with this shortcut and trigger it
				for button in action_bar.get_children():
					var shortcut_label = button.get_node_or_null("Label")
					if shortcut_label and shortcut_label.text == key_pressed:
						button.emit_signal("pressed")
						return
