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
		// base color (tint underneath the foil)
		uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
		// controls
		uniform float shimmer_speed = 1.5;
		uniform float shimmer_scale = 6.0;
		uniform float emission_strength = 1.2;
		
		vec3 rainbow(float t) {
			// simple rainbow palette
			return vec3(
				0.5 + 0.5 * cos(6.2831 * (t + 0.0)),
				0.5 + 0.5 * cos(6.2831 * (t + 0.33)),
				0.5 + 0.5 * cos(6.2831 * (t + 0.66))
			);
		}
		
		void fragment() {
			// animated UV distortion
			vec2 uv_scroll = UV * shimmer_scale + vec2(TIME * shimmer_speed, TIME * 0.5 * shimmer_speed);
			// make foil bands
			float bands = sin(uv_scroll.x + uv_scroll.y) * 0.5 + 0.5;
			// map to rainbow
			vec3 foil_color = rainbow(bands);
			ALBEDO = base_color.rgb;
			EMISSION = foil_color * emission_strength;
		}
	"""
	var shader = Shader.new()
	shader.code = shader_code
	var shader_mat = ShaderMaterial.new()
	shader_mat.shader = shader
	# keep original tint if possible
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
