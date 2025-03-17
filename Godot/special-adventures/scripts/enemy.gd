class_name Enemy

var name = "Goblin"
var health = 30
var max_health = 30  # Add max_health property
var attack = 10
var defense = 3

func is_alive():
	return health > 0

func attack_player(player: Player):
	return player.take_damage(attack)
