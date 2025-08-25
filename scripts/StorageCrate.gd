extends StaticBody3D
class_name StorageCrate

@export var max_capacity: int = 20
@onready var storage_area: Area3D = $StorageArea
@onready var item_container: Node3D = $ItemContainer
@onready var ui_label: Label3D = $UILabel

var stored_items: Array[PickupableItem] = []
var is_player_nearby: bool = false

signal items_stored_changed(count: int)

func _ready():
	storage_area.body_entered.connect(_on_player_entered)
	storage_area.body_exited.connect(_on_player_exited)
	update_ui()

func _on_player_entered(body):
	if body is FirstPersonController:
		is_player_nearby = true

func _on_player_exited(body):
	if body is FirstPersonController:
		is_player_nearby = false

func can_store_item() -> bool:
	return stored_items.size() < max_capacity

func store_item(item: PickupableItem) -> bool:
	if not can_store_item():
		return false
	
	stored_items.append(item)
	item.get_parent().remove_child(item)
	item_container.add_child(item)
	
	# Position item in crate (simple stacking)
	var stack_height = stored_items.size() * 0.3
	item.position = Vector3(0, stack_height, 0)
	item.freeze = true
	
	update_ui()
	items_stored_changed.emit(stored_items.size())
	return true

func remove_all_items() -> Array[PickupableItem]:
	var items = stored_items.duplicate()
	stored_items.clear()
	
	for item in items:
		item_container.remove_child(item)
	
	update_ui()
	items_stored_changed.emit(0)
	return items

func get_stored_count() -> int:
	return stored_items.size()

func update_ui():
	if ui_label:
		ui_label.text = "Storage: %d/%d" % [stored_items.size(), max_capacity]
