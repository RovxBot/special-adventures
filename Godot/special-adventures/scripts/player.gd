class_name Player
extends RefCounted

var name = ""
var race = "Human"  # Default race
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
var talent_points: int = 0  # Available talent points
var stat_points: int = 0    # Available stat points for STR, STAM, etc.
var talents = {}  # Dictionary to track unlocked talents

# Base Stats - all starting at 0 now (will be set during character creation)
var strength: int = 0
var stamina: int = 0
var intelligence: int = 0
var agility: int = 0
var armor: int = 0  # This is "DEF" in UI - reduces physical damage
var resistance: int = 0  # Reduces magical damage only

# Equipment slots - Adding all the new slots
var equipped_items = {
	"Head": null,
	"Chest": null,
	"Hands": null,
	"Legs": null,
	"Feet": null,
	"Weapon": null,
	"Shield": null,
	"Ring": null,
	"Neck": null,
	"Back": null,    # New slot for capes
	"Belt": null,    # New slot for belts
	"Pants": null    # New slot for pants separate from legs
}

# Attack types
enum AttackType {MELEE, RANGED, MAGIC}
var current_attack_type = AttackType.MELEE

# Player's learned abilities
var abilities = {}

# Add a new ability to the player
func learn_ability(ability_id: String, ability_data: Dictionary):
	abilities[ability_id] = ability_data
	print("Learned new ability: " + ability_data.name)

# Example abilities
var example_abilities = {
	"cleave": {
		"name": "Cleave",
		"type": "MELEE",
		"category": 0, # COMBAT
		"description": "A sweeping attack that hits all nearby enemies",
		"shortcut": "2",
		"level_requirement": 3,
		"cooldown": 8.0
	},
	"fireball": {
		"name": "Fireball",
		"type": "MAGIC", 
		"category": 1, # MAGIC
		"description": "Launches a ball of fire at the enemy",
		"shortcut": "3",
		"level_requirement": 5,
		"mana_cost": 20,
		"cooldown": 6.0
	},
	"heal": {
		"name": "Heal",
		"type": "MAGIC",
		"category": 2, # UTILITY
		"description": "Restores some health",
		"shortcut": "4", 
		"level_requirement": 7,
		"mana_cost": 30,
		"cooldown": 15.0
	}
}

func _init(p_name):
	name = p_name
	inventory = []
	
	# Calculate derived stats according to formulas
	recalculate_stats()
	
	give_starter_equipment()

# Calculate all derived stats based on base stats
func recalculate_stats():
	# Ensure minimum stats values for calculations
	var calc_stamina = max(1, stamina)  # Prevent zero/negative HP
	var calc_intelligence = max(1, intelligence)  # Prevent zero/negative mana
	
	# Store current health/mana percentages
	var health_percent = health / float(max_health) if max_health > 0 else 1.0
	var mana_percent = mana / float(max_mana) if max_mana > 0 else 1.0
	
	# Update max values based on stats
	max_health = calc_stamina * 10  # 1 STAM = 10 HP
	max_mana = calc_intelligence * 10  # 1 INT = 10 MP
	
	# Calculate other derived stats
	attack = 5 + strength  # Base attack + strength bonus
	armor = 0 + strength / 2  # Base armor + strength/2 bonus
	resistance = 0 + intelligence / 3  # Base resistance + int/3 bonus
	
	# Update current health/mana proportionally instead of maxing out
	health = round(max_health * health_percent)
	mana = round(max_mana * mana_percent)
	
	# Ensure minimum values
	health = max(1, health)
	mana = max(1, mana)

func is_alive():
	return health > 0

# Calculate damage based on attack type
func calculate_damage(attack_type: AttackType) -> int:
	var base_damage = 0
	var weapon_damage = 0
	
	# Get weapon damage if equipped
	if equipped_items["Weapon"] != null:
		weapon_damage = equipped_items["Weapon"].stats.get("attack", 0)
		
		# Check if the attack type matches the weapon type
		var weapon_type = equipped_items["Weapon"].type
		var is_matching_type = false
		
		match attack_type:
			AttackType.MELEE:
				is_matching_type = weapon_type in ["Sword", "Dagger", "Axe", "Hammer", "Mace"]
			AttackType.RANGED:
				is_matching_type = weapon_type in ["Bow", "Crossbow", "Gun"]
			AttackType.MAGIC:
				is_matching_type = weapon_type in ["Staff", "Wand"]
		
		# If using non-matching attack type with weapon, reduce effectiveness
		if not is_matching_type:
			weapon_damage = weapon_damage / 2
	
	match attack_type:
		AttackType.MELEE:
			base_damage = strength  # 1 STR = 1 Melee Damage
			# Punching does less damage than with a weapon
			if equipped_items["Weapon"] == null:
				base_damage = max(1, strength / 2)
		AttackType.RANGED:
			base_damage = agility  # 1 AGI = 1 Ranged Damage
			# Can't effectively use ranged attacks without a ranged weapon
			if equipped_items["Weapon"] == null or not equipped_items["Weapon"].type in ["Bow", "Crossbow", "Gun"]:
				base_damage = max(1, agility / 3)
		AttackType.MAGIC:
			base_damage = intelligence  # 1 INT = 1 Magic Damage
			# Magic is more effective with proper implements
			if equipped_items["Weapon"] == null or not equipped_items["Weapon"].type in ["Staff", "Wand"]:
				base_damage = max(1, intelligence / 2)
	
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
	
	# DEF (armor) reduces physical damage
	var final_damage = max(0, damage - armor)
	health = max(0, health - final_damage)
	return final_damage

# Add a separate method for magical damage
func take_magical_damage(damage):
	# Check for dodge (lower chance against magic)
	var magic_dodge_chance = get_dodge_chance() * 0.5  # Half as effective against magic
	if randf() * 100 <= magic_dodge_chance:
		print(name + " narrowly avoided the spell!")
		return 0
	
	# RES (resistance) reduces magical damage
	var final_damage = max(0, damage - resistance)
	health = max(0, health - final_damage)
	print(name + " took " + str(final_damage) + " magical damage!")
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
	
	# Check if the slot exists in equipped_items
	if not equipped_items.has(item.slot):
		print("Cannot equip - invalid slot: ", item.slot)
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
	# Use the items from the database
	var farmers_shirt = Item.new("Farmer's Shirt", "Cloth Armor", "Chest", {"armor": 1}, "A simple shirt worn by farmers")
	var farmers_slacks = Item.new("Farmer's Slacks", "Cloth Armor", "Legs", {"armor": 1}, "Simple pants worn by farmers")
	var farmers_boots = Item.new("Farmer's Boots", "Cloth Armor", "Feet", {"armor": 1}, "Simple boots worn by farmers")
	
	# Add new starter item - cape
	var simple_cape = Item.new("Simple Linen Cape", "Cloth Armor", "Back", {"armor": 1}, "A flowing traveler's cape")
	
	# Create weapons (to be kept in inventory)
	var rusty_dagger = Item.new("Rusty Dagger", "Dagger", "Weapon", {"attack": 1}, "An old, rusted dagger")
	var hunters_bow = Item.new("Flimsy Hunter's Bow", "Bow", "Weapon", {"attack": 1}, "A weak but functional hunting bow")
	
	# Add all items to inventory
	inventory.append(farmers_shirt)
	inventory.append(farmers_slacks)
	inventory.append(farmers_boots)
	inventory.append(simple_cape)  # Add cape to inventory
	inventory.append(rusty_dagger)
	inventory.append(hunters_bow)
	
	# Equip the clothing items
	equip_item(farmers_shirt)
	equip_item(farmers_slacks)
	equip_item(farmers_boots)
	equip_item(simple_cape)  # Equip the cape
	
	print("Starter equipment provided: Basic clothing equipped, weapons in inventory")

# Handle leveling up and gaining talent points
func gain_xp(amount: int):
	xp += amount
	
	# Check for level up
	if xp >= max_xp:
		level_up()
	
	return xp >= max_xp  # Return true if leveled up

func level_up():
	level += 1
	xp -= max_xp
	max_xp = int(max_xp * 1.5)  # Increase XP required for next level
	
	# Increase base stats
	strength += 1
	stamina += 1
	
	# Grant talent and stat points
	talent_points += 1
	stat_points += 3  # Players get 3 stat points per level
	
	# Check for new abilities
	check_ability_unlocks()
	
	# Recalculate derived stats
	recalculate_stats()

# Check if abilities should be learned on level up
func check_ability_unlocks():
	# Check each potential ability against player level
	for ability_id in example_abilities:
		var ability = example_abilities[ability_id]
		if level >= ability.level_requirement and not ability_id in abilities:
			learn_ability(ability_id, ability.duplicate())

# Apply talent effects
func apply_talent_effect(talent_id: String, rank: int):
	if talent_id == "warrior_base":
		strength += 1
		stamina += 1
	elif talent_id == "physical_conditioning":
		stamina += rank
	elif talent_id == "strength_of_giants":
		strength += 2 * rank
	elif talent_id == "iron_skin":
		armor += 2 * rank
	elif talent_id == "fortress":
		stamina += 5
	elif talent_id == "avatar_of_war":
		strength += 10
		stamina += 10
		armor += 10
	elif talent_id == "agile_footwork":
		agility += rank
		
	# Recalculate derived stats after applying talents
	recalculate_stats()
