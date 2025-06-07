extends Window

var player = null
signal keybinding_changed(ability_id, new_key)

func _ready():
	# Connect close button
	var close_button = get_node("Panel/MarginContainer/VBoxContainer/ButtonsContainer/CloseButton")
	close_button.pressed.connect(func(): hide())
	
	# Connect tab container
	var tab_container = get_node("Panel/MarginContainer/VBoxContainer/TabContainer")
	tab_container.tab_changed.connect(_on_tab_changed)

func setup(p_player):
	player = p_player
	refresh_ability_lists()

func refresh_ability_lists():
	if not player or not "abilities" in player:
		return
	
	# Clear existing abilities
	for i in range(3):  # Combat, Magic, Utility categories
		var container = get_node("Panel/MarginContainer/VBoxContainer/TabContainer/%s/VBoxContainer" % ["Combat", "Magic", "Utility"][i])
		for child in container.get_children():
			child.queue_free()
	
	# Add all abilities to their categories
	for ability_id in player.abilities:
		var ability = player.abilities[ability_id]
		var category_name = ["Combat", "Magic", "Utility"][ability.category]
		
		# Create the ability row
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Ability name
		var name_label = Label.new()
		name_label.text = ability.name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		
		# Ability description
		var desc_label = Label.new()
		desc_label.text = ability.description
		desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc_label.size_flags_stretch_ratio = 2
		row.add_child(desc_label)
		
		# Keybinding button
		var key_button = Button.new()
		key_button.text = ability.shortcut if "shortcut" in ability else "None"
		key_button.custom_minimum_size = Vector2(80, 30)
		key_button.pressed.connect(_on_keybind_button_pressed.bind(ability_id))
		row.add_child(key_button)
		
		# Add the row to the appropriate category
		var container = get_node("Panel/MarginContainer/VBoxContainer/TabContainer/%s/VBoxContainer" % category_name)
		container.add_child(row)

func _on_tab_changed(tab_index):
	# Switch UI to show abilities for the selected category
	pass

func _on_keybind_button_pressed(ability_id):
	# Show keybinding dialog
	var dialog = get_node("KeybindDialog")
	dialog.show()
	
	# Store the ability ID for when a key is pressed
	dialog.set_meta("target_ability", ability_id)
	
	# Connect input event to capture the next key press
	var old_handler = null
	if dialog.has_meta("input_handler"):
		old_handler = dialog.get_meta("input_handler")
		if dialog.is_connected("gui_input", old_handler):
			dialog.disconnect("gui_input", old_handler)
	
	var handler = func(event):
		if event is InputEventKey and event.pressed and not event.is_echo():
			var key_text = OS.get_keycode_string(event.keycode)
			if key_text in ["1", "2", "3", "4", "5", "6", "7", "8", "9"]:
				# Update the ability's shortcut
				var target_ability = dialog.get_meta("target_ability")
				player.abilities[target_ability].shortcut = key_text
				
				# Emit signal for game to update action bar
				keybinding_changed.emit(target_ability, key_text)
				
				# Refresh the UI
				refresh_ability_lists()
				
				# Close the dialog
				dialog.hide()
	
	dialog.set_meta("input_handler", handler)
	dialog.gui_input.connect(handler)
