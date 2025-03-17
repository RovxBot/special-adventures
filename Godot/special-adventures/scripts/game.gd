extends Control

var player
var enemy
var item_db  # Reference to the item database

@onready var hud = $Hud  # Get the HUD instance
# Update paths to match new HUD structure
@onready var game_label = $Hud/MainLayout/TopSection/MainTextPanel/MarginContainer/VBoxContainer/TextZone
@onready var submit_button = $Hud/MainLayout/ActionButtonsContainer/SubmitButton
@onready var game_text_input = $Hud/MainLayout/InputPanel/MarginContainer/HBoxContainer/GameTextInput
@onready var input_panel = $Hud/MainLayout/InputPanel
@onready var item_dialog = $Hud/ItemDialog

func _ready():
	# Initialize the item database
	item_db = ItemDatabase.new()
	
	# Connect signals for item interaction
	hud.inventory_item_selected.connect(_on_inventory_item_selected)
	hud.equipped_item_selected.connect(_on_equipped_item_selected)
	
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
	
	# Show input panel at the beginning for name entry
	if input_panel:
		input_panel.visible = true
		input_panel.custom_minimum_size = Vector2(0, 60)  # Set proper height for input panel
	
	game_label.text = "Enter your name:"
	submit_button.text = "Submit"
	submit_button.pressed.connect(_on_SubmitButton_pressed)  # Ensure signal is connected

	# Update the equipped items to include all available slots
	var equipped_items = {
		"Head": "Empty",
		"Chest": "Empty",
		"Hands": "Empty",
		"Legs": "Empty",
		"Feet": "Empty",
		"Weapon": "Empty",
		"Shield": "Empty",
		"Ring": "Empty",
		"Neck": "Empty",
		"Back": "Empty",
		"Belt": "Empty",
		"Pants": "Empty"
	}
	hud.update_equipped(equipped_items)

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
	
	# Ensure previous connection is removed
	if submit_button.pressed.is_connected(_on_SubmitButton_pressed):
		submit_button.pressed.disconnect(_on_SubmitButton_pressed)
	if submit_button.pressed.is_connected(_on_continue_pressed):
		submit_button.pressed.disconnect(_on_continue_pressed)
	
	# Show attack button
	submit_button.text = "Attack"
	submit_button.show()
	submit_button.pressed.connect(_on_attack_pressed)  # Connect attack function
	
	if input_panel:
		input_panel.visible = false
		input_panel.custom_minimum_size = Vector2(0, 0)

func _on_attack_pressed():
	# Use the new attack system
	var attack_result = player.attack_enemy(enemy, Player.AttackType.MELEE)
	var damage = attack_result["damage"]

	if enemy.is_alive():
		var enemy_damage = enemy.attack_enemy(player)
		game_label.text = ""
		if attack_result["critical"]:
			game_label.text += "Critical hit! "
		game_label.text += "You hit " + enemy.name + " for " + str(damage) + " damage!\n"
		game_label.text += enemy.name + " hits you for " + str(enemy_damage) + " damage!"

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
	player.xp += 10
	
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
					"ARMOR": player.armor
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
				"ARMOR": player.armor
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
				"ARMOR": player.armor
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
		
		if item.type == "Consumable":
			# Example healing potion effect
			if "health_restore" in item:
				player.health = min(player.health + item.health_restore, player.max_health)
				game_label.text = "Used " + item.name + " and restored " + str(item.health_restore) + " health!"
			
			# Remove the item after use
			player.inventory.remove_at(index)
			
			# Update the HUD
			hud.update_inventory(player.inventory, player)
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
			stats_grid.get_node_or_null("ARMORValue").text = str(player.armor)
