extends Control

# Use get_node_or_null to prevent crashes if nodes are missing
@onready var text_zone = get_node_or_null("MainLayout/TopSection/MainTextPanel/MarginContainer/VBoxContainer/TextZone")
@onready var enemy_bars = get_node_or_null("MainLayout/TopSection/RightPanel/EnemiesPanel/MarginContainer/VBoxContainer/EnemyBars")
@onready var player_hp = get_node_or_null("MainLayout/BottomSection/PlayerStatsSection/PlayerStatusPanel/MarginContainer/PlayerStats/HBoxContainer/HPBar")
@onready var player_mana = get_node_or_null("MainLayout/BottomSection/PlayerStatsSection/PlayerStatusPanel/MarginContainer/PlayerStats/HBoxContainer2/ManaBar")
@onready var player_xp = get_node_or_null("MainLayout/BottomSection/PlayerStatsSection/PlayerStatusPanel/MarginContainer/PlayerStats/HBoxContainer3/XPBar")
@onready var player_name_label = get_node_or_null("MainLayout/BottomSection/PlayerStatsSection/PlayerStatusPanel/MarginContainer/PlayerStats/Player")
@onready var inventory_list = get_node_or_null("MainLayout/BottomSection/InventorySection/MarginContainer/VBoxContainer/InventoryList")
@onready var stats_values = get_node_or_null("MainLayout/BottomSection/RightSection/StatsPanel/Panel/MarginContainer/VBoxContainer")
@onready var item_dialog = get_node_or_null("ItemDialog")
@onready var equipped_container = get_node_or_null("MainLayout/BottomSection/RightSection/EquippedPanel/Panel/MarginContainer/VBoxContainer/ScrollContainer/Equipped")

# Signals for when items are clicked
signal inventory_item_selected(index)
signal equipped_item_selected(slot)

# References to keep track of the currently selected item/slot
var current_player = null
var selected_inventory_index = -1
var selected_equipped_slot = ""

func _ready():
	# Make sure progress bars have proper styling and size
	_configure_progress_bar(player_hp)
	_configure_progress_bar(player_mana)
	_configure_progress_bar(player_xp)
	
	# Connect inventory item selection signal
	if inventory_list:
		inventory_list.item_selected.connect(_on_inventory_item_selected)
		inventory_list.item_activated.connect(_on_inventory_item_activated)

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

# Update inventory list
func update_inventory(items: Array, player = null):
	if inventory_list:
		inventory_list.clear()
		current_player = player
		
		for item in items:
			if item is Item:
				# Add the item name to the list
				inventory_list.add_item(item.name)
			elif item is String:
				inventory_list.add_item(item)
			else:
				inventory_list.add_item(str(item))

# Update stats dynamically
func update_stats(stats: Dictionary):
	# Update stats in the grid under player bars
	var stats_grid = get_node_or_null("MainLayout/BottomSection/PlayerStatsSection/PlayerStatusPanel/MarginContainer/PlayerStats/StatsGridContainer")
	if stats_grid:
		# Update existing labels in grid
		for key in stats.keys():
			var label = stats_grid.get_node_or_null(key + "Value")
			if label:
				label.text = str(stats[key])
				
	# Also update the old stats grid if still present
	if stats_values:
		var grid = stats_values.get_node_or_null("GridContainer")
		if grid:
			for key in stats.keys():
				var label = grid.get_node_or_null(key + "Value")
				if label:
					label.text = str(stats[key])

# Update equipped items
func update_equipped(equipped_items: Dictionary):
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
		# Fix: use the correct method to override theme color
		button.add_theme_color_override("font_hover_color", Color(0.776471, 0.729412, 0.407843))
		equipped_container.add_child(button)

# Update equipped items from player object
func update_equipped_from_player(player):
	if player == null:
		return
		
	current_player = player
	var equipped_data = {}
	for slot in player.equipped_items:
		if player.equipped_items[slot] != null:
			var item = player.equipped_items[slot]
			equipped_data[slot] = item.name
		else:
			equipped_data[slot] = "Empty"
	
	update_equipped(equipped_data)

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

# Show item dialog with options
func show_item_dialog(is_equipped: bool, item_name: String, can_equip: bool = true, item_data = null):
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
		
	# Update item name
	var item_name_label = main_container.get_node_or_null("ItemName")
	if item_name_label:
		item_name_label.text = item_name
	
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
		var is_usable = item_data and "type" in item_data and item_data.type == "Consumable"
		use_btn.visible = is_usable
		
	if destroy_btn: destroy_btn.show()
	
	# Show the dialog
	item_dialog.show()
	item_dialog.popup_centered()

func _on_item_dialog_cancel():
	if item_dialog:
		item_dialog.hide()
