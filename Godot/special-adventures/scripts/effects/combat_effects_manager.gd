extends Node

const BLOOD_PARTICLES = preload("res://scenes/effects/BloodParticles.tscn")
const SCREEN_SHAKE_INTENSITY = 10.0
const SCREEN_SHAKE_DURATION = 0.2

# Show blood particles at global position
func show_blood(global_position: Vector2, intensity: float = 1.0):
	var blood = BLOOD_PARTICLES.instantiate()
	blood.position = global_position
	
	# Scale based on intensity
	blood.amount = int(50 * intensity)
	blood.process_material.initial_velocity_max = 80.0 * intensity
	
	# Add to the current scene
	get_tree().get_root().add_child(blood)
	return blood

# Apply screen shake effect to Camera2D or viewport
func screen_shake(intensity: float = 1.0):
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
		
	var shake_strength = SCREEN_SHAKE_INTENSITY * intensity
	var shake_duration = SCREEN_SHAKE_DURATION
	
	# Create tween for camera shake
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Shake in random directions
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	for i in range(5):
		var random_angle = rng.randf() * 2.0 * PI
		var random_strength = rng.randf_range(0.5, 1.0) * shake_strength
		var offset = Vector2(cos(random_angle), sin(random_angle)) * random_strength
		
		tween.tween_property(camera, "offset", offset, shake_duration * 0.2)
	
	# Reset camera position
	tween.tween_property(camera, "offset", Vector2.ZERO, shake_duration * 0.2)

# Flash screen with color (used for damage, healing, etc.)
func flash_screen(color: Color, duration: float = 0.2):
	var flash = ColorRect.new()
	flash.color = color
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.anchors_preset = Control.PRESET_FULL_RECT
	
	get_tree().get_root().add_child(flash)
	
	# Fade out flash effect
	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.0, duration)
	tween.tween_callback(flash.queue_free)
