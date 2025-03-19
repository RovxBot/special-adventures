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
			if equip_item(item, item.slot):
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
		if player.equipped_items.has(slot) and player.equipped_items[slot] != null:
			var item = player.equipped_items[slot]
			# Store item name before unequipping
			var item_name = item.name
			
			if unequip_item(slot):
				game.add_to_game_log("Unequipped: " + item_name)
				
				# Update the HUD
				hud.update_inventory(player.inventory)
				hud.update_equipped_from_player(player)
				
				# Update player stats display
				update_stats_display()
				
				# Update action bar to reflect the unequipped weapon
				if game.is_in_combat and game.combat_manager:
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
			item_name = item.name  # Store name before destroying
			player.inventory.remove_at(index)
			
			# Update inventory display
			hud.update_inventory(player.inventory)
			return item_name
	
	elif slot != "":
		# Destroy equipped item
		if player and player.equipped_items.has(slot) and player.equipped_items[slot] != null:
			var item = player.equipped_items[slot]
			item_name = item.name  # Store name before destroying
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
			"DEF": player.def,           # Changed from armor to def
		"resistance": player.resistance
	}
	
	hud.update_stats(stats)

func equip_item(item, slot):
	if not player:
		return false
	
	# If already equipped in this slot, do nothing
	if player.equipped_items[slot] == item:
		return false
	
	# Check level requirement
	if item.level_requirement > player.level:
		game.add_to_game_log("Cannot equip: " + item.name + " (Level requirement: " + str(item.level_requirement) + ")")
		return false
	
	# Store the previous item to return to inventory
	var previous_item = player.equipped_items[slot]
	
	# Remove from inventory first, before equipping
	if item in player.inventory:
		player.inventory.erase(item)
	
	# Now equip the item
	player.equipped_items[slot] = item
	
	# Put previous item back in inventory if there was one
	if previous_item:
		player.inventory.append(previous_item)
	
	# Apply item stat bonuses by updating all stats
	apply_item_stats(item, true)
	
	# If there was a previous item, remove its stats
	if previous_item:
		apply_item_stats(previous_item, false)
	
	# Recalculate player stats after equip changes to ensure proper base values
	player.recalculate_stats()
	
	# Update stats display
	update_stats_display()
	
	# Only update action bar if in combat
	if game.is_in_combat and game.combat_manager:
		game.combat_manager.update_available_actions()
	
	game.add_to_game_log("Equipped " + item.name + " in " + slot + " slot.")
	return true

func unequip_item(slot):
	if not player or not slot in player.equipped_items:
		return false
	
	var item = player.equipped_items[slot]
	if not item:
		return false
	
	# Store item name before unequipping
	var item_name = item.name
	
	# Remove from equipped slot
	player.equipped_items[slot] = null
	
	# Add back to inventory
	player.inventory.append(item)
	
	# Remove item stat bonuses
	apply_item_stats(item, false)
	
	# Recalculate player stats after unequip to ensure proper base values
	player.recalculate_stats()
	
	# Update stats display
	update_stats_display()
	
	# Only update action bar if in combat
	if game.is_in_combat and game.combat_manager:
		game.combat_manager.update_available_actions()
	
	game.add_to_game_log("Unequipped " + item_name + " from " + slot + " slot.")
	return true

# New helper function to apply/remove item stats
func apply_item_stats(item, add_stats: bool = true):
	# Get the multiplier (add or subtract)
	var mult = 1 if add_stats else -1
	
	# Store initial DEF and RES values for debugging
	var initial_def = player.def
	var initial_res = player.resistance
	
	# Apply each stat from the item
	for stat_name in item.stats:
		var value = item.stats[stat_name] * mult
		
		match stat_name:
			"STR", "strength":
				player.strength += value
			"AGI", "agility":
				player.agility += value
			"INT", "intelligence":
				player.intelligence += value
			"STAM", "stamina":
				player.stamina += value
			"attack":
				player.attack += value
			"DEF", "def", "armor", "defence", "defense":
				player.def += value  # Apply DEF directly to def attribute
				print("DEF updated: " + str(initial_def) + " -> " + str(player.def) + " (change: " + ("+%d" % value if add_stats else "-%d" % abs(value)) + ")")
			"RES", "resistance":
				player.resistance += value
				print("RES updated: " + str(initial_res) + " -> " + str(player.resistance) + " (change: " + ("+%d" % value if add_stats else "-%d" % abs(value)) + ")")
	
	# Debug output for stat changes
	if add_stats:
		print("Applied stats from item: " + item.name + " - Stats: " + str(item.stats))
		print("DEF changed from " + str(initial_def) + " to " + str(player.def))
		print("RES changed from " + str(initial_res) + " to " + str(player.resistance))
	else:
		print("Removed stats from item: " + item.name + " - Stats: " + str(item.stats))
		print("DEF changed from " + str(initial_def) + " to " + str(player.def))
		print("RES changed from " + str(initial_res) + " to " + str(player.resistance))
	
	# Make sure DEF never goes below 0
	if player.def < 0:
		print("WARNING: DEF went negative (" + str(player.def) + "). Resetting to 0.")
		player.def = 0
	
	# Make sure RES never goes below 0 also
	if player.resistance < 0:
		print("WARNING: RES went negative (" + str(player.resistance) + "). Resetting to 0.")
		player.resistance = 0
	
	# Update the HUD with the new stats
	update_player_stats_display()

# Add this new function to refresh stats display after item operations
func update_player_stats_display():
	# Update stats display in HUD
	if hud:
		var stats = {
			"STR": player.strength,
			"STAM": player.stamina,
			"INT": player.intelligence,
			"AGI": player.agility,
			"DEF": player.def,
			"RES": player.resistance  # Use "RES" consistently as the key
		}
		hud.update_stats(stats)
