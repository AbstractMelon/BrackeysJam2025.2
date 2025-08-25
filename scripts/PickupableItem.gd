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
	if item_data:
		setup_item()
	
	# Setup pickup area
	pickup_area.body_entered.connect(_on_player_entered)
	pickup_area.body_exited.connect(_on_player_exited)
	
	# Create outline material for highlighting
	outline_material = StandardMaterial3D.new()
	outline_material.flags_unshaded = true
	outline_material.albedo_color = Color.YELLOW
	outline_material.flags_do_not_receive_shadows = true
	outline_material.flags_disable_ambient_light = true

func setup_item():
	if not item_data:
		return
	
	# Apply mesh and material
	if item_data.mesh:
		mesh_instance.mesh = item_data.mesh
	
	if item_data.material:
		mesh_instance.material_override = item_data.material
		original_material = item_data.material
	
	# Handle shiny items
	if item_data.is_shiny:
		add_shiny_effect()

func add_shiny_effect():
	# Add a simple glowing effect for shiny items
	var glow_material = StandardMaterial3D.new()
	glow_material.emission_enabled = true
	glow_material.emission = Color.GOLD
	glow_material.emission_energy = 0.5
	if original_material:
		glow_material.albedo_color = original_material.albedo_color if original_material.has_method("get") else Color.WHITE
	mesh_instance.material_override = glow_material

func _on_player_entered(body):
	if body is FirstPersonController and not is_being_carried:
		highlight(true)

func _on_player_exited(body):
	if body is FirstPersonController and not is_being_carried:
		highlight(false)

func highlight(enable: bool):
	is_highlighted = enable
	if enable:
		mesh_instance.material_overlay = outline_material
	else:
		mesh_instance.material_overlay = null

func pickup():
	is_being_carried = true
	freeze = true
	highlight(false)
	collision_layer = 0  # Disable collision with world
	item_picked_up.emit(self)

func drop():
	is_being_carried = false
	freeze = false
	collision_layer = 1  # Re-enable collision
	item_dropped.emit(self)

func get_point_value() -> int:
	var base_points = item_data.point_value if item_data else 10
	if item_data and item_data.is_shiny:
		base_points = int(base_points * item_data.shiny_multiplier)
	return base_points
