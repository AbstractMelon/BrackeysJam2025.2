extends RigidBody3D
class_name PickupableItem

@export var item_data: ItemData
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var pickup_area: Area3D = $PickupArea
@onready var outline_material: StandardMaterial3D

var is_being_carried: bool = false
var is_highlighted: bool = false
var original_material: Material

signal item_picked_up(item: PickupableItem)
signal item_dropped(item: PickupableItem)

func _ready():
	# Set proper collision layers and masks
	collision_layer = 1  # Item layer
	collision_mask = 1   # Can collide with world
	
	# Ensure RigidBody settings are correct for pickup
	gravity_scale = 1.0
	can_sleep = true
	
	if item_data:
		setup_item()
	
	# Setup pickup area
	if pickup_area:
		pickup_area.body_entered.connect(_on_player_entered)
		pickup_area.body_exited.connect(_on_player_exited)
		# Make sure pickup area is on the right layer
		pickup_area.collision_layer = 2  # Separate layer for detection
		pickup_area.collision_mask = 4   # Layer for player detection
	
	# Create outline material for highlighting
	outline_material = StandardMaterial3D.new()
	outline_material.flags_unshaded = true
	outline_material.albedo_color = Color.YELLOW
	outline_material.flags_do_not_receive_shadows = true
	outline_material.flags_disable_ambient_light = true
	outline_material.no_depth_test = true  # Ensure outline is visible
	outline_material.flags_transparent = true
	outline_material.albedo_color.a = 0.7

func setup_item():
	if not item_data:
		return
	
	# Apply mesh and material
	if item_data.mesh and mesh_instance:
		mesh_instance.mesh = item_data.mesh
		
		# Auto-generate collision shape if none exists
		if collision_shape and not collision_shape.shape:
			var trimesh_shape = item_data.mesh.create_trimesh_shape()
			if trimesh_shape:
				collision_shape.shape = trimesh_shape
	
	if item_data.material and mesh_instance:
		mesh_instance.material_override = item_data.material
		original_material = item_data.material
	
	# Handle shiny items
	if item_data.is_shiny:
		add_shiny_effect()

func add_shiny_effect():
	var shader_code = """
		shader_type spatial;
		render_mode specular_schlick_ggx;
		
		// Base appearance
		uniform vec4 base_color : source_color = vec4(0.9, 0.9, 0.9, 1.0);
		uniform float metallic : hint_range(0.0, 1.0) = 0.8;
		uniform float roughness : hint_range(0.0, 1.0) = 0.1;
		
		// Foil effect controls
		uniform float shimmer_speed : hint_range(0.1, 5.0) = 1.5;
		uniform float shimmer_scale : hint_range(1.0, 20.0) = 8.0;
		uniform float emission_strength : hint_range(0.0, 3.0) = 1.5;
		uniform float rainbow_intensity : hint_range(0.0, 2.0) = 1.0;
		uniform float foil_contrast : hint_range(0.1, 3.0) = 1.8;
		
		// Advanced controls
		uniform float noise_scale : hint_range(1.0, 50.0) = 15.0;
		uniform float distortion_strength : hint_range(0.0, 0.5) = 0.1;
		uniform vec2 scroll_direction = vec2(1.0, 0.3);
		uniform bool enable_sparkles = true;
		uniform float sparkle_density : hint_range(0.1, 5.0) = 2.0;
		uniform float view_angle_effect : hint_range(0.0, 2.0) = 0.8;
		
		// Noise function for more organic patterns
		float noise(vec2 pos) {
			return fract(sin(dot(pos, vec2(12.9898, 78.233))) * 43758.5453);
		}
		
		float smooth_noise(vec2 pos) {
			vec2 i = floor(pos);
			vec2 f = fract(pos);
			f = f * f * (3.0 - 2.0 * f);
			
			float a = noise(i);
			float b = noise(i + vec2(1.0, 0.0));
			float c = noise(i + vec2(0.0, 1.0));
			float d = noise(i + vec2(1.0, 1.0));
			
			return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
		}
		
		// Enhanced rainbow function with more vibrant colors
		vec3 rainbow(float t) {
			t = fract(t); // Keep t in 0-1 range
			vec3 color;
			
			if (t < 0.16667) {
				color = mix(vec3(1.0, 0.0, 1.0), vec3(0.0, 0.0, 1.0), t * 6.0);
			} else if (t < 0.33333) {
				color = mix(vec3(0.0, 0.0, 1.0), vec3(0.0, 1.0, 1.0), (t - 0.16667) * 6.0);
			} else if (t < 0.5) {
				color = mix(vec3(0.0, 1.0, 1.0), vec3(0.0, 1.0, 0.0), (t - 0.33333) * 6.0);
			} else if (t < 0.66667) {
				color = mix(vec3(0.0, 1.0, 0.0), vec3(1.0, 1.0, 0.0), (t - 0.5) * 6.0);
			} else if (t < 0.83333) {
				color = mix(vec3(1.0, 1.0, 0.0), vec3(1.0, 0.5, 0.0), (t - 0.66667) * 6.0);
			} else {
				color = mix(vec3(1.0, 0.5, 0.0), vec3(1.0, 0.0, 0.0), (t - 0.83333) * 6.0);
			}
			
			return color;
		}
		
		// Fresnel effect for view-dependent reflections
		float fresnel(float cosTheta, float f0) {
			return f0 + (1.0 - f0) * pow(1.0 - cosTheta, 5.0);
		}
		
		void fragment() {
			vec2 base_uv = UV;
			
			// Add subtle distortion using noise
			vec2 noise_uv = base_uv * noise_scale + TIME * 0.1;
			vec2 distortion = vec2(
				smooth_noise(noise_uv) - 0.5,
				smooth_noise(noise_uv + vec2(100.0, 100.0)) - 0.5
			) * distortion_strength;
			
			vec2 distorted_uv = base_uv + distortion;
			
			// Create animated foil pattern
			vec2 uv_scroll = distorted_uv * shimmer_scale + TIME * shimmer_speed * scroll_direction;
			
			// Multiple overlapping wave patterns for complexity
			float pattern1 = sin(uv_scroll.x * 2.0 + uv_scroll.y);
			float pattern2 = sin(uv_scroll.x - uv_scroll.y * 1.5 + TIME * 2.0);
			float pattern3 = sin((uv_scroll.x + uv_scroll.y) * 0.8 + TIME * 0.7);
			
			// Combine patterns
			float combined_pattern = (pattern1 + pattern2 * 0.7 + pattern3 * 0.5) / 2.2;
			combined_pattern = pow(abs(combined_pattern), foil_contrast);
			
			// Create rainbow colors
			float rainbow_offset = combined_pattern + TIME * 0.2;
			vec3 foil_color = rainbow(rainbow_offset) * rainbow_intensity;
			
			// Add sparkles
			if (enable_sparkles) {
				vec2 sparkle_uv = distorted_uv * sparkle_density * 10.0 + TIME * 0.5;
				float sparkle = smooth_noise(sparkle_uv);
				sparkle = step(0.98, sparkle) * (sin(TIME * 10.0 + sparkle * 100.0) * 0.5 + 0.5);
				foil_color += vec3(sparkle) * 2.0;
			}
			
			// View angle dependent effects
			vec3 view_dir = normalize(VIEW);
			float view_dot = dot(NORMAL, view_dir);
			float fresnel_factor = fresnel(abs(view_dot), 0.04);
			
			// Apply view angle effect
			foil_color *= mix(1.0, fresnel_factor * 2.0, view_angle_effect);
			
			// Set material properties
			ALBEDO = base_color.rgb;
			METALLIC = metallic;
			ROUGHNESS = roughness;
			EMISSION = foil_color * emission_strength;
			
			// Add some specular highlighting based on the foil pattern
			SPECULAR = mix(0.5, 1.0, combined_pattern * 0.5 + 0.5);
		}
	"""
	
	var shader = Shader.new()
	shader.code = shader_code
	var shader_mat = ShaderMaterial.new()
	shader_mat.shader = shader
	
	# Set default parameters for optimal foil effect
	shader_mat.set_shader_parameter("base_color", Color(0.95, 0.95, 0.95, 1.0))
	shader_mat.set_shader_parameter("metallic", 0.8)
	shader_mat.set_shader_parameter("roughness", 0.1)
	shader_mat.set_shader_parameter("shimmer_speed", 1.5)
	shader_mat.set_shader_parameter("shimmer_scale", 8.0)
	shader_mat.set_shader_parameter("emission_strength", 1.5)
	shader_mat.set_shader_parameter("rainbow_intensity", 1.2)
	shader_mat.set_shader_parameter("foil_contrast", 1.8)
	shader_mat.set_shader_parameter("noise_scale", 15.0)
	shader_mat.set_shader_parameter("distortion_strength", 0.1)
	shader_mat.set_shader_parameter("scroll_direction", Vector2(1.0, 0.3))
	shader_mat.set_shader_parameter("enable_sparkles", true)
	shader_mat.set_shader_parameter("sparkle_density", 2.0)
	shader_mat.set_shader_parameter("view_angle_effect", 0.8)
	
	# Preserve original material color if available
	if original_material and original_material.has_method("get"):
		var base = original_material.get("albedo_color")
		if base:
			shader_mat.set_shader_parameter("base_color", base)
	
	mesh_instance.material_override = shader_mat

func _on_player_entered(body):
	if body.is_in_group("player") and not is_being_carried:
		highlight(true)

func _on_player_exited(body):
	if body.is_in_group("player") and not is_being_carried:
		highlight(false)

func highlight(enable: bool):
	if not mesh_instance:
		return
		
	is_highlighted = enable
	if enable:
		mesh_instance.material_overlay = outline_material
	else:
		mesh_instance.material_overlay = null

func pickup():
	is_being_carried = true
	highlight(false)
	
	# Switch to kinematic mode for smooth carrying
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = true
	
	# Clear any existing velocities
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	
	# Change collision settings for carried state
	collision_layer = 0  # Disable collision with world
	collision_mask = 0   # Don't collide with anything
	
	# Disable pickup area while carried
	if pickup_area:
		pickup_area.monitoring = false
	
	item_picked_up.emit(self)

func drop():
	is_being_carried = false
	
	# Switch back to rigid body mode BEFORE unfreezing
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	freeze = false
	
	# Restore collision settings
	collision_layer = 1  # Re-enable collision
	collision_mask = 1   # Can collide with world again
	
	# Re-enable pickup area
	if pickup_area:
		pickup_area.monitoring = true
	
	# Add slight downward velocity for natural drop (after unfreezing)
	await get_tree().process_frame  # Wait one frame for physics to update
	linear_velocity = Vector3(0, -1, 0)
	
	item_dropped.emit(self)

func get_point_value() -> int:
	var base_points = item_data.point_value if item_data else 10
	if item_data and item_data.is_shiny:
		base_points = int(base_points * item_data.shiny_multiplier)
	return base_points
