extends Control

var player
var enemy

@onready var hud = $Hud  # Get the HUD instance
@onready var game_label = $Hud/TextZone  # Reference the Text Zone for messages
@onready var submit_button = $Hud/SubmitButton
@onready var game_text_input = $Hud/GameTextInput

func _ready():
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

	# Update HUD with initial player stats
	hud.update_player_stats(player.health, player.max_health, player.mana, player.max_mana, player.xp, player.max_xp)
	hud.update_inventory(player.inventory)
	
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
	var damage = player.attack
	enemy.health -= damage

	if enemy.is_alive():
		var enemy_damage = enemy.attack
		player.health -= enemy_damage
		game_label.text = "You hit " + enemy.name + " for " + str(damage) + "\n"
		game_label.text += enemy.name + " hits you for " + str(enemy_damage)

		hud.update_player_stats(player.health, player.max_health, player.mana, player.max_mana, player.xp, player.max_xp)
		hud.update_enemy_hp([enemy])  # Fix: Pass an array with the enemy object
	else:
		game_label.text = "You defeated the " + enemy.name + "!"
		submit_button.hide()  # Hide button after battle
