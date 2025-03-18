extends Node

# Global game state and save management
var current_player = null
var current_save_slot = 0
var game_settings = {
	"music_volume": 0.5,
	"sfx_volume": 0.7,
	"fullscreen": false,
	"show_tutorials": true
}

# Constants
const SAVE_PATH = "user://saves/"
const SETTINGS_PATH = "user://settings.save"

func _ready():
	# Create save directory if it doesn't exist
	var dir = DirAccess.open("user://")
	if not dir.dir_exists(SAVE_PATH):
		dir.make_dir(SAVE_PATH)
	
	# Load settings
	load_settings()
	
	print("Game Manager initialized")

# Save game to a specific slot
func save_game(slot_number):
	if not current_player:
		print("No player data to save")
		return false
	
	# Create save data dictionary
	var save_data = {
		"player_name": current_player.name,
		"player_level": current_player.level,
		"player_health": current_player.health,
		"player_max_health": current_player.max_health,
		"player_mana": current_player.mana,
		"player_max_mana": current_player.max_mana,
		"player_xp": current_player.xp,
		"player_max_xp": current_player.max_xp,
		"player_stats": {
			"strength": current_player.strength,
			"stamina": current_player.stamina,
			"agility": current_player.agility,
			"intelligence": current_player.intelligence,
		},
		"timestamp": Time.get_datetime_dict_from_system()
	}
	
	var save_path = SAVE_PATH + "save_" + str(slot_number) + ".save"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		return true
	
	return false

# Load game from a specific slot
func load_game(slot_number):
	var save_path = SAVE_PATH + "save_" + str(slot_number) + ".save"
	
	if not FileAccess.file_exists(save_path):
		print("Save file doesn't exist")
		return null
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var save_data = file.get_var()
		return save_data
	
	return null

# Save settings
func save_settings():
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_var(game_settings)
		return true
	return false

# Load settings
func load_settings():
	if not FileAccess.file_exists(SETTINGS_PATH):
		# If no settings file exists, create default settings
		save_settings()
		return
	
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file:
		var loaded_settings = file.get_var()
		if loaded_settings:
			game_settings = loaded_settings
			
			# Apply loaded settings
			if "fullscreen" in game_settings:
				if game_settings.fullscreen:
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
				else:
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func set_current_player(player):
	current_player = player
	print("Current player set: " + player.name)
