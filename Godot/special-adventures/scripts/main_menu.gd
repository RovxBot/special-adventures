extends Control

func _ready():
	# Connect button signals
	$MenuPanel/MenuContainer/StartButton.pressed.connect(_on_start_pressed)
	$MenuPanel/MenuContainer/LoadButton.pressed.connect(_on_load_pressed)
	$MenuPanel/MenuContainer/OptionButton.pressed.connect(_on_options_pressed)
	$MenuPanel/MenuContainer/QuitButton.pressed.connect(_on_quit_pressed)
	
	# Set button focus for keyboard navigation
	$MenuPanel/MenuContainer/StartButton.grab_focus()
	
	# Add a subtle animation to make the menu feel more alive
	var tween = create_tween().set_loops()
	tween.tween_property($MenuPanel, "position:y", $MenuPanel.position.y + 5, 2)
	tween.tween_property($MenuPanel, "position:y", $MenuPanel.position.y, 2)

func _on_start_pressed():
	# Play a sound effect if you have one
	# $AudioPlayer.play()
	
	# Change to game scene
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_load_pressed():
	# For now, just show a message - implement proper loading later
	var notification = Label.new()
	notification.text = "Load game feature coming soon!"
	notification.position = Vector2(500, 400)
	notification.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	add_child(notification)
	
	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(func(): notification.queue_free())

func _on_options_pressed():
	# For now, just show a message - implement options menu later
	var notification = Label.new()
	notification.text = "Options menu coming soon!"
	notification.position = Vector2(500, 400)
	notification.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	add_child(notification)
	
	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(func(): notification.queue_free())

func _on_quit_pressed():
	# Exit the game
	get_tree().quit()
