extends Node3D
class_name TestCrateSpawner

@export var crate_scene: PackedScene = preload("res://scenes/components/crate.tscn")
@export var spawn_position: Vector3 = Vector3(0, 1, 0)

func _ready():
	# Wait a moment for the scene to be fully loaded
	await get_tree().create_timer(1.0).timeout
	spawn_test_crate()

func spawn_test_crate():
	if not crate_scene:
		print("[TestCrateSpawner] No crate scene assigned!")
		return

	var crate_instance = crate_scene.instantiate()
	get_parent().add_child(crate_instance)
	crate_instance.global_position = spawn_position

	print("[TestCrateSpawner] Spawned test crate at position: ", spawn_position)

	# Connect to crate signals for debugging
	if crate_instance.has_signal("item_stored"):
		crate_instance.item_stored.connect(_on_item_stored)
	if crate_instance.has_signal("item_removed"):
		crate_instance.item_removed.connect(_on_item_removed)
	if crate_instance.has_signal("crate_dumped"):
		crate_instance.crate_dumped.connect(_on_crate_dumped)

func _on_item_stored(item: PickupableItem):
	print("[TestCrateSpawner] Item stored in crate: ", item.item_data.item_name if item.item_data else "Unknown")

func _on_item_removed(item: PickupableItem):
	print("[TestCrateSpawner] Item removed from crate: ", item.item_data.item_name if item.item_data else "Unknown")

func _on_crate_dumped(items: Array):
	print("[TestCrateSpawner] Crate dumped with ", items.size(), " items")
