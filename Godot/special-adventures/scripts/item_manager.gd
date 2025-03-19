class_name ItemManager
extends RefCounted

var game
var player
var hud
var item_db

func _init(p_game):
	game = p_game
	player = game.player
	hud = game.hud
	item_db = game.item_db

func give_player_item(item_id: String):
	if player and item_db:
		var item = item_db.get_item(item_id)
		if item:
			player.inventory.append(item)
			game.add_to_game_log("You received: " + item.name)
			hud.update_inventory(player.inventory)
			return true
	return false

func handle_equip_item(index):
	if player and index >= 0 and index < player.inventory.size():
		var item = player.inventory[index]
		
		# Log debug info
		print_item_debug_info(item)
		
		if item.slot != "":  # Make sure it's an equippable item
			if player.equip_item(item):
				game.add_to_game_log("Equipped: " + item.name)
				
				# Update the HUD
				hud.update_inventory(player.inventory)
				hud.update_equipped_from_player(player)
				
				# Update player stats display
				update_stats_display()
				
				# Update action bar to reflect the new weapon
				game.combat_manager.update_available_actions()
				
				return true
			else:
				game.add_to_game_log("Cannot equip: " + item.name + 
					" (Level requirement: " + str(item.level_requirement) + ")")
		else:
			game.add_to_game_log("This item cannot be equipped.")
	
	return false

func handle_unequip_item(slot):
	if player and slot != "":
		var item = player.unequip_item(slot)
		if item:
			game.add_to_game_log("Unequipped: " + item.name)
			
			# Update the HUD
			hud.update_inventory(player.inventory)
			hud.update_equipped_from_player(player)
			
			# Update player stats display
			update_stats_display()
			
			# Update action bar to reflect the unequipped weapon
			game.combat_manager.update_available_actions()
			
			return true
	
	return false

func handle_use_item(index):
	if player and index >= 0 and index < player.inventory.size():
		var item = player.inventory[index]
		
		# Check for both Consumable and Potion types
		if item.type == "Consumable" or item.type == "Potion":
			var used = false
			
			# Handle healing potions
			if "heal" in item.stats:
				var heal_amount = item.stats["heal"]
				player.health = min(player.health + heal_amount, player.max_health)
				game.add_to_game_log("Used " + item.name + " and restored [color=#55ff55]" + 
					str(heal_amount) + " health[/color]!")
				used = true
			elif "health_restore" in item.stats:
				var heal_amount = item.stats["health_restore"]
				player.health = min(player.health + heal_amount, player.max_health)
				game.add_to_game_log("Used " + item.name + " and restored [color=#55ff55]" + 
					str(heal_amount) + " health[/color]!")
				used = true
			
			# Handle mana potions
			if "mana" in item.stats:
				var mana_amount = item.stats["mana"]
				player.mana = min(player.mana + mana_amount, player.max_mana)
				game.add_to_game_log("Used " + item.name + " and restored [color=#5555ff]" + 
					str(mana_amount) + " mana[/color]!")
				used = true
			
			if used:
				# Remove the item after use
				player.inventory.remove_at(index)
				
				# Update the HUD
				hud.update_inventory(player.inventory)
				hud.update_player_stats(player.health, player.max_health, 
					player.mana, player.max_mana, player.xp, player.max_xp)
				
				return true
	
	return false

func handle_destroy_item(index, slot):
	var item_name = ""
	
	if index >= 0:
		# Destroy from inventory
		if player and index >= 0 and index < player.inventory.size():
			var item = player.inventory[index]
			item_name = item.name
			player.inventory.remove_at(index)
			
			# Update inventory display
			hud.update_inventory(player.inventory)
			return item_name
	
	elif slot != "":
		# Destroy equipped item
		if player and player.equipped_items.has(slot) and player.equipped_items[slot] != null:
			var item = player.equipped_items[slot]
			item_name = item.name
			player.equipped_items[slot] = null
			
			# Update equipped display
			hud.update_equipped_from_player(player)
			
			# Update player stats display
			update_stats_display()
			
			return item_name
	
	return ""

func print_item_debug_info(item):
	print("Item Debug Info:")
	print("- Name: ", item.name)
	print("- Type: ", item.type)
	print("- Slot: ", item.slot)
	print("- Level Req: ", item.level_requirement)
	print("- Stats: ", item.stats)
	print("- Player level: ", player.level)

func update_stats_display():
	# Update derived stats first
	var stats = {
		"STR": player.strength,
		"STAM": player.stamina,
		"INT": player.intelligence,
		"AGI": player.agility,
		"armor": player.armor,
		"resistance": player.resistance
	}
	
	hud.update_stats(stats)
