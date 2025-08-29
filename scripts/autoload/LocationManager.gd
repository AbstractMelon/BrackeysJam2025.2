extends Node

signal location_selected(location_scene: PackedScene)
signal teleport_started()
signal teleport_completed()

var available_locations: Array[PackedScene] = []
var current_location: Node3D = null
var main_kitchen_scene: PackedScene = preload("res://scenes/kitchen.tscn")
var player: Node3D = null
var player_crate: Node3D = null

func _ready():
	# Load all location scenes from the locations folder
	_load_available_locations()

func _load_available_locations():
	available_locations.clear()
	var dir = DirAccess.open("res://scenes/locations/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tscn"):
				var location_scene = load("res://scenes/locations/" + file_name)
				if location_scene:
					available_locations.append(location_scene)
					print("[LocationManager] Loaded location: ", file_name)
			file_name = dir.get_next()
		dir.list_dir_end()

	print("[LocationManager] Total locations loaded: ", available_locations.size())

func get_random_locations(count: int) -> Array[PackedScene]:
	if available_locations.is_empty():
		print("[LocationManager] No locations available!")
		return []

	var shuffled = available_locations.duplicate()
	shuffled.shuffle()
	return shuffled.slice(0, min(count, shuffled.size()))

func teleport_to_location(location_scene: PackedScene):
	print("[LocationManager] teleport_to_location called with scene: ", location_scene.resource_path if location_scene else "null")
	
	if not location_scene:
		print("[LocationManager] Invalid location scene!")
		return

	teleport_started.emit()

	# Store reference to player and their crate
	player = get_tree().get_first_node_in_group("player")
	print("[LocationManager] Player found: ", player != null)
	
	player_crate = _find_player_crate()
	print("[LocationManager] Player crate found: ", player_crate != null)

	# Fade to black
	print("[LocationManager] Starting fade to black")
	await _fade_screen(true)

	# Load new location
	print("[LocationManager] Loading new location: ", location_scene.resource_path)
	_load_location(location_scene)

	# Fade back in
	print("[LocationManager] Starting fade from black")
	await _fade_screen(false)

	print("[LocationManager] Teleport completed successfully to: ", location_scene.resource_path)
	teleport_completed.emit()

func return_to_kitchen():
	print("[LocationManager] return_to_kitchen called")
	
	if not main_kitchen_scene:
		print("[LocationManager] Main kitchen scene not found!")
		return

	teleport_started.emit()

	# Store player and crate references
	player = get_tree().get_first_node_in_group("player")
	print("[LocationManager] Player found: ", player != null)
	
	player_crate = _find_player_crate()
	print("[LocationManager] Player crate found: ", player_crate != null)

	# Fade to black
	print("[LocationManager] Starting fade to black")
	await _fade_screen(true)

	# Load kitchen scene
	print("[LocationManager] Loading kitchen scene: ", main_kitchen_scene.resource_path)
	_load_location(main_kitchen_scene)

	# Fade back in
	print("[LocationManager] Starting fade from black")
	await _fade_screen(false)

	print("[LocationManager] Return to kitchen completed")
	teleport_completed.emit()

func _find_player_crate() -> Node3D:
	print("[LocationManager] Looking for player crate")
	
	# Look for a crate being carried by the player
	var interaction_system = get_tree().get_first_node_in_group("item_interaction")
	if interaction_system and interaction_system.has_method("get_carried_item"):
		var carried_item = interaction_system.get_carried_item()
		if carried_item and carried_item.has_method("is_crate") and carried_item.is_crate():
			print("[LocationManager] Found crate being carried by player")
			return carried_item

	# Look for crates in the scene
	var crates = get_tree().get_nodes_in_group("crates")
	print("[LocationManager] Found ", crates.size(), " crates in scene")
	
	for crate in crates:
		if crate.has_method("belongs_to_player") and crate.belongs_to_player():
			print("[LocationManager] Found crate belonging to player")
			return crate

	print("[LocationManager] No player crate found")
	return null

func _load_location(location_scene: PackedScene):
	print("[LocationManager] _load_location called with: ", location_scene.resource_path)
	print("[LocationManager] Current location before loading: ", current_location.name if current_location else "null")
	
	# Store player reference before clearing scene
	if not player:
		player = get_tree().get_first_node_in_group("player")
		print("[LocationManager] Player re-acquired: ", player != null)

	# Remove player from current scene but don't free it
	var player_parent = null
	if player:
		player_parent = player.get_parent()
		if player_parent:
			print("[LocationManager] Removing player from parent: ", player_parent.name)
			player_parent.remove_child(player)
		else:
			print("[LocationManager] Player has no parent")

	# Find the location container in the main scene
	var main_scene = get_tree().current_scene
	print("[LocationManager] Current scene: ", main_scene.name if main_scene else "null")
	
	var location_container = main_scene.get_node_or_null("LocationContainer")
	
	if not location_container:
		push_error("[LocationManager] LocationContainer not found in main scene!")
		print("[LocationManager] Available nodes in main scene:")
		for child in main_scene.get_children():
			print("  - ", child.name)
		return
	
	print("[LocationManager] Found LocationContainer: ", location_container.name)
	
	# Clear ALL existing locations from container, not just current_location
	print("[LocationManager] Clearing all locations from container")
	var children_to_remove = []
	for child in location_container.get_children():
		# Check if this child is a location (has 3D nodes or specific properties)
		if child is Node3D:  
			print("[LocationManager] Removing location from container: ", child.name)
			children_to_remove.append(child)
	
	# Remove children after iteration to avoid modification during iteration
	for child in children_to_remove:
		location_container.remove_child(child)
		child.queue_free()
	
	print("[LocationManager] Location container cleared. Remaining children: ", location_container.get_children().size())

	# Load new location and add to container
	print("[LocationManager] Instantiating new location")
	var new_location = location_scene.instantiate()
	print("[LocationManager] New location instantiated: ", new_location.name)
	
	location_container.add_child(new_location)
	current_location = new_location
	print("[LocationManager] New location added to container: ", current_location.name)

	# Add player to new location
	if player:
		print("[LocationManager] Adding player to new location")
		current_location.add_child(player)
		_position_player_in_location()
	else:
		print("[LocationManager] No player to add to location")

	# Move crate to location if it exists
	_position_crate_in_location()
	
	print("[LocationManager] Location loading complete: ", location_scene.resource_path)

func _position_player_in_location():
	if not player:
		print("[LocationManager] Cannot position player - no player reference")
		return

	# Look for spawn point in the new location
	var spawn_point = current_location.get_node_or_null("PlayerSpawn")
	if spawn_point:
		print("[LocationManager] Found spawn point: ", spawn_point.global_position)
		player.global_position = spawn_point.global_position
		print("[LocationManager] Player positioned at spawn point: ", spawn_point.global_position)
	else:
		# Default position
		print("[LocationManager] No spawn point found, using default position")
		player.global_position = Vector3(0, 1, 0)
		print("[LocationManager] Player positioned at default location: ", player.global_position)

func _position_crate_in_location():
	if not player_crate:
		print("[LocationManager] No crate to position")
		return

	print("[LocationManager] Positioning crate in new location")
	
	# Position crate near player
	var crate_position = player.global_position + Vector3(2, 0, 0)
	player_crate.global_position = crate_position

	# Re-parent crate to new scene if needed
	var crate_parent = player_crate.get_parent()
	if crate_parent and crate_parent != current_location:
		print("[LocationManager] Re-parenting crate from ", crate_parent.name, " to ", current_location.name)
		crate_parent.remove_child(player_crate)
		current_location.add_child(player_crate)
	else:
		print("[LocationManager] Crate already in correct parent")

	print("[LocationManager] Crate positioned in new location at: ", crate_position)

func _fade_screen(fade_in: bool) -> void:
	print("[LocationManager] _fade_screen: ", "fade_in" if fade_in else "fade_out")
	
	var overlay = ColorRect.new()
	overlay.color = Color.BLACK
	overlay.color.a = 1.0 if fade_in else 0.0
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 1000  # Ensure it's on top

	# Add to current scene's UI layer or root
	var ui_parent = _get_ui_parent()
	print("[LocationManager] UI parent found: ", ui_parent.name if ui_parent else "null")
	
	ui_parent.add_child(overlay)

	# Animate fade
	var tween = create_tween()
	var target_alpha = 0.0 if fade_in else 1.0
	tween.tween_property(overlay, "color:a", target_alpha, 0.5)
	await tween.finished

	# Clean up if fading out
	if not fade_in:
		print("[LocationManager] Removing fade overlay")
		overlay.queue_free()
	else:
		print("[LocationManager] Fade overlay complete")

func _get_ui_parent() -> Node:
	var current_scene = get_tree().current_scene
	print("[LocationManager] Looking for UI parent in scene: ", current_scene.name if current_scene else "null")

	# Try to find UI layer
	var ui_layer = current_scene.get_node_or_null("UI")
	if ui_layer:
		print("[LocationManager] Found UI layer: ", ui_layer.name)
		return ui_layer

	# Try to find Canvas layer
	var canvas = current_scene.get_node_or_null("CanvasLayer")
	if canvas:
		print("[LocationManager] Found CanvasLayer: ", canvas.name)
		return canvas

	# Fallback to current scene
	print("[LocationManager] Using current scene as UI parent")
	return current_scene

func is_in_location() -> bool:
	var result = current_location != null and current_location.scene_file_path != main_kitchen_scene.resource_path
	print("[LocationManager] is_in_location: ", result)
	return result

func get_current_location_name() -> String:
	if not current_location:
		print("[LocationManager] get_current_location_name: Kitchen (no current location)")
		return "Kitchen"

	var scene_path = current_location.scene_file_path
	if scene_path.is_empty():
		print("[LocationManager] get_current_location_name: Unknown Location (empty scene path)")
		return "Unknown Location"

	var file_name = scene_path.get_file().get_basename()
	var result = file_name.capitalize().replace("_", " ")
	print("[LocationManager] get_current_location_name: ", result)
	return result
