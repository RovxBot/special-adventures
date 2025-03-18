extends Window

var player = null
var available_points = 0
signal stat_point_spent(stat_name)

func _ready():
	# Connect close button
	var close_button = get_node("Panel/MarginContainer/VBoxContainer/ButtonsContainer/CloseButton")
	close_button.pressed.connect(func(): hide())
	
	# Connect stat buttons
	connect_stat_button("Strength")
	connect_stat_button("Stamina")
	connect_stat_button("Agility")
	connect_stat_button("Intelligence")

func setup(p_player):
	player = p_player
	available_points = player.stat_points if "stat_points" in player else 0
	update_ui()

func connect_stat_button(stat_name):
	var button = get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/StatsContainer/%sSection/Header/PlusButton" % stat_name)
	if button:
		button.pressed.connect(func(): increase_stat(stat_name.to_lower()))

func increase_stat(stat_name: String):
	if player and available_points > 0:
		match stat_name:
			"strength":
				player.strength += 1
			"stamina":
				player.stamina += 1
			"agility":
				player.agility += 1
			"intelligence":
				player.intelligence += 1
		
		# Always recalculate stats after any stat change
		player.recalculate_stats()
		
		available_points -= 1
		player.stat_points -= 1
		
		# Update the game's UI elements showing player stats
		var game_node = get_tree().get_first_node_in_group("game")
		if game_node and game_node.has_method("update_player_stats_display"):
			game_node.update_player_stats_display()
			
		update_ui()
		stat_point_spent.emit(stat_name)

func update_ui():
	# Update available points display
	var points_label = get_node("Panel/MarginContainer/VBoxContainer/HeaderSection/PointsLabel")
	if points_label:
		points_label.text = "Available Stat Points: %d" % available_points
	
	# Update stat values
	if player:
		update_stat_value("Strength", player.strength)
		update_stat_value("Stamina", player.stamina)
		update_stat_value("Agility", player.agility)
		update_stat_value("Intelligence", player.intelligence)
		
		# Update derived stats
		update_derived_stats()
		
		# Update button enabled states
		update_buttons_state()

func update_stat_value(stat_name: String, value: int):
	var value_label = get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/StatsContainer/%sSection/Header/Value" % stat_name)
	if value_label:
		value_label.text = str(value)

func update_derived_stats():
	# Update the derived stats section with calculated values
	var stats_grid = get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/StatsContainer/CurrentStatsSection/GridContainer")
	if stats_grid and player:
		stats_grid.get_node("HPValue").text = str(player.max_health)
		stats_grid.get_node("MPValue").text = str(player.max_mana)
		stats_grid.get_node("AttackValue").text = str(player.attack)
		stats_grid.get_node("ArmorValue").text = str(player.armor)
		stats_grid.get_node("ResistanceValue").text = str(player.resistance)
		stats_grid.get_node("DodgeValue").text = str(player.get_dodge_chance()) + "%"
		stats_grid.get_node("CritValue").text = str(player.get_crit_chance()) + "%"

func update_buttons_state():
	# Enable/disable plus buttons based on available points
	var has_points = available_points > 0
	get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/StatsContainer/StrengthSection/Header/PlusButton").disabled = not has_points
	get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/StatsContainer/StaminaSection/Header/PlusButton").disabled = not has_points
	get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/StatsContainer/AgilitySection/Header/PlusButton").disabled = not has_points
	get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/StatsContainer/IntelligenceSection/Header/PlusButton").disabled = not has_points
