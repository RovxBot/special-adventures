class_name Player
extends RefCounted

# Player identification and character info
var name = ""
var race = "Human"  # Default race

# Core stats and resources
var health: int
var mana: int
var xp: int = 0
var max_health: int
var max_mana: int
var max_xp: int = 100
var level: int = 1

# Points for character advancement
var talent_points: int = 0  # Available talent points
var stat_points: int = 0    # Available stat points for STR, STAM, etc.

# Basic attributes - all starting at 0 (set during character creation)
var strength: int = 0     # Affects melee damage and DEF
var stamina: int = 0      # Affects health
var intelligence: int = 0  # Affects mana and magic resistance
var agility: int = 0      # Affects dodge and critical chance

# Derived combat stats
var attack: int = 5       # Base attack value
var def: int = 0          # Physical damage reduction (renamed from armor)
var resistance: int = 0   # Magic damage reduction
var block_value: int = 5  # Additional damage reduction when blocking (renamed from defense)

# NEW: Track item bonuses separately from base stats
var bonus_strength: int = 0
var bonus_agility: int = 0
var bonus_intelligence: int = 0
var bonus_stamina: int = 0
var bonus_attack: int = 0
var bonus_def: int = 0
var bonus_resistance: int = 0

# Inventory and equipment
var inventory: Array = []
var talents = {}  # Dictionary to track unlocked talents

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
	"Neck": null,
	"Back": null,    # For capes
	"Belt": null     # For belts
}

# Use GameEnums for attack types - ensure it's properly referenced
const GameEnumsScript = preload("res://scripts/game_enums.gd")
var current_attack_type = GameEnums.AttackType.MELEE  # Using the autoload singleton

# Player's learned abilities
var abilities = {}

# Initialize a new player
func _init(p_name):
	name = p_name
	inventory = []
	
	# Calculate initial stats
	recalculate_stats()
	
	# Provide starter gear
	give_starter_equipment()

# Add a new ability to the player
func learn_ability(ability_id: String, ability_data: Dictionary):
	abilities[ability_id] = ability_data
	print("Learned new ability: " + ability_data.name)

# Calculate all derived stats based on base stats
func recalculate_stats():
	# Store current health/mana percentages for proportional scaling
	var health_percent = health / float(max_health) if max_health > 0 else 1.0
	var mana_percent = mana / float(max_mana) if max_mana > 0 else 1.0
	
	# Calculate total stats including bonuses
	var total_strength = strength + bonus_strength
	var _total_agility = agility + bonus_agility  # Renamed with underscore prefix since it's not used
	var total_intelligence = intelligence + bonus_intelligence
	var total_stamina = stamina + bonus_stamina
	
	# Ensure minimum stats values
	var calc_stamina = max(1, total_stamina)
	var calc_intelligence = max(1, total_intelligence)
	
	# Calculate resource maximums
	max_health = calc_stamina * 10      # 1 STAM = 10 HP
	max_mana = calc_intelligence * 10   # 1 INT = 10 MP
	
	# Calculate combat stats using total stats
	attack = 5 + total_strength + bonus_attack  # Base attack + strength bonus + item bonus
	
	# Calculate base DEF from strength
	var base_def = 0
	if total_strength >= 2:
		base_def = int(total_strength / 2)
	
	# DEF is base_def + bonus_def from items
	def = base_def + bonus_def
	
	# Calculate base resistance from intelligence
	var base_resistance = 0
	if total_intelligence >= 3:
		base_resistance = int(total_intelligence / 3)
	
	# Total resistance includes base + item bonuses
	resistance = base_resistance + bonus_resistance
	
	# Update current health/mana proportionally
	health = round(max_health * health_percent)
	mana = round(max_mana * mana_percent)
	
	# Ensure minimum values
	health = max(1, health)
	mana = max(1, mana)
	
	print("Player stats recalculated - Base DEF: " + str(base_def) + ", Bonus DEF: " + str(bonus_def) + ", Total DEF: " + str(def))
	print("Base RES: " + str(base_resistance) + ", Bonus RES: " + str(bonus_resistance) + ", Total RES: " + str(resistance))

# Check if player is alive
func is_alive() -> bool:
	return health > 0

# Calculate damage based on attack type
func calculate_damage(attack_type: int) -> int:
	var base_damage = 0
	var weapon_damage = 0
	
	# Get weapon damage if equipped
	if equipped_items["Weapon"] != null:
		weapon_damage = equipped_items["Weapon"].stats.get("attack", 0)
		
		# Check if the attack type matches the weapon type
		var weapon_type = equipped_items["Weapon"].type
		var is_matching_type = false
		
		match attack_type:
			GameEnums.AttackType.MELEE:  # Using the autoload singleton
				is_matching_type = weapon_type in ["Sword", "Dagger", "Axe", "Hammer", "Mace"]
			GameEnums.AttackType.RANGED:  # Using the autoload singleton
				is_matching_type = weapon_type in ["Bow", "Crossbow", "Gun"]
			GameEnums.AttackType.MAGIC:  # Using the autoload singleton
				is_matching_type = weapon_type in ["Staff", "Wand"]
		
		# If using non-matching attack type with weapon, reduce effectiveness
		if not is_matching_type:
			weapon_damage = weapon_damage / 2.0  # Fixed: converted to float division
	
	# Calculate base damage based on attack type and relevant attribute
	match attack_type:
		GameEnums.AttackType.MELEE:
			base_damage = strength  # 1 STR = 1 Melee Damage
			if equipped_items["Weapon"] == null:  # Unarmed attack
				base_damage = max(1, strength / 2.0)  # Fixed: converted to float division
		GameEnums.AttackType.RANGED:
			base_damage = agility   # 1 AGI = 1 Ranged Damage
			if equipped_items["Weapon"] == null or not equipped_items["Weapon"].type in ["Bow", "Crossbow", "Gun"]:
				base_damage = max(1, agility / 3.0)  # Fixed: converted to float division
		GameEnums.AttackType.MAGIC:
			base_damage = intelligence  # 1 INT = 1 Magic Damage
			if equipped_items["Weapon"] == null or not equipped_items["Weapon"].type in ["Staff", "Wand"]:
				base_damage = max(1, intelligence / 2.0)  # Fixed: converted to float division
	
	return base_damage + weapon_damage

# Combat mechanics calculation methods
func get_dodge_chance() -> float:
	return agility  # AGI * 1 = % Chance to Dodge

func get_crit_chance() -> float:
	return min(5 + agility * 0.1, 50)  # 5% Base + AGI * 0.1 = % Chance to Crit (Max 50%)

func get_block_chance() -> float:
	if equipped_items["Shield"] != null:
		return min(5 + strength * 0.1, 50)  # 5% Base + STR * 0.1 = % Chance to Block (Max 50%)
	return 0  # No chance to block without a shield

func get_parry_chance() -> float:
	if equipped_items["Weapon"] != null and equipped_items["Shield"] == null:
		return min(1 + agility * 0.1, 30)  # 1% Base + AGI * 0.1 = % Chance to Parry (Max 30%)
	return 0

# Process incoming physical damage
func take_damage(damage) -> int:
	# Check for dodge
	if randf() * 100 <= get_dodge_chance():
		print(name + " dodged the attack!")
		return 0
		
	# Check for block if equipped with shield
	if randf() * 100 <= get_block_chance():
		print(name + " blocked the attack!")
		damage = max(0, damage - block_value * 2)  # Blocking reduces damage significantly
	
	# Apply DEF reduction
	var final_damage = max(0, damage - def)
	health = max(0, health - final_damage)
	return final_damage

# Process incoming magical damage
func take_magical_damage(damage) -> int:
	# Check for dodge (lower chance against magic)
	var magic_dodge_chance = get_dodge_chance() * 0.5  # Half as effective against magic
	if randf() * 100 <= magic_dodge_chance:
		print(name + " narrowly avoided the spell!")
		return 0
	
	# Apply resistance reduction
	var final_damage = max(0, damage - resistance)
	health = max(0, health - final_damage)
	print(name + " took " + str(final_damage) + " magical damage!")
	return final_damage

# Attack an enemy with a specific attack type
func attack_enemy(enemy, attack_type: int = GameEnums.AttackType.MELEE) -> Dictionary:
	var damage = calculate_damage(attack_type)
	var result = {
		"damage": damage,
		"critical": false,
		"dodged": false,
		"blocked": false,
		"parried": false
	}
	
	# Check for critical hit (except for magic attacks)
	if attack_type != GameEnums.AttackType.MAGIC and randf() * 100 <= get_crit_chance():
		damage *= 2
		result["critical"] = true
		print("Critical hit!")
	
	# Apply damage to enemy based on attack type
	if attack_type == GameEnums.AttackType.MAGIC:
		damage = enemy.take_magical_damage(damage)
	else:
		damage = enemy.take_damage(damage)
	
	result["damage"] = damage
	return result

# Use an ability against a target
func use_ability(ability_id: String, _target = null) -> Dictionary:  # Fixed: renamed unused parameter
	# Result dictionary to be returned
	var result = {
		"success": false,
		"message": "Ability not found",
		"damage": 0,
		"type": GameEnums.AttackType.MELEE
	}
	
	# Check if the ability exists
	if not ability_id in abilities:
		return result
		
	var ability = abilities[ability_id]
	
	# Check mana cost if it's a magical ability
	if "mana_cost" in ability and mana < ability["mana_cost"]:
		result.message = "Not enough mana!"
		return result
	
	# Apply mana cost if applicable
	if "mana_cost" in ability:
		mana -= ability["mana_cost"]
	
	# Set success and basic message
	result.success = true
	result.message = "You used " + ability.name + "!"
	
	# Handle different abilities
	match ability_id:
		"cleave":
			# Cleave does physical damage based on strength
			result.damage = strength * 1.5
			result.type = GameEnums.AttackType.MELEE
			result.message += " It cleaves through your enemy!"
			
		"fireball":
			# Fireball does magical damage based on intelligence
			result.damage = intelligence * 2
			result.type = GameEnums.AttackType.MAGIC
			result.message += " A ball of fire erupts from your hands!"
			
		"heal":
			# Heal restores health based on intelligence
			var heal_amount = intelligence * 5
			health = min(health + heal_amount, max_health)
			result.message += " You restore " + str(heal_amount) + " health!"
	
	return result

# Equip an item from inventory
func equip_item(item: Item) -> bool:
	print("WARNING: Using deprecated Player.equip_item method, use ItemManager.equip_item instead")
	# Find the game reference through the scene tree
	var game = Engine.get_main_loop().current_scene if Engine.get_main_loop() else null
	if game and game.item_manager:
		return game.item_manager.equip_item(item, item.slot)
	return false

# Unequip an item from a specific slot
func unequip_item(slot: String) -> Item:
	print("WARNING: Using deprecated Player.unequip_item method, use ItemManager.unequip_item instead")
	# Find the game reference through the scene tree
	var game = Engine.get_main_loop().current_scene if Engine.get_main_loop() else null
	if game and game.item_manager:
		if game.item_manager.unequip_item(slot):
			return equipped_items[slot]
	return null

# Give starter gear based on class/character type
func give_starter_equipment():
	# Load starter equipment config
	var json_file = FileAccess.open("res://resources/characters/starter_equipment.json", FileAccess.READ)
	if not json_file:
		push_error("Failed to open starter equipment JSON file")
		return
		
	var json_text = json_file.get_as_text()
	json_file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	
	if error != OK:
		push_error("Failed to parse starter equipment JSON: " + json.get_error_message())
		return
		
	var starter_configs = json.get_data()
	
	# Default to "default" config if no specific class is set
	var config_name = "default"
	# Could be expanded to use actual character class when implemented
	
	if config_name in starter_configs:
		var config = starter_configs[config_name]
		
		# Create and add each starter item
		for slot in config:
			var item_id = config[slot]
			
			# This assumes you have a way to create items from IDs
			# The implementation might differ based on your item creation system
			var item = create_starter_item(item_id)
			if item:
				inventory.append(item)
	else:
		push_error("Starter equipment configuration not found: " + config_name)

# Helper function to create items (implementation will depend on your item system)
func create_starter_item(item_id: String):
	# Placeholder implementation - you'll need to adapt this to your item creation system
	var item_db = ItemDatabase.new()  # This assumes ItemDatabase is globally accessible
	return item_db.get_item(item_id)

# Handle experience gain and level ups
func gain_xp(amount: int) -> bool:
	xp += amount
	
	# Check for level up
	if xp >= max_xp:
		level_up()
		return true
	
	return false

# Process level up
func level_up():
	level += 1
	xp -= max_xp
	max_xp = int(max_xp * 1.5)  # Increase XP required for next level
	
	# Grant talent and stat points
	talent_points += 1
	stat_points += 3  # Players get 3 stat points per level
	
	# Recalculate derived stats
	recalculate_stats()
	
	# Note: ability checks are now handled through talent acquisition
	# rather than automatically on level up

# Remove/rename this function as it's no longer needed
# Since it's referenced in the code, we'll keep it but make it do nothing
func check_ability_unlocks():
	# Abilities are now only unlocked through talents
	pass

# Apply talent effects based on talent ID and rank
func apply_talent_effect(talent_id: String, rank: int):
	# Dictionary mapping talent IDs to their effects
	var talent_effects = {
		"warrior_base": func(): 
			strength += 1
			stamina += 1,
		"physical_conditioning": func(): 
			stamina += rank,
		"strength_of_giants": func(): 
			strength += 2 * rank,
		"iron_skin": func(): 
			def += 2 * rank,  # Changed from armor to def
		"fortress": func(): 
			stamina += 5,
		"avatar_of_war": func(): 
			strength += 10
			stamina += 10
			def += 10,  # Changed from armor to def
		"agile_footwork": func(): 
			agility += rank
	}
	
	# Apply the effect if it exists in our mapping
	if talent_id in talent_effects:
		talent_effects[talent_id].call()
		
	# Always recalculate derived stats after applying talents
	recalculate_stats()
