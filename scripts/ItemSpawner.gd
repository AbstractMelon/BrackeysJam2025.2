extends Node3D
class_name ItemSpawner

@export var spawn_radius: float = 10.0
@export var max_items: int = 15
@export var spawn_interval: float = 5.0
@export var available_items: Array[ItemData] = []

@onready var spawn_timer: Timer = $SpawnTimer
var pickupable_item_scene: PackedScene = preload("res://scenes/pickupable_item.tscn")
var active_items: Array[PickupableItem] = []

func _ready():
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()
	
	# Defer initial spawn to ensure scene is fully ready
	call_deferred("spawn_initial_items")

func spawn_initial_items():
	for i in range(max_items / 2):
		spawn_random_item()

func _on_spawn_timer_timeout():
	if not is_inside_tree():
		spawn_timer.stop() # Prevent it from firing again.
		return

	if active_items.size() < max_items:
		spawn_random_item()

func spawn_random_item():
	if available_items.is_empty():
		return
	
	var item_data = available_items[randi() % available_items.size()]
	
	# Check if should be shiny
	if GameManager.should_spawn_shiny_item():
		item_data = create_shiny_variant(item_data)
	
	var spawn_position = get_random_spawn_position()
	spawn_item(item_data, spawn_position)

func create_shiny_variant(base_data: ItemData) -> ItemData:
	var shiny_data = base_data.duplicate()
	shiny_data.is_shiny = true
	shiny_data.item_name = "Shiny " + shiny_data.item_name
	return shiny_data

func get_random_spawn_position() -> Vector3:
	# Add safety check
	if not is_inside_tree():
		print("Warning: ItemSpawner not in tree when getting spawn position")
		return Vector3.ZERO
	
	var angle = randf() * TAU
	var distance = randf() * spawn_radius
	var x = cos(angle) * distance
	var z = sin(angle) * distance
	
	# Raycast down to find ground
	var space_state = get_world_3d().direct_space_state
	var from = global_position + Vector3(x, 20, z)
	var to = global_position + Vector3(x, -20, z)
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)
	
	var y_position = 0.0
	if result:
		y_position = result.position.y + 1.0
	
	return Vector3(x, y_position, z) + global_position

func spawn_item(item_data: ItemData, position: Vector3):
	var item_instance = pickupable_item_scene.instantiate()
	
	if is_inside_tree():
		return
		
	item_instance.item_data = item_data
	item_instance.global_position = position
	
	# Connect signals
	item_instance.item_picked_up.connect(_on_item_picked_up)
	item_instance.item_dropped.connect(_on_item_dropped)
	
	# Use call_deferred to avoid the "busy setting up children" error
	get_parent().call_deferred("add_child", item_instance)
	active_items.append(item_instance)

func _on_item_picked_up(item: PickupableItem):
	# Item picked up - could trigger effects
	pass

func _on_item_dropped(item: PickupableItem):
	# Item dropped - could trigger effects
	pass

func remove_item(item: PickupableItem):
	if item in active_items:
		active_items.erase(item)
		
func _exit_tree():
	spawn_timer.stop()
