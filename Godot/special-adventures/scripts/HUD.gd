extends Control

# Use get_node_or_null to prevent crashes if nodes are missing
@onready var text_zone = get_node_or_null("TextZone")
@onready var enemy_bars = get_node_or_null("EnemyBars")
@onready var player_hp = get_node_or_null("PlayerStats/HPBar")
@onready var player_mana = get_node_or_null("PlayerStats/ManaBar")
@onready var player_xp = get_node_or_null("PlayerStats/XPBar")
@onready var inventory_list = get_node_or_null("InventoryList")
@onready var stats_values = get_node_or_null("StatsPanel")

# Update text area
func update_text(new_text: String):
	if text_zone:
		text_zone.text = new_text

# Update player health, mana, XP
func update_player_stats(hp, max_hp, mana, max_mana, xp, max_xp):
	if player_hp:
		player_hp.value = (hp / float(max_hp)) * 100
	if player_mana:
		player_mana.value = (mana / float(max_mana)) * 100
	if player_xp:
		player_xp.value = (xp / float(max_xp)) * 100

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
		var label = Label.new()
		label.text = enemy.name + ": "
		container.add_child(label)
		var hp_bar = ProgressBar.new()
		hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hp_bar.value = (enemy.health / float(enemy.max_health)) * 100
		hp_bar.name = "HPBar"
		container.add_child(hp_bar)
		enemy_bars.add_child(container)

# Update inventory list
func update_inventory(items: Array):
	if inventory_list:
		inventory_list.clear()
		for item in items:
			inventory_list.add_item(item)

# Update stats dynamically
func update_stats(stats: Dictionary):
	if not stats_values:
		return

	# Ensure all stat labels exist before updating
	var stat_labels = {
		"STR": get_node_or_null("StatsPanel/STR"),
		"STAM": get_node_or_null("StatsPanel/STAM"),
		"INT": get_node_or_null("StatsPanel/INT"),
		"AGI": get_node_or_null("StatsPanel/AGI"),
		"ARMOR": get_node_or_null("StatsPanel/ARMOR")
	}
	
	for key in stat_labels.keys():
		if key in stats and stat_labels[key]:
			stat_labels[key].text = key + ": " + str(stats[key])

# Update equipped items
func update_equipped(equipped_items: Dictionary):
	var equipped_panel = get_node_or_null("EquippedPanel")
	if not equipped_panel:
		return

	# Remove old labels before adding new ones
	for child in equipped_panel.get_children():
		child.queue_free()

	# Wait for one frame to ensure clean update
	await get_tree().process_frame

	for slot in equipped_items.keys():
		var label = Label.new()
		label.text = slot + ": " + equipped_items[slot]
		equipped_panel.add_child(label)
