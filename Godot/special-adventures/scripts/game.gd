extends Control

var player
var enemy
var item_db  # Reference to the item database

@onready var hud = $Hud  # Get the HUD instance
@onready var game_label = $Hud/TextZone  # Reference the Text Zone for messages
@onready var submit_button = $Hud/SubmitButton
@onready var game_text_input = $Hud/GameTextInput
@onready var item_dialog = $Hud/ItemDialog  # Reference to the item dialog

func _ready():
	# Initialize the item database
	item_db = ItemDatabase.new()
	
	# Connect signals for item interaction
	hud.inventory_item_selected.connect(_on_inventory_item_selected)
	hud.equipped_item_selected.connect(_on_equipped_item_selected)
	
	# Connect item dialog button signals
	var equip_btn = item_dialog.get_node_or_null("VBoxContainer/EquipButton")
	var unequip_btn = item_dialog.get_node_or_null("VBoxContainer/UnequipButton")
	var destroy_btn = item_dialog.get_node_or_null("VBoxContainer/DestroyButton")
	var cancel_btn = item_dialog.get_node_or_null("VBoxContainer/CancelButton")
	
	if equip_btn:
		equip_btn.pressed.connect(_on_equip_button_pressed)
	if unequip_btn:
		unequip_btn.pressed.connect(_on_unequip_button_pressed)
	if destroy_btn:
		destroy_btn.pressed.connect(_on_destroy_button_pressed)
	if cancel_btn:
		cancel_btn.pressed.connect(_on_cancel_button_pressed)
	
	game_label.text = "Enter your name:"
	submit_button.pressed.connect(_on_SubmitButton_pressed)  # Ensure signal is connected

	var equipped_items = {
		"Head": "Helmet",
		"Chest": "Armor",
		"Hands": "Gloves",
		"Feet": "Boots",
		"Legs": "Leg Guards",
		"Left Hand": "Shield",
		"Right Hand": "Sword",
		"Ring": "Magic Ring",
		"Neck": "Amulet"
	}
	hud.update_equipped(equipped_items)

func _on_SubmitButton_pressed():
	var player_name = game_text_input.text.strip_edges()  # Get input text
	if player_name == "":
		game_label.text = "Please enter a valid name!"  # Prevent empty names
		return

	player = Player.new(player_name)
	enemy = Enemy.new()

	var stats = {
		"STR": player.strength,
		"STAM": player.stamina,
		"INT": player.intelligence,
		"AGI": player.agility,
		"ARMOR": player.armor
	}
	hud.update_stats(stats)

	# Hide input field
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
	
	# Show attack button
	submit_button.text = "Attack"
	submit_button.show()
	
	# Ensure previous connection is removed
	if submit_button.pressed.is_connected(_on_SubmitButton_pressed):
		submit_button.pressed.disconnect(_on_SubmitButton_pressed)
	
	submit_button.pressed.connect(_on_attack_pressed)  # Connect attack function

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
	
	# Update the HUD
	hud.update_player_stats(player.health, player.max_health, player.mana, player.max_mana, player.xp, player.max_xp)
	hud.update_inventory(player.inventory)
	
	submit_button.hide()  # Hide button after battle

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

# Item interaction handlers
func _on_inventory_item_selected(index):
	if player and index >= 0 and index < player.inventory.size():
		var item = player.inventory[index]
		var can_equip = item.slot != ""  # Can only equip items with valid slots
		
		# Show the item dialog
		hud.show_item_dialog(false, item.name, can_equip)

func _on_equipped_item_selected(slot):
	if player and player.equipped_items.has(slot) and player.equipped_items[slot] != null:
		var item = player.equipped_items[slot]
		
		# Show the item dialog
		hud.show_item_dialog(true, item.name)

# Handle equip button
func _on_equip_button_pressed():
	var index = hud.selected_inventory_index
	if player and index >= 0 and index < player.inventory.size():
		var item = player.inventory[index]
		
		if item.slot != "":  # Make sure it's an equippable item
			if player.equip_item(item):
				game_label.text = "Equipped: " + item.name
				
				# Update the HUD
				hud.update_inventory(player.inventory, player)
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
		
	item_dialog.hide()

# Handle unequip button
func _on_unequip_button_pressed():
	var slot = hud.selected_equipped_slot
	if player and slot != "":
		var item = player.unequip_item(slot)
		if item:
			game_label.text = "Unequipped: " + item.name
			
			# Update the HUD
			hud.update_inventory(player.inventory, player)
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
			hud.update_inventory(player.inventory, player)
			
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

# Handle cancel button
func _on_cancel_button_pressed():
	item_dialog.hide()
	
	# Reset selections
	hud.selected_inventory_index = -1
	hud.selected_equipped_slot = ""
