extends GPUParticles2D

# Auto-restart emission and queue_free when done
func _ready():
	# Connect to the finished signal
	finished.connect(on_finished)
	
	# Start emitting
	emitting = true

func on_finished():
	# Remove the particle effect from scene when finished
	queue_free()
