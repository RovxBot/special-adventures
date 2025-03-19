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

class_name AbilityManager
extends RefCounted

var game
var player
var hud
var ability_cooldowns = {}

func _init(p_game):
    game = p_game
    player = game.player
    hud = game.hud

func use_ability_with_cooldown(ability_id, cooldown_time):
    # Put ability on cooldown
    ability_cooldowns[ability_id] = cooldown_time
    
    # Start a timer to remove the cooldown
    var timer = game.get_tree().create_timer(cooldown_time)
    timer.timeout.connect(func(): ability_cooldowns.erase(ability_id))
    
    # Update action bar to show cooldown
    if "abilities" in player and ability_id in player.abilities:
        var ability = player.abilities[ability_id]
        hud.show_action_cooldown(ability.name, cooldown_time)
    
    # Update available actions to exclude this ability
    game.combat_manager.update_available_actions()

func process_ability_action(action_data):
    # Handle abilities with special effects
    if "ability_id" in action_data:
        var ability_id = action_data.ability_id
        var ability = player.abilities[ability_id]
        
        # Use ability and apply cooldown
        var result = player.use_ability(ability_id, game.current_enemy)
        
        if result.success:
            game.add_to_game_log(result.message)
            
            # Apply cooldown if specified
            if "cooldown" in ability:
                use_ability_with_cooldown(ability_id, ability.cooldown)
            
            # Process damage or other effects
            if "damage" in result:
                if result.type == Player.AttackType.MAGIC:
                    game.current_enemy.take_magical_damage(result.damage)
                else:
                    game.current_enemy.take_damage(result.damage)
                
                game.add_to_game_log("The ability deals [color=#ff5555]" + 
                    str(result.damage) + "[/color] damage!")
                
                # Update enemy health display
                hud.update_enemy_hp([game.current_enemy])
                
                # Check if enemy died
                if not game.current_enemy.is_alive():
                    game.combat_manager.handle_enemy_defeat()
            
            # Update player stats after ability use
            hud.update_player_stats(player.health, player.max_health, 
                player.mana, player.max_mana, player.xp, player.max_xp)
            
            return true
        else:
            game.add_to_game_log("[color=#ff5555]" + result.message + "[/color]")
    
    return false
