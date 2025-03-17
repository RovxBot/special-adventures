class_name Player
extends RefCounted

var name = ""
var health: int = 100
var mana: int = 50
var attack: int = 15
var defense: int = 5
var xp: int = 0
var max_health: int = 100
var max_mana: int = 50
var max_xp: int = 100  # Add max XP property
var inventory: Array = [] 

var strength: int = 10
var stamina: int = 10
var intelligence: int = 7
var agility: int = 12
var armor: int = 20

func _init(p_name):
	name = p_name
	inventory = []

func is_alive():
	return health > 0

func take_damage(damage):
	var final_damage = max(0, damage - defense)
	health = max(0, health - final_damage)
	return final_damage
