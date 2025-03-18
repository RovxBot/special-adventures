extends Control

@onready var candle_flicker = $CandleFlicker
@onready var vignette = $VignetteEffect
@onready var flicker_timer = $FlickerTimer

var vignette_tween: Tween
var base_flicker_alpha = 0.05
var rng = RandomNumberGenerator.new()

func _ready():
	# Connect timer for candle flicker effect
	flicker_timer.timeout.connect(_on_flicker_timer_timeout)
	
	# Setup vignette effect
	setup_vignette()

func setup_vignette():
	# Create a subtle dark border around the screen
	var shader_material = ShaderMaterial.new()
	var shader_code = """
	shader_type canvas_item;
	
	uniform float vignette_intensity = 0.4;
	uniform float vignette_opacity = 0.5;
	uniform vec4 vignette_color: source_color = vec4(0.0, 0.0, 0.0, 1.0);
	
	void fragment() {
		vec2 uv = UV;
		uv *= 1.0 - uv.xy;
		float vig = uv.x * uv.y * 15.0;
		vig = pow(vig, vignette_intensity);
		vig = 1.0 - vig;
		
		COLOR = vec4(vignette_color.rgb, vig * vignette_opacity);
	}
	"""
	
	var shader = RDShaderSource.new()
	shader.source_code = shader_code
	shader_material.shader = shader.get_shader()
	
	# Apply shader to vignette
	vignette.material = shader_material

func _on_flicker_timer_timeout():
	# Create random flicker effect
	var flicker_variation = rng.randf_range(-0.02, 0.02)
	var new_alpha = base_flicker_alpha + flicker_variation
	new_alpha = clamp(new_alpha, 0.02, 0.08)
	
	var color = candle_flicker.color
	color.a = new_alpha
	candle_flicker.color = color
	
	# Randomize next timer interval for more natural effect
	flicker_timer.wait_time = rng.randf_range(0.08, 0.3)
