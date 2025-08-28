extends PickupableItem
class_name Crate

signal item_stored(item: PickupableItem)
signal item_removed(item: PickupableItem)
signal crate_dumped(items: Array[PickupableItem])

@export var max_capacity: int = 10
@export var storage_ui_scene: PackedScene 

var stored_items: Array[PickupableItem] = []
var is_open: bool = false
var player_owner: bool = true  

@onready var storage_indicator: Label3D = $StorageIndicator

func _ready():
	super._ready()
	add_to_group("crates")

	if item_data:
		item_data.zone_type = ItemData.Zones.UTILITY
		
	# Create storage indicator
	if not storage_indicator:
		storage_indicator = Label3D.new()
		add_child(storage_indicator)
		storage_indicator.position = Vector3(0, 1.5, 0)
		storage_indicator.billboard = BaseMaterial3D.BILLBOARD_ENABLED

	_update_storage_indicator()

func _input(event):
	if event.is_action_pressed("dump_crate"):
		# Dump all contents
		dump_contents()

	# Only handle input if this crate is being carried
	if not is_being_carried:
		return

	if event.is_action_pressed("interact"):
		# Open/close crate when carried and interact is pressed
		toggle_crate()


func toggle_crate():
	is_open = !is_open
	print("[Crate] Crate ", "opened" if is_open else "closed")

	if is_open:
		_show_contents()
	else:
		_hide_contents()

func can_store_item(item: PickupableItem) -> bool:
	if not item:
		return false

	if stored_items.size() >= max_capacity:
		return false

	if item == self:  # Can't store itself
		return false

	if item.has_method("is_crate") and item.is_crate():  # Can't store other crates
		return false

	return true

func store_item(item: PickupableItem) -> bool:
	if not can_store_item(item):
		return false

	stored_items.append(item)

	# Hide the item visually
	item.visible = false
	item.freeze = true
	item.collision_layer = 0
	item.collision_mask = 0

	# Remove from scene temporarily
	if item.get_parent():
		item.get_parent().remove_child(item)

	_update_storage_indicator()
	item_stored.emit(item)

	print("[Crate] Stored item: ", item.item_data.item_name if item.item_data else "Unknown")
	return true

func remove_item(item: PickupableItem) -> bool:
	if item not in stored_items:
		return false

	stored_items.erase(item)

	# Restore item visibility and physics
	item.visible = true
	item.freeze = false
	item.collision_layer = 1
	item.collision_mask = 1

	# Add back to current scene
	get_tree().current_scene.add_child(item)
	item.global_position = global_position + Vector3(randf_range(-2, 2), 1, randf_range(-2, 2))

	_update_storage_indicator()
	item_removed.emit(item)

	print("[Crate] Removed item: ", item.item_data.item_name if item.item_data else "Unknown")
	return true

func dump_contents():
	if stored_items.is_empty():
		print("[Crate] No items to dump")
		return

	print("[Crate] Dumping ", stored_items.size(), " items")

	var dumped_items = stored_items.duplicate()
	var dump_position = global_position

	# Create a circle pattern for dumped items
	for i in range(stored_items.size()):
		var item = stored_items[i]
		var angle = (float(i) / float(stored_items.size())) * TAU
		var offset = Vector3(cos(angle) * 3, 1, sin(angle) * 3)

		# Restore item
		item.visible = true
		item.freeze = false
		item.collision_layer = 1
		item.collision_mask = 1

		# Add to scene
		if not item.get_parent():
			get_tree().current_scene.add_child(item)

		item.global_position = dump_position + offset

		# Add some upward velocity for dramatic effect
		if item is RigidBody3D:
			item.apply_impulse(Vector3(0, 5, 0))

	stored_items.clear()
	_update_storage_indicator()
	crate_dumped.emit(dumped_items)

func get_stored_items() -> Array[PickupableItem]:
	return stored_items.duplicate()

func get_storage_count() -> int:
	return stored_items.size()

func is_full() -> bool:
	return stored_items.size() >= max_capacity

func is_empty() -> bool:
	return stored_items.is_empty()

func is_crate() -> bool:
	return true

func belongs_to_player() -> bool:
	return player_owner

func _update_storage_indicator():
	if storage_indicator:
		var count_text = str(stored_items.size()) + "/" + str(max_capacity)
		storage_indicator.text = count_text

		# Change color based on fullness
		if stored_items.size() >= max_capacity:
			storage_indicator.modulate = Color.RED
		elif stored_items.size() > max_capacity * 0.7:
			storage_indicator.modulate = Color.YELLOW
		else:
			storage_indicator.modulate = Color.WHITE

func _show_contents():
	# Could implement a UI here to show stored items
	print("[Crate] Contents: ")
	for item in stored_items:
		if item and item.item_data:
			print("  - ", item.item_data.item_name)

func _hide_contents():
	# Hide any UI elements for contents
	pass

# Override pickup to handle stored items
func pickup():
	super.pickup()
	# Stored items travel with the crate
	print("[Crate] Picked up crate with ", stored_items.size(), " items")

# Override drop to mkae sure that stored items stay with crate
func drop():
	super.drop()
	print("[Crate] Dropped crate with ", stored_items.size(), " items")
	# Stored items remain stored

# Auto-pickup nearby items when crate is placed near them
func _on_crate_area_entered(body):
	if is_being_carried:
		return # Can't absorb items while carried
		
	if body is PickupableItem and body != self:
		if can_store_item(body) and not body.is_being_carried:
			# Auto-store items that touch the crate
			store_item(body)

func _on_area_3d_body_entered(body):
	_on_crate_area_entered(body)
