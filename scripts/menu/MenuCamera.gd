extends Camera3D

@export var target: Node3D  # The object to orbit around
@export var orbit_speed: float = 30.0  # Degrees per second
@export var orbit_radius: float = 5.0  # Distance from target
@export var orbit_height: float = 2.0  # Height above target

var angle: float = 0.0

func _ready():
	# If no target is set, try to find one automatically
	if not target:
		var potential_targets = get_tree().get_nodes_in_group("orbit_target")
		if potential_targets.size() > 0:
			target = potential_targets[0]
		else:
			push_warning("No orbit target found. Add a Node3D to the 'orbit_target' group or assign one manually.")

func _process(delta):
	if not target:
		return
	
	# Update orbit angle
	angle += orbit_speed * delta
	if angle >= 360.0:
		angle -= 360.0
	
	# Calculate new position
	var radians = deg_to_rad(angle)
	var target_pos = target.global_position
	
	var new_pos = Vector3(
		target_pos.x + cos(radians) * orbit_radius,
		target_pos.y + orbit_height,
		target_pos.z + sin(radians) * orbit_radius
	)
	
	# Set camera position and look at target
	global_position = new_pos
	look_at(target_pos, Vector3.UP)
