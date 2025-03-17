class_name Player
extends RefCounted

var name = ""
var health: int
var mana: int
var attack: int = 15
var defense: int = 5
var xp: int = 0
var max_health: int
var max_mana: int
var max_xp: int = 100
var inventory: Array = [] 
var level: int = 1

# Base Stats
var strength: int = 10
var stamina: int = 10
var intelligence: int = 7
var agility: int = 12
var armor: int = 5
var resistance: int = 0  # Added resistance stat for magic defense

# Equipment slots
var equipped_items = {
	"Head": null,
	"Chest": null,
	"Hands": null,
	"Legs": null,
	"Feet": null,
	"Weapon": null,
	"Shield": null,
	"Ring": null,
	"Neck": null
}

# Attack types
enum AttackType {MELEE, RANGED, MAGIC}
var current_attack_type = AttackType.MELEE

func _init(p_name):
	name = p_name
	inventory = []
	
	# Calculate derived stats according to formulas
	recalculate_stats()
	
	give_starter_equipment()

# Calculate all derived stats based on base stats
func recalculate_stats():
	max_health = stamina * 10  # 1 STAM = 10 HP
	health = max_health
	max_mana = intelligence * 10  # 1 INT = 10 MP
	mana = max_mana

func is_alive():
	return health > 0

# Calculate damage based on attack type
func calculate_damage(attack_type: AttackType) -> int:
	var base_damage = 0
	var weapon_damage = 0
	
	# Get weapon damage if equipped
	if equipped_items["Weapon"] != null:
		weapon_damage = equipped_items["Weapon"].stats.get("attack", 0)
	
	match attack_type:
		AttackType.MELEE:
			base_damage = strength  # 1 STR = 1 Melee Damage
		AttackType.RANGED:
			base_damage = agility  # 1 AGI = 1 Ranged Damage
		AttackType.MAGIC:
			base_damage = intelligence  # 1 INT = 1 Magic Damage
	
	return base_damage + weapon_damage

# Calculate chances for combat mechanics
func get_dodge_chance() -> float:
	return agility  # AGI * 1 = % Chance to Dodge

func get_crit_chance() -> float:
	return min(5 + agility * 0.1, 50)  # 5% Base + AGI * 0.1 = % Chance to Crit (Max 50%)

func get_block_chance() -> float:
	if equipped_items["Shield"] != null:
		return min(5 + strength * 0.1, 50)  # 5% Base + STR * 0.1 = % Chance to Block (Max 50%)
	return 0  # Can't block without a shield

func get_parry_chance() -> float:
	# Check if dual-wielding (would need to add off-hand weapon slot for true dual-wielding)
	if equipped_items["Weapon"] != null and equipped_items["Shield"] == null:
		return min(1 + agility * 0.1, 30)  # 1% Base + AGI * 0.1 = % Chance to Parry (Max 30%)
	return 0

func take_damage(damage):
	# Check for dodge
	if randf() * 100 <= get_dodge_chance():
		print(name + " dodged the attack!")
		return 0
		
	# Check for block if equipped with shield
	if randf() * 100 <= get_block_chance():
		print(name + " blocked the attack!")
		damage = max(0, damage - defense * 2)  # Blocking reduces damage significantly
	
	var final_damage = max(0, damage - armor)
	health = max(0, health - final_damage)
	return final_damage

func attack_enemy(enemy, attack_type: AttackType = AttackType.MELEE) -> Dictionary:
	var damage = calculate_damage(attack_type)
	var result = {
		"damage": damage,
		"critical": false,
		"dodged": false,
		"blocked": false,
		"parried": false
	}
	
	# Check for critical hit
	if attack_type != AttackType.MAGIC and randf() * 100 <= get_crit_chance():
		damage *= 2
		result["critical"] = true
		print("Critical hit!")
	
	if attack_type == AttackType.MAGIC:
		# For magic attacks, apply resistance instead of armor
		damage = enemy.take_magical_damage(damage)
	else:
		# For physical attacks
		damage = enemy.take_damage(damage)
	
	result["damage"] = damage
	return result

func equip_item(item: Item) -> bool:
	if item.level_requirement > self.level:
		return false
	
	# Check if item is in inventory first
	var item_index = -1
	for i in range(inventory.size()):
		if inventory[i] == item:
			item_index = i
			break
	
	# If item is not in inventory, can't equip it
	if item_index == -1:
		print("Cannot equip - item not in inventory")
		return false
	
	# Unequip any existing item in this slot
	if equipped_items[item.slot] != null:
		unequip_item(item.slot)
	
	# Remove from inventory when equipped
	inventory.remove_at(item_index)
	
	equipped_items[item.slot] = item
	
	# Apply item stats
	for stat_name in item.stats:
		match stat_name:
			"STR": strength += item.stats[stat_name]
			"AGI": agility += item.stats[stat_name]
			"INT": intelligence += item.stats[stat_name]
			"STAM": stamina += item.stats[stat_name]
			"armor": armor += item.stats[stat_name]
			"attack": attack += item.stats[stat_name]
			"defense": defense += item.stats[stat_name]
			"resistance": resistance += item.stats[stat_name]  # Add resistance handling
	
	# Recalculate derived stats after equipping
	recalculate_stats()
	
	print("Equipped: ", item.name)
	return true

func unequip_item(slot: String) -> Item:
	if slot in equipped_items and equipped_items[slot] != null:
		var item = equipped_items[slot]
		
		# Remove item stats
		for stat_name in item.stats:
			match stat_name:
				"STR": strength -= item.stats[stat_name]
				"AGI": agility -= item.stats[stat_name]
				"INT": intelligence -= item.stats[stat_name]
				"STAM": stamina -= item.stats[stat_name]
				"armor": armor -= item.stats[stat_name]
				"attack": attack -= item.stats[stat_name]
				"defense": defense -= item.stats[stat_name]
				"resistance": resistance -= item.stats[stat_name]  # Add resistance handling
		
		# Add the item back to inventory when unequipped
		inventory.append(item)
		
		equipped_items[slot] = null
		
		# Recalculate derived stats after unequipping
		recalculate_stats()
		
		print("Unequipped: ", item.name)
		return item
	
	return null

func give_starter_equipment():
	# Create basic clothing items (to be equipped)
	var farmers_shirt = Item.new("Farmers Shirt", "Armor", "Chest", {"armor": 1}, "A simple shirt worn by farmers")
	var farmers_slacks = Item.new("Farmers Slacks", "Armor", "Legs", {"armor": 1}, "Simple pants worn by farmers")
	var farmers_boots = Item.new("Farmers Boots", "Armor", "Feet", {"armor": 1}, "Simple boots worn by farmers")
	
	# Create weapons (to be kept in inventory)
	var rusty_dagger = Item.new("Rusted Dagger", "Weapon", "Weapon", {"attack": 1}, "An old, rusted dagger")
	var hunters_bow = Item.new("Flimsy Hunters Bow", "Weapon", "Weapon", {"attack": 1}, "A weak but functional hunting bow")
	
	# Add all items to inventory
	inventory.append(farmers_shirt)
	inventory.append(farmers_slacks)
	inventory.append(farmers_boots)
	inventory.append(rusty_dagger)
	inventory.append(hunters_bow)
	
	# Equip the clothing items
	equip_item(farmers_shirt)
	equip_item(farmers_slacks)
	equip_item(farmers_boots)
	
	# Weapons are left in inventory, not equipped
	print("Starter equipment provided: Basic clothing equipped, weapons in inventory")
