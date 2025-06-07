extends Control

# Use get_node_or_null to prevent crashes if nodes are missing
@onready var text_zone = get_node_or_null("MainLayout/TopSection/MainTextPanel/MarginContainer/VBoxContainer/TextZone")
@onready var enemy_bars = get_node_or_null("MainLayout/TopSection/RightPanel/EnemiesPanel/MarginContainer/VBoxContainer/EnemyBars")
@onready var player_hp = get_node_or_null("MainLayout/BottomSection/PlayerStatsSection/PlayerStatusPanel/MarginContainer/PlayerStats/HBoxContainer/HPBar")
@onready var player_mana = get_node_or_null("MainLayout/BottomSection/PlayerStatsSection/PlayerStatusPanel/MarginContainer/PlayerStats/HBoxContainer2/ManaBar")
@onready var player_xp = get_node_or_null("MainLayout/BottomSection/PlayerStatsSection/PlayerStatusPanel/MarginContainer/PlayerStats/HBoxContainer3/XPBar")
@onready var player_name_label = get_node_or_null("MainLayout/BottomSection/PlayerStatsSection/PlayerStatusPanel/MarginContainer/PlayerStats/Player")
@onready var inventory_list = get_node_or_null("MainLayout/BottomSection/InventorySection/MarginContainer/VBoxContainer/InventoryScrollContainer/InventoryList")
@onready var stats_values = get_node_or_null("MainLayout/BottomSection/RightSection/StatsPanel/Panel/MarginContainer/VBoxContainer")
@onready var item_dialog = get_node_or_null("ItemDialog")
@onready var equipped_container = get_node_or_null("MainLayout/BottomSection/RightSection/EquippedPanel/Panel/MarginContainer/VBoxContainer/ScrollContainer/Equipped")

# Signals for when items are clicked
signal inventory_item_selected(index)
signal equipped_item_selected(slot)

# Signal for action button clicks
signal action_button_pressed(action_name)

# References to keep track of the currently selected item/slot
var current_player = null
var selected_inventory_index = -1
var selected_equipped_slot = ""

# Action categories for organizing abilities
enum ActionCategory {COMBAT, MAGIC, UTILITY}

# Store action buttons by category
var action_buttons = {
	ActionCategory.COMBAT: [],
	ActionCategory.MAGIC: [],
	ActionCategory.UTILITY: []
}

# Current active category
var active_category = ActionCategory.COMBAT

func _ready():
	# Load the dark theme for consistent styling
	var dark_theme = load("res://resources/dark_theme.tres")
	if dark_theme:
		theme = dark_theme
	
	# Make sure progress bars have proper styling and size
	_configure_progress_bar(player_hp)
	_configure_progress_bar(player_mana)
	_configure_progress_bar(player_xp)
	
	# Connect inventory item selection signal
	if inventory_list:
		inventory_list.item_selected.connect(_on_inventory_item_selected)
		inventory_list.item_activated.connect(_on_inventory_item_activated)
	
	# Initialize talent and stat points display
	update_talent_points(0)
	update_stat_points(0)
	
	# Hide action buttons container initially
	var action_container = get_node_or_null("MainLayout/ActionButtonsContainer")
	if action_container:
		action_container.visible = false
		print("Action container initially hidden")

# Helper function to configure progress bar appearance
func _configure_progress_bar(bar):
	if bar:
		bar.min_value = 0
		bar.max_value = 100
		bar.size_flags_horizontal = SIZE_EXPAND_FILL
		bar.custom_minimum_size = Vector2(150, 20) # Set minimum size
		bar.show() # Ensure it's visible

# Update text area
func update_text(new_text: String):
	if text_zone:
		text_zone.text = new_text

# Show/hide talent points indicator
func update_talent_points(points: int):
	var talent_points_label = get_node_or_null("MainLayout/BottomSection/PlayerStatsSection/PlayerStatusPanel/MarginContainer/PlayerStats/TalentButton/TalentPoints")
	if talent_points_label:
		print("Updating talent points display: ", points)
		talent_points_label.text = str(points)
		# Always show the label, regardless of points value
		talent_points_label.visible = true
		
		# Make sure the label is styled properly
		talent_points_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 1))
		talent_points_label.custom_minimum_size = Vector2(30, 0) # Ensure it has enough width
		talent_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		# Force the talent points to update visually
		if points > 0:
			# Highlight with a pulse effect if there are unspent points
			var tween = create_tween().set_loops(0) # Continuous looping
			tween.tween_property(talent_points_label, "modulate", Color(1, 1, 1, 1), 0.5)
			tween.tween_property(talent_points_label, "modulate", Color(1, 0.7, 0.7, 1), 0.5)

# Show/hide stat points indicator
func update_stat_points(points: int):
	var stat_points_label = get_node_or_null("MainLayout/BottomSection/PlayerStatsSection/PlayerStatusPanel/MarginContainer/PlayerStats/StatsButton/StatPoints")
	if stat_points_label:
		print("Updating stat points display: ", points)
		stat_points_label.text = str(points)
		# Always show the label, regardless of points value
		stat_points_label.visible = true
		
		# Make sure the label is styled properly
		stat_points_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 1))
		stat_points_label.custom_minimum_size = Vector2(30, 0) # Ensure it has enough width
		stat_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		# Force the stat points to update visually
		if points > 0:
			# Highlight with a pulse effect if there are unspent points
			var tween = create_tween().set_loops(0) # Continuous looping
			tween.tween_property(stat_points_label, "modulate", Color(1, 1, 1, 1), 0.5)
			tween.tween_property(stat_points_label, "modulate", Color(1, 0.7, 0.7, 1), 0.5)

# Open talent window
func open_talent_window(player):
	var talent_window = preload("res://scenes/TalentWindow.tscn").instantiate()
	add_child(talent_window)
	talent_window.setup(player)
	talent_window.popup_centered()
	
	# Connect signals for talent interactions
	talent_window.talent_points_spent.connect(func(talent_id): 
		if player and "talent_points" in player:
			player.talent_points -= 1
			update_talent_points(player.talent_points)
	)

# Open stats window
func open_stats_window(player):
	var stats_window = preload("res://scenes/StatsWindow.tscn").instantiate()
	add_child(stats_window)
	stats_window.setup(player)
	stats_window.popup_centered()
	
	# Connect signals for spending stat points
	stats_window.stat_point_spent.connect(func(stat_name): 
		if player:
			update_stat_points(player.stat_points)
	)

# Update player health, mana, XP
func update_player_stats(hp, max_hp, mana, max_mana, xp, max_xp):
	print("Updating stats: HP:", hp, "/", max_hp, " Mana:", mana, "/", max_mana, " XP:", xp, "/", max_xp)

	if player_name_label and player_name_label.text == "":
		# Set player name if it's empty
		if hp > 0:  # Make sure player exists
			player_name_label.text = "Player"
			
	if player_hp:
		var hp_percent = (hp / float(max_hp)) * 100
		print("HP bar value set to: ", hp_percent)
		player_hp.value = hp_percent
		var hp_label = player_hp.get_parent().get_node_or_null("HP")
		if hp_label:
			hp_label.text = "HP: " + str(hp) + "/" + str(max_hp)
		
	if player_mana:
		var mana_percent = (mana / float(max_mana)) * 100
		print("Mana bar value set to: ", mana_percent)
		player_mana.value = mana_percent
		var mana_label = player_mana.get_parent().get_node_or_null("Mana")
		if mana_label:
			mana_label.text = "Mana: " + str(mana) + "/" + str(max_mana)
		
	if player_xp:
		var xp_percent = (xp / float(max_xp)) * 100
		print("XP bar value set to: ", xp_percent)
		player_xp.value = xp_percent
		var xp_label = player_xp.get_parent().get_node_or_null("Exp") 
		if xp_label:
			xp_label.text = "EXP: " + str(xp) + "/" + str(max_xp)
		
	# Force UI refresh
	if player_hp or player_mana or player_xp:
		queue_redraw()
	
	# Add low health effect to adventure log panel
	var main_text_panel = get_node_or_null("MainLayout/TopSection/MainTextPanel")
	if main_text_panel and hp > 0:  # Make sure player exists
		var health_percent = (hp / float(max_hp)) * 100
		var log_border_style = main_text_panel.get_theme_stylebox("panel").duplicate()
		
		if health_percent < 30:  # Less than 30% health
			log_border_style.border_color = Color(0.9, 0, 0, 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.005))  # Pulsing red effect
			log_border_style.border_width_left = 4
			log_border_style.border_width_right = 4
			log_border_style.border_width_top = 4
			log_border_style.border_width_bottom = 4
		else:  # Normal border
			log_border_style.border_color = Color(0.776471, 0.729412, 0.407843, 1)  # Gold color
			log_border_style.border_width_left = 2
			log_border_style.border_width_right = 2
			log_border_style.border_width_top = 2
			log_border_style.border_width_bottom = 2
		
		main_text_panel.add_theme_stylebox_override("panel", log_border_style)

# Update enemy HP bars
func update_enemy_hp(enemies: Array):
	if not enemy_bars:
		return
	
	# Clear existing enemy bars
	for child in enemy_bars.get_children():
		child.queue_free()
	
	# Wait a frame to properly clear the UI before adding new bars
	await get_tree().process_frame

	# Create bars for each enemy
	for enemy in enemies:
		var container = HBoxContainer.new()
		container.size_flags_horizontal = SIZE_EXPAND_FILL
		
		var label = Label.new()
		label.text = enemy.name + ": "
		container.add_child(label)
		
		var hp_bar = ProgressBar.new()
		hp_bar.size_flags_horizontal = SIZE_EXPAND_FILL
		hp_bar.custom_minimum_size = Vector2(150, 20) # Set minimum size
		hp_bar.min_value = 0
		hp_bar.max_value = 100
		hp_bar.value = (enemy.health / float(enemy.max_health)) * 100
		hp_bar.name = "HPBar"
		
		# Apply the same style as player bars
		var fill_style = get_theme_stylebox("fill", "ProgressBar")
		var bg_style = get_theme_stylebox("background", "ProgressBar")
		if fill_style and bg_style:
			hp_bar.add_theme_stylebox_override("fill", fill_style)
			hp_bar.add_theme_stylebox_override("background", bg_style)
		
		container.add_child(hp_bar)
		enemy_bars.add_child(container)

# Update inventory list to use rarity colors
func update_inventory(items: Array, player = null):
	if inventory_list:
		inventory_list.clear()
		current_player = player
		
		for item in items:
			if item is Item:
				# Add the item name with proper color based on rarity
				var item_index = inventory_list.add_item(item.name)
				var color = item.get_rarity_color()
				inventory_list.set_item_custom_fg_color(item_index, color)
			elif item is String:
				inventory_list.add_item(item)
			else:
				inventory_list.add_item(str(item))

# Enhanced update_stats function to ensure DEF is properly displayed
func update_stats(stats_dict):
	# Get references to the stats grid labels
	var str_value = get_node_or_null("MainLayout/BottomSection/PlayerStatsSection/PlayerStatusPanel/MarginContainer/PlayerStats/StatsGridContainer/STRValue")
	var stam_value = get_node_or_null("MainLayout/BottomSection/PlayerStatsSection/PlayerStatusPanel/MarginContainer/PlayerStats/StatsGridContainer/STAMValue")
	var def_value = get_node_or_null("MainLayout/BottomSection/PlayerStatsSection/PlayerStatusPanel/MarginContainer/PlayerStats/StatsGridContainer/DEFValue")
	var res_value = get_node_or_null("MainLayout/BottomSection/PlayerStatsSection/PlayerStatusPanel/MarginContainer/PlayerStats/StatsGridContainer/RESValue")
	var int_value = get_node_or_null("MainLayout/BottomSection/PlayerStatsSection/PlayerStatusPanel/MarginContainer/PlayerStats/StatsGridContainer/INTValue")
	var agi_value = get_node_or_null("MainLayout/BottomSection/PlayerStatsSection/PlayerStatusPanel/MarginContainer/PlayerStats/StatsGridContainer/AGIValue")
	
	# Print full debug info 
	print("Updating HUD stats: " + str(stats_dict))
	
	# Check if we found the DEF node
	if def_value == null:
		print("ERROR: Could not find DEF value node in HUD!")
	
	# Update the displayed values if the nodes exist
	if str_value and "STR" in stats_dict:
		str_value.text = str(stats_dict["STR"])
	
	if stam_value and "STAM" in stats_dict:
		stam_value.text = str(stats_dict["STAM"])
	
	if def_value and "DEF" in stats_dict:
		var old_value = def_value.text
		def_value.text = str(stats_dict["DEF"])
		print("DEF display updated from " + old_value + " to: " + str(stats_dict["DEF"]))
	
	if res_value:
		# Only check for RES now (standardized)
		if "RES" in stats_dict:
			res_value.text = str(stats_dict["RES"])
	
	if int_value and "INT" in stats_dict:
		int_value.text = str(stats_dict["INT"])
	
	if agi_value and "AGI" in stats_dict:
		agi_value.text = str(stats_dict["AGI"])
	
	# Force UI update
	queue_redraw()

# Update equipped items with colors
func update_equipped(equipped_items: Dictionary, equipped_colors: Dictionary = {}):
	if not equipped_container:
		return

	# Remove old buttons before adding new ones
	for child in equipped_container.get_children():
		if child is Button:  # Disconnect any existing signals
			if child.pressed.is_connected(_on_equipped_item_button_pressed):
				child.pressed.disconnect(_on_equipped_item_button_pressed)
		child.queue_free()

	# Wait for one frame to ensure clean update
	await get_tree().process_frame

	for slot in equipped_items.keys():
		var button = Button.new()
		button.text = slot + ": " + equipped_items[slot]
		button.name = "slot_" + slot
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_on_equipped_item_button_pressed.bind(slot))
		
		# Apply rarity color if available
		if equipped_colors.has(slot):
			button.add_theme_color_override("font_color", equipped_colors[slot])
			button.add_theme_color_override("font_hover_color", equipped_colors[slot])
		else:
			# Fix: use the correct method to override theme color
			button.add_theme_color_override("font_hover_color", Color(0.776471, 0.729412, 0.407843))
		
		equipped_container.add_child(button)

# Update equipped items from player object with rarity colors
func update_equipped_from_player(player):
	if player == null:
		return
		
	current_player = player
	var equipped_data = {}
	var equipped_colors = {}  # Store color for each equipped item
	
	# Build data dictionaries but don't clear the container yet
	# (that will be done in update_equipped)
	for slot in player.equipped_items:
		if player.equipped_items[slot] != null:
			var item = player.equipped_items[slot]
			equipped_data[slot] = item.name
			equipped_colors[slot] = item.get_rarity_color()
		else:
			equipped_data[slot] = "Empty"
			equipped_colors[slot] = Color.WHITE
	
	# Call the lower-level function to update the UI
	# This will clear the container and create new buttons
	update_equipped(equipped_data, equipped_colors)

# Handle inventory item selection
func _on_inventory_item_selected(index):
	selected_inventory_index = index
	
func _on_inventory_item_activated(index):
	# Double click or Enter key was pressed on an inventory item
	selected_inventory_index = index
	inventory_item_selected.emit(index)

# Handle equipped item button press
func _on_equipped_item_button_pressed(slot):
	selected_equipped_slot = slot
	equipped_item_selected.emit(slot)

# Helper function to get the item dialog
func get_item_dialog():
	return get_node_or_null("ItemDialog")

# Show item dialog with options and apply rarity color to the item name
func show_item_dialog(is_equipped: bool, item_name: String, can_equip: bool = true, item_data = null):
	if not item_dialog:
		# Try to get the dialog if it wasn't found initially
		item_dialog = get_item_dialog()
		if not item_dialog:
			print("ERROR: ItemDialog not found!")
			return
	
	# Update title
	var title_text = "Item Details"
	item_dialog.title = title_text
	
	# Make sure the dialog is in the foreground
	item_dialog.move_to_foreground()
	
	# Get all necessary dialog components with null checks
	var main_container = item_dialog.get_node_or_null("Panel/MarginContainer/VBoxContainer")
	if not main_container:
		print("ERROR: Dialog container not found!")
		return
		
	# Update item name and apply color if rarity is available
	var item_name_label = main_container.get_node_or_null("ItemName")
	if item_name_label:
		item_name_label.text = item_name
		
		# Apply rarity color if available
		if item_data and "rarity" in item_data:
			var color = Color.WHITE
			match item_data.rarity:
				"Common": color = Color.WHITE
				"Magic": color = Color(0.0, 0.8, 0.0)  # Green
				"Rare": color = Color(0.0, 0.5, 1.0)   # Blue
				"Epic": color = Color(0.6, 0.0, 0.8)   # Purple
			
			item_name_label.add_theme_color_override("font_color", color)
	
	# Get item details section
	var item_details = main_container.get_node_or_null("ScrollContainer/ItemDetails")
	if not item_details:
		print("ERROR: Item details container not found!")
		return
		
	# Update description
	var item_desc = item_details.get_node_or_null("ItemDescription")
	if item_desc:
		var description = "A common item."
		if item_data and "description" in item_data:
			description = item_data.description
		item_desc.text = description
		
	# Update stats if available
	var stats_container = item_details.get_node_or_null("StatsContainer")
	if stats_container and item_data:
		var type_value = stats_container.get_node_or_null("TypeValue")
		if type_value and "type" in item_data:
			type_value.text = item_data.type
			
		var value_amount = stats_container.get_node_or_null("ValueAmount")
		if value_amount and "value" in item_data:
			value_amount.text = str(item_data.value) + " gold"
	
	# Update effects if available
	var effects_label = item_details.get_node_or_null("EffectLabel")
	var effects_container = item_details.get_node_or_null("EffectsContainer")
	
	if effects_label and effects_container and item_data and "effects" in item_data and item_data.effects.size() > 0:
		effects_label.show()
		effects_container.show()
		
		# Clear existing effects
		for child in effects_container.get_children():
			child.queue_free()
			
		# Add new effects
		for effect in item_data.effects:
			var effect_label = Label.new()
			effect_label.text = "• " + effect
			effects_container.add_child(effect_label)
	else:
		if effects_label:
			effects_label.hide()
		if effects_container:
			effects_container.hide()
	
	# Get buttons container
	var buttons_container = main_container.get_node_or_null("ButtonsContainer")
	if not buttons_container:
		print("ERROR: Buttons container not found!")
		return
		
	# Setup buttons
	var equip_btn = buttons_container.get_node_or_null("EquipButton")
	var unequip_btn = buttons_container.get_node_or_null("UnequipButton")
	var use_btn = buttons_container.get_node_or_null("UseButton")
	var destroy_btn = buttons_container.get_node_or_null("DestroyButton")
	var cancel_btn = main_container.get_node_or_null("CancelButton")
	
	# Connect cancel button
	if cancel_btn:
		if cancel_btn.pressed.is_connected(_on_item_dialog_cancel):
			cancel_btn.pressed.disconnect(_on_item_dialog_cancel)
		cancel_btn.pressed.connect(_on_item_dialog_cancel)
	
	# Show appropriate buttons based on item type and state
	if is_equipped:
		if equip_btn: equip_btn.hide()
		if unequip_btn: unequip_btn.show()
	else:
		if equip_btn: 
			equip_btn.show()
			equip_btn.disabled = not can_equip
		if unequip_btn: unequip_btn.hide()
		
	# Show/hide use button based on item type
	if use_btn:
		# Updated to check for both "Potion" and "Consumable" types
		var is_usable = item_data and "type" in item_data and (item_data.type == "Consumable" or item_data.type == "Potion")
		use_btn.visible = is_usable
		
	if destroy_btn: 
		destroy_btn.show()
	
	# Show the dialog
	item_dialog.show()
	item_dialog.popup_centered()

func _on_item_dialog_cancel():
	if item_dialog:
		item_dialog.hide()

func add_text_to_log(text: String, clear_first: bool = false):
	if text_zone:
		# Clear existing text if requested
		if clear_first:
			text_zone.clear()
		# Otherwise add a separator if this isn't the first text
		elif text_zone.text.length() > 0:
			text_zone.append_text("\n\n")
		
		# Add the new text
		text_zone.append_text(text)
		
		# Scroll to the bottom
		text_zone.scroll_to_line(text_zone.get_line_count())

# Clears and rebuilds the action bar with appropriate buttons
func update_action_bar(available_actions: Array):
	var action_bar = get_node_or_null("MainLayout/ActionButtonsContainer/ActionBarScroll/ActionBar")
	if not action_bar:
		return
		
	# Clear existing buttons
	for child in action_bar.get_children():
		child.queue_free()
	
	# Reset button arrays
	action_buttons = {
		ActionCategory.COMBAT: [],
		ActionCategory.MAGIC: [],
		ActionCategory.UTILITY: []
	}
	
	# Add buttons for each available action
	for action in available_actions:
		var button = Button.new()
		button.text = action.name
		button.custom_minimum_size = Vector2(120, 35)
		button.add_theme_color_override("font_hover_color", Color(0.776471, 0.729412, 0.407843, 1))
		
		# Store action data in button metadata
		button.set_meta("action_type", action.type)
		button.set_meta("action_name", action.name)
		button.set_meta("action_category", action.get("category", ActionCategory.COMBAT))
		
		# Add keyboard shortcut if available
		if "shortcut" in action:
			var shortcut_label = Label.new()
			shortcut_label.text = action.shortcut
			shortcut_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			shortcut_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			shortcut_label.size_flags_vertical = SIZE_SHRINK_CENTER
			button.add_child(shortcut_label)
		
		# Connect pressed signal
		button.pressed.connect(_on_action_button_pressed.bind(action.name, action.type))
		
		# Add tooltip if available
		if "tooltip" in action:
			button.tooltip_text = action.tooltip
		
		# Add button to the appropriate category
		var category = action.get("category", ActionCategory.COMBAT)
		action_buttons[category].append(button)
		
		# Add to the current action bar if it matches active category
		if category == active_category:
			action_bar.add_child(button)

# Switch between action categories
func switch_action_category(category: int):
	if category < 0 or category >= ActionCategory.size():
		return
		
	active_category = category
	
	# Update the action bar with buttons from this category
	var action_bar = get_node_or_null("MainLayout/ActionButtonsContainer/ActionBarScroll/ActionBar")
	if not action_bar:
		return
	
	# Clear existing buttons
	for child in action_bar.get_children():
		child.queue_free()
	
	# Add buttons for the selected category
	for button in action_buttons[active_category]:
		action_bar.add_child(button)

# Show cooldown on a button
func show_action_cooldown(action_name: String, cooldown_time: float):
	# Find the button with this action name
	var action_bar = get_node_or_null("MainLayout/ActionButtonsContainer/ActionBarScroll/ActionBar")
	if not action_bar:
		return
		
	for button in action_bar.get_children():
		if button.get_meta("action_name") == action_name:
			# Create or update cooldown overlay
			var cooldown = button.get_node_or_null("CooldownOverlay")
			if not cooldown:
				cooldown = ColorRect.new()
				cooldown.name = "CooldownOverlay"
				cooldown.color = Color(0, 0, 0, 0.5)
				cooldown.mouse_filter = Control.MOUSE_FILTER_IGNORE
				button.add_child(cooldown)
				cooldown.anchors_preset = Control.PRESET_FULL_RECT
			
			# Animate the cooldown
			var tween = create_tween()
			cooldown.size_flags_vertical = SIZE_FILL
			cooldown.size_flags_horizontal = SIZE_FILL
			tween.tween_property(cooldown, "size_flags_vertical", 0, cooldown_time)
			tween.tween_callback(cooldown.queue_free)
			break

# Handle action button press
func _on_action_button_pressed(action_name: String, action_type: String):
	# Emit signal to game script
	action_button_pressed.emit({"name": action_name, "type": action_type})

func add_action_button(button: Button):
	var action_bar = get_node_or_null("MainLayout/ActionButtonsContainer/ActionBarScroll/ActionBar")
	if action_bar:
		action_bar.add_child(button)

func clear_action_buttons():
	var action_bar = get_node_or_null("MainLayout/ActionButtonsContainer/ActionBarScroll/ActionBar")
	if action_bar:
		for child in action_bar.get_children():
			child.queue_free()
