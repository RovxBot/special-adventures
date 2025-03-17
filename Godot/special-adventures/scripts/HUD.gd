extends Control

# Use get_node_or_null to prevent crashes if nodes are missing
@onready var text_zone = get_node_or_null("TextZone")
@onready var enemy_bars = get_node_or_null("EnemyBars")
@onready var player_hp = get_node_or_null("PlayerStats/HBoxContainer/HPBar")
@onready var player_mana = get_node_or_null("PlayerStats/HBoxContainer2/ManaBar")
@onready var player_xp = get_node_or_null("PlayerStats/HBoxContainer3/XPBar")
@onready var player_name_label = get_node_or_null("PlayerStats/Player")
@onready var inventory_list = get_node_or_null("InventoryList")
@onready var stats_values = get_node_or_null("StatsPanel")
@onready var item_dialog = get_node_or_null("ItemDialog")

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
		player_hp.get_parent().get_node("HP").text = "HP: " + str(hp) + "/" + str(max_hp)
		
	if player_mana:
		var mana_percent = (mana / float(max_mana)) * 100
		print("Mana bar value set to: ", mana_percent)
		player_mana.value = mana_percent
		player_mana.get_parent().get_node("Mana").text = "Mana: " + str(mana) + "/" + str(max_mana)
		
	if player_xp:
		var xp_percent = (xp / float(max_xp)) * 100
		print("XP bar value set to: ", xp_percent)
		player_xp.value = xp_percent
		player_xp.get_parent().get_node("Exp").text = "EXP: " + str(xp) + "/" + str(max_xp)
		
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
	if not stats_values:
		return

	# Use GridContainer to organize stats
	var grid = stats_values.get_node_or_null("GridContainer")
	if grid:
		# Update existing labels in grid
		for key in stats.keys():
			var label = grid.get_node_or_null(key + "Value")
			if label:
				label.text = str(stats[key])

# Update equipped items
func update_equipped(equipped_items: Dictionary):
	var equipped_panel = get_node_or_null("EquippedPanel")
	if not equipped_panel:
		return

	# Remove old labels before adding new ones
	for child in equipped_panel.get_children():
		if child.name != "Equipped":  # Don't remove the title
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
		equipped_panel.add_child(button)

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
func show_item_dialog(is_equipped: bool, item_name: String, can_equip: bool = true):
	if item_dialog:
		var title = "Item: " + item_name
		item_dialog.window_title = title
		
		# Get dialog buttons
		var equip_btn = item_dialog.get_node_or_null("VBoxContainer/EquipButton")
		var unequip_btn = item_dialog.get_node_or_null("VBoxContainer/UnequipButton")
		var destroy_btn = item_dialog.get_node_or_null("VBoxContainer/DestroyButton")
		
		# Show appropriate buttons
		if is_equipped:
			if equip_btn: equip_btn.hide()
			if unequip_btn: unequip_btn.show()
		else:
			if equip_btn: 
				equip_btn.show()
				equip_btn.disabled = not can_equip
			if unequip_btn: unequip_btn.hide()
			
		if destroy_btn: destroy_btn.show()
		
		item_dialog.popup_centered()
