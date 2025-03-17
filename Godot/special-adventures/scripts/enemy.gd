class_name Enemy
extends RefCounted  # Add the extends RefCounted line to properly inherit

var name = "Goblin"
var health = 30
var max_health = 30
var attack = 10
var defense = 3
var armor = 2
var resistance = 1  # Add resistance stat for magic defense
var strength = 8
var agility = 4
var dodge_chance = 4  # Equal to agility

func is_alive():
	return health > 0

func take_damage(damage):
	# Check for dodge first
	if randf() * 100 <= dodge_chance:
		print(name + " dodged the attack!")
		return 0
		
	var final_damage = max(0, damage - armor)
	health = max(0, health - final_damage)
	print(name + " took " + str(final_damage) + " physical damage!")
	return final_damage
	
func take_magical_damage(damage):
	# Magical damage is reduced by resistance, not armor
	var final_damage = max(0, damage - resistance)
	health = max(0, health - final_damage)
	print(name + " took " + str(final_damage) + " magical damage!")
	return final_damage

func attack_enemy(player: Player):
	var damage = attack + strength
	return player.take_damage(damage)
