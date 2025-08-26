extends Node3D
class_name ItemSpawner

@export var spawn_radius: float = 10.0
@export var max_items: int = 15
@export var spawn_interval: float = 5.0
@export var available_items: Array[ItemData] = []

@onready var spawn_timer: Timer = $SpawnTimer
var pickupable_item_scene: PackedScene = preload("res://scenes/components/pickupable_item.tscn")
var active_items: Array[PickupableItem] = []
var round_spawning: bool = false

func _ready():
	add_to_group("item_spawner")
	print("[ItemSpawner] Ready. Radius:", spawn_radius, " Max:", max_items, " Interval:", spawn_interval)
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

	# Don't auto-start timer - wait for game loop
	call_deferred("_setup_for_game_loop")

func _setup_for_game_loop():
	# Initial spawn only if not in round-based mode
	if not round_spawning:
		spawn_timer.start()
		spawn_initial_items()

func spawn_initial_items():
	print("[ItemSpawner] Spawning initial items...")
	for i in range(max_items / 2):
		spawn_random_item()
	print("[ItemSpawner] Initial spawn complete. Active items:", active_items.size())

func spawn_items_for_round(item_count: int, difficulty: float):
	print("[ItemSpawner] Spawning ", item_count, " items for round with difficulty ", difficulty)
	round_spawning = true
	spawn_timer.stop()

	# Clear existing items
	clear_all_items()

	# Wait until we're properly in the tree before spawning
	_wait_for_tree_ready(item_count, difficulty)

func _wait_for_tree_ready(item_count: int, difficulty: float):
	if not is_inside_tree() or not is_node_ready():
		# Wait one more frame
		await get_tree().process_frame
		_wait_for_tree_ready(item_count, difficulty)
		return
	
	_spawn_round_items(item_count, difficulty)

func _spawn_round_items(item_count: int, difficulty: float):
	# Adjust spawn parameters based on difficulty
	var adjusted_max_items = int(item_count * difficulty)
	var adjusted_spawn_interval = spawn_interval / difficulty

	# Spawn initial batch for round
	for i in range(min(adjusted_max_items, item_count)):
		spawn_random_item()

	# Set up continuous spawning for round
	spawn_timer.wait_time = adjusted_spawn_interval
	max_items = adjusted_max_items
	spawn_timer.start()

func clear_all_items():
	for item in active_items:
		if is_instance_valid(item):
			item.queue_free()
	active_items.clear()

func _on_spawn_timer_timeout():
	if active_items.size() < max_items:
		spawn_random_item()
	else:
		#print("[ItemSpawner] Max items reached, skipping spawn")
		pass

func spawn_random_item():
	if not is_inside_tree():
		print("[ItemSpawner] Cannot spawn item: not in tree")
		return
		
	if available_items.is_empty():
		print("[ItemSpawner] No available items to spawn")
		return

	var item_data = available_items[randi() % available_items.size()]
	print("[ItemSpawner] Selected item: ", item_data.item_name)

	# Check if should be shiny
	if GameManager.should_spawn_shiny_item():
		item_data = create_shiny_variant(item_data)
		print("[ItemSpawner] Shiny variant created: ", item_data.item_name)

	var spawn_position = get_random_spawn_position()
	spawn_item(item_data, spawn_position)

func create_shiny_variant(base_data: ItemData) -> ItemData:
	var shiny_data = base_data.duplicate()
	shiny_data.is_shiny = true
	shiny_data.item_name = "Shiny " + shiny_data.item_name
	return shiny_data

func get_random_spawn_position() -> Vector3:
	if not is_inside_tree():
		print("[ItemSpawner] Warning: not in tree when getting spawn position")
		return Vector3.ZERO

	var angle = randf() * TAU
	var distance = randf() * spawn_radius
	var x = cos(angle) * distance
	var z = sin(angle) * distance

	var space_state = get_world_3d().direct_space_state
	var from = global_position + Vector3(x, 20, z)
	var to = global_position + Vector3(x, -20, z)

	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)

	var y_position = 0.0
	if result:
		y_position = result.position.y + 1.0
	else:
		print("[ItemSpawner] Raycast missed ground at XZ:", x, z, " using fallback Y=0")

	return Vector3(x, y_position, z) + global_position

func spawn_item(item_data: ItemData, position: Vector3):
	if not is_inside_tree():
		print("[ItemSpawner] Cannot spawn item: not in tree")
		return

	var item_instance = pickupable_item_scene.instantiate()
	item_instance.item_data = item_data
	
	# Connect signals
	item_instance.item_picked_up.connect(_on_item_picked_up)
	item_instance.item_dropped.connect(_on_item_dropped)

	# Add to parent first, then set position
	get_parent().add_child(item_instance)
	item_instance.global_position = position
	
	active_items.append(item_instance)
	print("[ItemSpawner] Spawned item:", item_data.item_name, " at", position, " Active items:", active_items.size())

func _on_item_picked_up(item: PickupableItem):
	pass

func _on_item_dropped(item: PickupableItem):
	pass

func remove_item(item: PickupableItem):
	if item in active_items:
		active_items.erase(item)
		print("[ItemSpawner] Removed item:", item.item_data.item_name, " Active items:", active_items.size())

func stop_round_spawning():
	round_spawning = false
	spawn_timer.stop()

func _exit_tree():
	spawn_timer.stop()
