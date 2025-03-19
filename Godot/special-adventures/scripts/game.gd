extends Control

var player
var current_enemy # Rename from 'enemy' for clarity 
var item_db  # Reference to the item database
var character_creation_scene

# Manager instances
var combat_manager
var item_manager
var ability_manager

@onready var hud = $Hud  # Get the HUD instance
# Update paths to match new HUD structure
@onready var game_label = $Hud/MainLayout/TopSection/MainTextPanel/MarginContainer/VBoxContainer/TextZone
@onready var submit_button = $Hud/MainLayout/ActionButtonsContainer/SubmitButton
@onready var game_text_input = $Hud/MainLayout/InputPanel/MarginContainer/HBoxContainer/GameTextInput
@onready var input_panel = $Hud/MainLayout/InputPanel
# Fix ItemDialog path - use get_node_or_null for safety
@onready var item_dialog = hud.get_node_or_null("ItemDialog")

# Store ability cooldowns
var ability_cooldowns = {}

# Add reference to combat effects
var combat_effects

var story_manager = null
var story_choices = []
var current_story_file = "res://data/stories/intro_story.json"

func _ready():
	# Initialize the item database
	item_db = ItemDatabase.new()
	
	# Initialize combat effects
	combat_effects = load("res://scripts/effects/combat_effects_manager.gd").new()
	add_child(combat_effects)
	
	# Add ambient UI effects
	var ambient_effects = load("res://scenes/effects/AmbientUIEffects.tscn").instantiate()
	add_child(ambient_effects)
	
	# Connect signals for item interaction
	hud.inventory_item_selected.connect(_on_inventory_item_selected)
	hud.equipped_item_selected.connect(_on_equipped_item_selected)
	
	# Connect talent button
	var talent_button = hud.get_node_or_null("MainLayout/BottomSection/PlayerStatsSection/PlayerStatusPanel/MarginContainer/PlayerStats/TalentButton")
	if talent_button:
		talent_button.pressed.connect(_on_talent_button_pressed)
	
	# Connect item dialog button signals - update for safer access
	if item_dialog:
		var dialog_container = item_dialog.get_node_or_null("Panel/MarginContainer/VBoxContainer")
		if dialog_container:
			var buttons_container = dialog_container.get_node_or_null("ButtonsContainer")
			if buttons_container:
				var equip_btn = buttons_container.get_node_or_null("EquipButton")
				var unequip_btn = buttons_container.get_node_or_null("UnequipButton")
				var use_btn = buttons_container.get_node_or_null("UseButton")
				var destroy_btn = buttons_container.get_node_or_null("DestroyButton")
				var cancel_btn = dialog_container.get_node_or_null("CancelButton")
				
				if equip_btn:
					equip_btn.pressed.connect(_on_equip_button_pressed)
				if unequip_btn:
					unequip_btn.pressed.connect(_on_unequip_button_pressed)
				if use_btn:
					use_btn.pressed.connect(_on_use_button_pressed)
				if destroy_btn:
					destroy_btn.pressed.connect(_on_destroy_button_pressed)
				if cancel_btn:
					cancel_btn.pressed.connect(_on_cancel_button_pressed)
	else:
		print("WARNING: ItemDialog not found in HUD!")
	
	# Connect stats button
	var stats_button = hud.get_node_or_null("MainLayout/BottomSection/PlayerStatsSection/PlayerStatusPanel/MarginContainer/PlayerStats/StatsButton")
	if stats_button:
		stats_button.pressed.connect(_on_stats_button_pressed)
	
	# Connect action button signal
	hud.action_button_pressed.connect(_on_action_button_pressed)
	
	# Start with character creation
	start_character_creation()
	
	# Hide HUD initially
	hud.visible = false

func start_character_creation():
	# Load and instantiate the character creation scene
	character_creation_scene = load("res://scenes/CharacterCreation.tscn").instantiate()
	add_child(character_creation_scene)
	
	# Connect signals
	character_creation_scene.character_created.connect(_on_character_created)
	character_creation_scene.creation_cancelled.connect(_on_creation_cancelled)

func _on_character_created(character_data):
	# Clean up character creation scene
	if character_creation_scene:
		character_creation_scene.queue_free()
		character_creation_scene = null
	
	# Create player with the provided data
	player = Player.new(character_data.name)
	
	# Set custom stats from character creation
	player.strength = character_data.strength
	player.agility = character_data.agility
	player.stamina = character_data.stamina
	player.intelligence = character_data.intelligence
	player.race = character_data.race  # Store race information
	
	# Recalculate stats after customization
	player.recalculate_stats()
	
	# Initialize managers once player exists
	combat_manager = CombatManager.new(self)
	item_manager = ItemManager.new(self)
	ability_manager = AbilityManager.new(self)
	
	# Create enemy
	current_enemy = Enemy.new()
	
	# Set player name in the UI
	var player_name_label = hud.get_node_or_null("MainLayout/BottomSection/PlayerStatsSection/PlayerStatusPanel/MarginContainer/PlayerStats/Player")
	if player_name_label:
		player_name_label.text = player.name
		
		# Add race in parentheses
		if player.race:
			player_name_label.text += " (" + player.race + ")"
	
	# Update stats display
	var stats = {
		"STR": player.strength,
		"STAM": player.stamina,
		"INT": player.intelligence,
		"AGI": player.agility,
		"armor": player.armor,
		"resistance": player.resistance
	}
	hud.update_stats(stats)
	
	# Update HUD with initial player stats and equipment
	hud.update_player_stats(player.health, player.max_health, player.mana, player.max_mana, player.xp, player.max_xp)
	hud.update_inventory(player.inventory)
	hud.update_equipped_from_player(player)
	hud.update_talent_points(player.talent_points)
	hud.update_stat_points(player.stat_points)
	
	# Show HUD
	hud.visible = true
	
	# Initialize story manager
	initialize_story_manager()
	
	# Start the game with a battle or story based on preference
	start_story() # Start with story instead of combat

func _on_creation_cancelled():
	# Handle creation cancelled (return to main menu or exit)
	# For now, we'll just restart character creation
	if character_creation_scene:
		character_creation_scene.queue_free()
		character_creation_scene = null
	
	# Restart character creation
	call_deferred("start_character_creation")

func _on_SubmitButton_pressed():
	var player_name = game_text_input.text.strip_edges()  # Get input text
	if player_name == "":
		game_label.text = "Please enter a valid name!"  # Prevent empty names
		return
	
	player = Player.new(player_name)
	current_enemy = Enemy.new()
	
	# Create managers
	combat_manager = CombatManager.new(self)
	item_manager = ItemManager.new(self)
	ability_manager = AbilityManager.new(self)
	
	# Set player name and hide input panel
	if player_name != "":
		# Make sure player name is set in the UI
		var player_name_label = hud.get_node_or_null("MainLayout/BottomSection/PlayerStatsSection/PlayerStatusPanel/MarginContainer/PlayerStats/Player")
		if player_name_label:
			player_name_label.text = player_name
	
	var stats = {
		"STR": player.strength,
		"STAM": player.stamina,
		"INT": player.intelligence,
		"AGI": player.agility,
		"armor": player.armor
	}
	hud.update_stats(stats)
	
	# Hide input field
	if input_panel:
		input_panel.visible = false
		input_panel.custom_minimum_size = Vector2(0, 0)  # Remove height when not visible
	game_text_input.hide()
	submit_button.hide()
	
	# Update HUD with initial player stats and equipment
	hud.update_player_stats(player.health, player.max_health, player.mana, player.max_mana, player.xp, player.max_xp)
	hud.update_inventory(player.inventory)
	hud.update_equipped_from_player(player)
	
	start_battle()

func start_battle():
	combat_manager.start_battle(current_enemy)
	
	if input_panel:
		input_panel.visible = false
		input_panel.custom_minimum_size = Vector2(0, 0)

# Add this function to give player a new item from database
func give_player_item(item_id: String):
	return item_manager.give_player_item(item_id)

# Delegate action handling to ability manager first, then combat manager
func _on_action_button_pressed(action_data):
	# First check if it's an ability
	if "ability_id" in action_data:
		ability_manager.process_ability_action(action_data)
	else:
		# Otherwise, it's a regular combat action
		combat_manager.process_combat_action(action_data)

# Add a stub for the old function to avoid errors during disconnection attempts
func _on_attack_pressed():
	# This is just a stub to prevent errors when disconnecting
	pass

# Add new function to handle continuing to next battle
func _on_continue_pressed():
	# Create a new enemy but keep the same player
	current_enemy = Enemy.new()
	
	# Disconnect continue button and prepare for next battle
	if submit_button.pressed.is_connected(_on_continue_pressed):
		submit_button.pressed.disconnect(_on_continue_pressed)
	
	# Start a new battle with the same player (preserving health/mana)
	start_battle()

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
		
		# Show the item dialog with item data
		var item_data = {
			"type": item.type,
			"description": item.description,
			"rarity": item.rarity,  # Pass rarity to the dialog
			"value": 10,  # Example value, you can add this to your Item class
			"effects": []  # Build effects list from item stats
		}
		
		# Fill effects array with stat bonuses
		for stat_name in item.stats:
			item_data.effects.append(stat_name + ": +" + str(item.stats[stat_name]))
		
		hud.show_item_dialog(false, item.name, can_equip, item_data)

func _on_equipped_item_selected(slot):
	if player and player.equipped_items.has(slot) and player.equipped_items[slot] != null:
		var item = player.equipped_items[slot]
		
		# Show the item dialog with item data
		var item_data = {
			"type": item.type,
			"description": item.description,
			"rarity": item.rarity,  # Pass rarity to dialog
			"value": 10,  # Example value
			"effects": []
		}
		
		# Fill effects array with stat bonuses
		for stat_name in item.stats:
			item_data.effects.append(stat_name + ": +" + str(item.stats[stat_name]))
		
		hud.show_item_dialog(true, item.name, true, item_data)

# Handle equip button - delegate to item manager
func _on_equip_button_pressed():
	var index = hud.selected_inventory_index
	if item_manager.handle_equip_item(index):
		# Success - handled by item_manager
		pass
	item_dialog.hide()

# Handle unequip button - delegate to item manager
func _on_unequip_button_pressed():
	var slot = hud.selected_equipped_slot
	if item_manager.handle_unequip_item(slot):
		# Success - handled by item_manager
		pass
	item_dialog.hide()

# Handle destroy button - delegate to item manager
func _on_destroy_button_pressed():
	var index = hud.selected_inventory_index
	var slot = hud.selected_equipped_slot
	
	var item_name = item_manager.handle_destroy_item(index, slot)
	if item_name != "":
		game_label.text = "Destroyed: " + item_name
	
	item_dialog.hide()

# Delegate to item manager
func _on_use_button_pressed():
	var index = hud.selected_inventory_index
	if item_manager.handle_use_item(index):
		# Success - handled by item_manager
		pass
	
	item_dialog.hide()

# Handle cancel button
func _on_cancel_button_pressed():
	if item_dialog:
		item_dialog.hide()
	
	# Reset selections
	hud.selected_inventory_index = -1
	hud.selected_equipped_slot = ""

# Update stats display in the new location
func update_player_stats_display():
	if player:
		item_manager.update_stats_display()

func _on_talent_button_pressed():
	if player:
		hud.open_talent_window(player)

func _on_stats_button_pressed():
	if player:
		hud.open_stats_window(player)

# Use rich text tags for colored text in game label
func update_game_text(text, text_type = "normal"):
	var colored_text = ""
	
	match text_type:
		"damage":
			colored_text = "[color=#ff5555]" + text + "[/color]"  # Red for damage
		"healing":
			colored_text = "[color=#55ff55]" + text + "[/color]"  # Green for healing
		"mana":
			colored_text = "[color=#5555ff]" + text + "[/color]"  # Blue for mana
		"xp":
			colored_text = "[color=#ffff55]" + text + "[/color]"  # Yellow for XP
		"item":
			colored_text = "[color=#ff55ff]" + text + "[/color]"  # Purple for items
		_:
			colored_text = text
	
	game_label.text = colored_text

func add_to_game_log(text: String, clear_first: bool = false):
	if hud:
		hud.add_text_to_log(text, clear_first)

func _on_story_updated(text, clear_text = false):
	# Add the text to the game log, clearing first if requested
	add_to_game_log(text, clear_text)
	
	# Clear any existing story choice buttons when main text changes
	# (but not for item acquisition notifications)
	if clear_text:
		clear_action_buttons()

func initialize_story_manager():
	story_manager = StoryManager.new(self)
	story_manager.story_updated.connect(_on_story_updated)
	story_manager.choices_available.connect(_on_story_choices_available)
	story_manager.story_event_triggered.connect(_on_story_event_triggered)
	
	# Load the initial story file
	if story_manager.load_story_file(current_story_file):
		print("Story loaded successfully")
	else:
		print("Failed to load story")

func start_story():
	if story_manager:
		add_to_game_log("Beginning your adventure...", Color(0.8, 0.8, 0.2))
		story_manager.start_story()
	else:
		start_battle() # Fallback to combat if no story

func _on_story_choices_available(choices):
	story_choices = choices
	
	# Create buttons for each choice
	for i in range(choices.size()):
		var choice = choices[i]
		create_choice_button(choice.text, i)

func create_choice_button(text: String, choice_index: int):
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(150, 40)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Connect button press to choice selection
	button.pressed.connect(func(): _on_story_choice_selected(choice_index))
	
	# Add button to UI
	hud.add_action_button(button)

func _on_story_choice_selected(choice_index: int):
	# Process the selected choice
	var choice_text = story_choices[choice_index].text
	add_to_game_log("[color=#A9A9A9]You chose: " + choice_text + "[/color]")
	
	# Clear action buttons
	clear_action_buttons()
	
	# Tell the story manager about our choice
	story_manager.select_choice(choice_index)

func _on_story_event_triggered(event_id: String):
	match event_id:
		"chapter_complete":
			add_to_game_log("[color=yellow]Chapter completed! You've earned experience.[/color]")
			player.gain_xp(50)
		"treasure_found":
			add_to_game_log("[color=yellow]You've found a treasure![/color]")
		"ambush":
			add_to_game_log("[color=red]You've been ambushed![/color]")
			start_battle()
		_:
			print("Unhandled story event: ", event_id)

func clear_action_buttons():
	hud.clear_action_buttons()

func start_combat_with_enemy(enemy_id: String):
	# Create specific enemy type based on ID
	var enemy_data = {
		"dark_acolyte": {
			"name": "Dark Acolyte",
			"health": 50,
			"max_health": 50,
			"attack": 8,
			"defense": 3,
			"xp_reward": 30,
			"gold_reward": 15
		},
		"forest_wolf": {
			"name": "Forest Wolf",
			"health": 40,
			"max_health": 40,
			"attack": 6,
			"defense": 2,
			"xp_reward": 20,
			"gold_reward": 5
		}
		# Add more enemies as needed
	}
	
	if enemy_id in enemy_data:
		current_enemy = Enemy.new()
		var data = enemy_data[enemy_id]
		current_enemy.name = data.name
		current_enemy.health = data.health
		current_enemy.max_health = data.max_health
		current_enemy.attack = data.attack
		current_enemy.defense = data.defense
		if "xp_reward" in data:
			current_enemy.xp_reward = data.xp_reward
		if "gold_reward" in data:
			current_enemy.gold_reward = data.gold_reward
		
		start_battle()
	else:
		print("Unknown enemy ID: ", enemy_id)
		# Create default enemy as fallback
		current_enemy = Enemy.new()
		start_battle()

# Process keyboard shortcuts for abilities
func _input(event):
	if not player or not player.is_alive():
		return
		
	if event is InputEventKey and event.pressed:
		var key_pressed = OS.get_keycode_string(event.keycode)
		
		# Number keys 1-9 for ability shortcuts
		if key_pressed in ["1", "2", "3", "4", "5", "6", "7", "8", "9"]:
			var action_bar = hud.get_node_or_null("MainLayout/ActionButtonsContainer/ActionBarScroll/ActionBar")
			if action_bar:
				# Find button with this shortcut and trigger it
				for button in action_bar.get_children():
					var shortcut_label = button.get_node_or_null("Label")
					if shortcut_label and shortcut_label.text == key_pressed:
						button.emit_signal("pressed")
						return
