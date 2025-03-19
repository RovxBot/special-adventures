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
		
		# Reduce available points
		player.stat_points -= 1
		available_points = player.stat_points
		
		# Update player stats
		player.recalculate_stats()
		
		# Update UI
		update_ui()
		
		# Emit signal
		stat_point_spent.emit(stat_name)

func update_ui():
	if player:
		# Update available points
		var points_label = get_node("Panel/MarginContainer/VBoxContainer/HeaderSection/PointsLabel")
		if points_label:
			points_label.text = "Available Stat Points: " + str(available_points)
		
		# Update stat values
		update_stat_value("Strength", player.strength)
		update_stat_value("Stamina", player.stamina)
		update_stat_value("Agility", player.agility)
		update_stat_value("Intelligence", player.intelligence)
		
		# Update derived stats
		update_derived_stats()
		
		# Enable/disable buttons based on available points
		update_button_states()

func update_stat_value(stat_name, value):
	var label = get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/StatsContainer/%sSection/Header/Value" % stat_name)
	if label:
		label.text = str(value)

func update_derived_stats():
	if player:
		# Update HP/MP
		var hp_value = get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/StatsContainer/CurrentStatsSection/GridContainer/HPValue")
		var mp_value = get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/StatsContainer/CurrentStatsSection/GridContainer/MPValue")
		if hp_value:
			hp_value.text = str(player.max_health)
		if mp_value:
			mp_value.text = str(player.max_mana)
		
		# Update other derived stats
		var attack_value = get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/StatsContainer/CurrentStatsSection/GridContainer/AttackValue")
		var armor_value = get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/StatsContainer/CurrentStatsSection/GridContainer/ArmorValue")
		var resistance_value = get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/StatsContainer/CurrentStatsSection/GridContainer/ResistanceValue")
		var dodge_value = get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/StatsContainer/CurrentStatsSection/GridContainer/DodgeValue")
		var crit_value = get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/StatsContainer/CurrentStatsSection/GridContainer/CritValue")
		
		if attack_value:
			attack_value.text = str(player.attack)
		if armor_value:
			armor_value.text = str(player.def)
		if resistance_value:
			resistance_value.text = str(player.resistance)
		if dodge_value:
			dodge_value.text = str(player.get_dodge_chance()) + "%"
		if crit_value:
			crit_value.text = str(player.get_crit_chance()) + "%"

func update_button_states():
	# Enable/disable plus buttons based on available points
	var plus_buttons = [
		get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/StatsContainer/StrengthSection/Header/PlusButton"),
		get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/StatsContainer/StaminaSection/Header/PlusButton"),
		get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/StatsContainer/AgilitySection/Header/PlusButton"),
		get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/StatsContainer/IntelligenceSection/Header/PlusButton")
	]
	
	for button in plus_buttons:
		if button:
			button.disabled = (available_points <= 0)

func update_stats(player):
	# Update attribute values
	get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/StatsContainer/StrengthSection/Header/Value").text = str(player.strength)
	get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/StatsContainer/StaminaSection/Header/Value").text = str(player.stamina)
	get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/StatsContainer/AgilitySection/Header/Value").text = str(player.agility)
	get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/StatsContainer/IntelligenceSection/Header/Value").text = str(player.intelligence)
	
	# Update derived stats
	var derived_stats = get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/StatsContainer/CurrentStatsSection/GridContainer")
	derived_stats.get_node("HPValue").text = str(player.max_health)
	derived_stats.get_node("MPValue").text = str(player.max_mana)
	derived_stats.get_node("AttackValue").text = str(player.attack)
	
	# Make sure to update the DEF value (previously referred to as ArmorValue)
	derived_stats.get_node("ArmorValue").text = str(player.def)
	
	derived_stats.get_node("ResistanceValue").text = str(player.resistance)
	derived_stats.get_node("DodgeValue").text = str(player.agility) + "%"
	
	# Calculate crit chance based on agility
	var crit_chance = 5 + (player.agility * 0.1) # 5% base + 0.1% per AGI point
	derived_stats.get_node("CritValue").text = str(snapped(crit_chance, 0.1)) + "%"
	
	print("Stats window updated. Current DEF: " + str(player.def))
