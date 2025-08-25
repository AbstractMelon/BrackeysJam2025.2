extends Node
class_name ItemInteractionSystem

@export var interaction_range: float = 3.0
@export var carry_distance: float = 2.0
@export var carry_height_offset: float = -0.5
@export var player: FirstPersonController
@export var camera: Camera3D

var carried_item: PickupableItem = null
var highlighted_item: PickupableItem = null

func _ready():
	# Validate that references are set
	if player == null:
		print("ERROR: Player not assigned in ItemInteractionSystem!")
		return
	if camera == null:
		print("ERROR: Camera not assigned in ItemInteractionSystem!")
		return
	
	# Add to player group for identification
	player.add_to_group("player")
	print("ItemInteractionSystem ready")

func _input(event):
	if event.is_action_pressed("interact"):
		if carried_item:
			drop_item()
		else:
			pickup_item()

func _physics_process(delta):
	# Add null checks
	if not is_setup_valid():
		return
		
	update_item_detection()
	update_carried_item_position()

func is_setup_valid() -> bool:
	return player != null and camera != null and is_instance_valid(player) and is_instance_valid(camera)

func update_item_detection():
	if not is_setup_valid():
		return
		
	var space_state = player.get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from + camera.global_transform.basis.z * -interaction_range
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	# Make sure we hit items by including their collision layers
	query.collision_mask = 1  # Layer 1 for items
	var result = space_state.intersect_ray(query)
	
	var new_highlighted: PickupableItem = null
	
	if result:
		var collider = result.get("collider")
		# Try direct check first
		if collider is PickupableItem:
			new_highlighted = collider
		# Then check parent
		elif collider != null and collider.get_parent() is PickupableItem:
			new_highlighted = collider.get_parent()
		# Also check if the collider has a PickupableItem ancestor
		elif collider != null:
			var current_node = collider
			while current_node != null:
				if current_node is PickupableItem:
					new_highlighted = current_node
					break
				current_node = current_node.get_parent()
	
	# Update highlighting
	if highlighted_item != new_highlighted:
		if highlighted_item != null and is_instance_valid(highlighted_item):
			highlighted_item.highlight(false)
		highlighted_item = new_highlighted
		if highlighted_item != null and is_instance_valid(highlighted_item) and not highlighted_item.is_being_carried:
			highlighted_item.highlight(true)

func pickup_item():
	if highlighted_item != null and is_instance_valid(highlighted_item) and not highlighted_item.is_being_carried and carried_item == null:
		carried_item = highlighted_item
		carried_item.pickup()

func drop_item():
	if carried_item == null or not is_instance_valid(carried_item):
		carried_item = null
		return
	
	# Position item properly before dropping
	if is_setup_valid():
		var drop_position = camera.global_position + camera.global_transform.basis.z * -2.0
		# Make sure we're not dropping inside the ground
		drop_position.y = max(drop_position.y, player.global_position.y)
		carried_item.global_position = drop_position
	
	# Drop the item (this handles physics state changes)
	carried_item.drop()
	
	# Check if dropping into storage crate
	var nearby_crate = find_nearby_storage_crate()
	if nearby_crate != null and nearby_crate.can_store_item():
		nearby_crate.store_item(carried_item)
	
	carried_item = null

func update_carried_item_position():
	if carried_item == null or not is_instance_valid(carried_item) or not is_setup_valid():
		return
	
	# Only update position if item is actually being carried
	if not carried_item.is_being_carried:
		return
		
	var target_position = camera.global_position + camera.global_transform.basis.z * -carry_distance
	target_position.y += carry_height_offset
	
	# Use smooth interpolation for better feel
	var current_pos = carried_item.global_position
	var smooth_pos = current_pos.lerp(target_position, 15.0 * get_process_delta_time())
	carried_item.global_position = smooth_pos

func find_nearby_storage_crate() -> StorageCrate:
	if not is_setup_valid():
		return null
		
	var crates = get_tree().get_nodes_in_group("storage_crates")
	for crate in crates:
		if crate is StorageCrate and is_instance_valid(crate):
			var distance = player.global_position.distance_to(crate.global_position)
			if distance < 3.0 and crate.is_player_nearby:
				return crate
	return null
