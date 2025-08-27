extends Node
class_name ItemInteractionSystem

@export var interaction_range: float = 3.0
@export var carry_distance: float = 2.0
@export var carry_height_offset: float = -0.5
@export var player: FirstPersonController
@export var camera: Camera3D
@export var tooltip_scene: PackedScene  # Assign the ItemTooltip scene here

var carried_item: PickupableItem = null
var highlighted_item: PickupableItem = null
var tooltip: ItemTooltip = null
var tooltip_delay_timer: Timer

@export var dropitemAudio: AudioStream

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
	
	# Setup tooltip
	setup_tooltip()
	
	# Setup tooltip delay timer
	tooltip_delay_timer = Timer.new()
	tooltip_delay_timer.wait_time = 0.25  # Quartar second delay before showing tooltip
	tooltip_delay_timer.one_shot = true
	tooltip_delay_timer.timeout.connect(_on_tooltip_delay_timeout)
	add_child(tooltip_delay_timer)
	
	print("ItemInteractionSystem ready")

func setup_tooltip():
	if tooltip_scene:
		tooltip = tooltip_scene.instantiate()
		# Defer adding tooltip to avoid "busy setting up children" error
		setup_tooltip_deferred.call_deferred()
	else:
		print("WARNING: Tooltip scene not assigned in ItemInteractionSystem!")

func setup_tooltip_deferred():
	if not tooltip:
		return
		
	# Add tooltip to the main scene's UI layer
	var main_scene = get_tree().current_scene
	if main_scene.has_method("get_ui_layer"):
		main_scene.get_ui_layer().add_child(tooltip)
	else:
		# Fallback: add to current scene
		get_tree().current_scene.add_child(tooltip)

func _input(event):
	if event.is_action_pressed("interact"):
		if carried_item:
			drop_item()
		else:
			pickup_item()
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			carry_distance = clamp(carry_distance + 0.2, 0.5, 5.0)
			print("Carry distance:", carry_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			carry_distance = clamp(carry_distance - 0.2, 0.5, 5.0)
			print("Carry distance:", carry_distance)

func _physics_process(delta):
	# Add null checks
	if not is_setup_valid():
		return
		
	update_item_detection()
	update_carried_item_position()
	update_tooltip_position()

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
	
	# Update highlighting and tooltip
	if highlighted_item != new_highlighted:
		# Hide old tooltip and cancel timer
		hide_tooltip()
		tooltip_delay_timer.stop()
		
		# Remove highlighting from old item
		if highlighted_item != null and is_instance_valid(highlighted_item):
			highlighted_item.highlight(false)
		
		# Set new highlighted item
		highlighted_item = new_highlighted
		
		# Highlight new item and start tooltip timer
		if highlighted_item != null and is_instance_valid(highlighted_item) and not highlighted_item.is_being_carried:
			highlighted_item.highlight(true)
			# Start tooltip delay timer
			tooltip_delay_timer.start()

func _on_tooltip_delay_timeout():
	# Show tooltip for currently highlighted item
	if highlighted_item != null and is_instance_valid(highlighted_item) and not highlighted_item.is_being_carried:
		show_tooltip_for_item(highlighted_item)

func show_tooltip_for_item(item: PickupableItem):
	if not tooltip or not item or not item.item_data:
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	tooltip.show_tooltip(item.item_data, mouse_pos)

func hide_tooltip():
	if tooltip:
		tooltip.hide_tooltip()

func update_tooltip_position():
	# Update tooltip position to follow mouse if it's visible
	if tooltip and tooltip.is_visible:
		var mouse_pos = get_viewport().get_mouse_position()
		tooltip.position_tooltip(mouse_pos)

func pickup_item():
	if highlighted_item != null and is_instance_valid(highlighted_item) and not highlighted_item.is_being_carried and carried_item == null:
		# Hide tooltip when picking up
		hide_tooltip()
		tooltip_delay_timer.stop()
		
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
	
	carried_item = null
	AudioManager.play_sfx(dropitemAudio)

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
