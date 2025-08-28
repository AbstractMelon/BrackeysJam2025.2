extends Node

signal location_selected(location_scene: PackedScene)
signal teleport_started()
signal teleport_completed()

var available_locations: Array[PackedScene] = []
var current_location: Node3D = null
var main_kitchen_scene: PackedScene = preload("res://scenes/game.tscn")
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
	if not location_scene:
		print("[LocationManager] Invalid location scene!")
		return

	teleport_started.emit()

	# Store reference to player and their crate
	player = get_tree().get_first_node_in_group("player")
	player_crate = _find_player_crate()

	# Fade to black
	await _fade_screen(true)

	# Load new location
	_load_location(location_scene)

	# Fade back in
	await _fade_screen(false)

	teleport_completed.emit()

func return_to_kitchen():
	if not main_kitchen_scene:
		print("[LocationManager] Main kitchen scene not found!")
		return

	teleport_started.emit()

	# Store player and crate references
	player = get_tree().get_first_node_in_group("player")
	player_crate = _find_player_crate()

	# Fade to black
	await _fade_screen(true)

	# Load kitchen scene
	_load_location(main_kitchen_scene)

	# Fade back in
	await _fade_screen(false)

	teleport_completed.emit()

func _find_player_crate() -> Node3D:
	# Look for a crate being carried by the player
	var interaction_system = get_tree().get_first_node_in_group("item_interaction")
	if interaction_system and interaction_system.has_method("get_carried_item"):
		var carried_item = interaction_system.get_carried_item()
		if carried_item and carried_item.has_method("is_crate") and carried_item.is_crate():
			return carried_item

	# Look for crates in the scene
	var crates = get_tree().get_nodes_in_group("crates")
	for crate in crates:
		if crate.has_method("belongs_to_player") and crate.belongs_to_player():
			return crate

	return null

func _load_location(location_scene: PackedScene):
	# Store player reference before clearing scene
	if not player:
		player = get_tree().get_first_node_in_group("player")

	# Remove player from current scene but don't free it
	var player_parent = null
	if player:
		player_parent = player.get_parent()
		if player_parent:
			player_parent.remove_child(player)

	# Find the main game scene (kitchen scene)
	var main_scene = get_tree().current_scene
	var location_container = main_scene.get_node_or_null("LocationContainer")
	
	# If we don't have a LocationContainer, we need to restructure
	if not location_container:
		# This means we're swapping entire scenes - preserve UI and systems
		_swap_entire_scene(location_scene)
		return
	
	# Clear existing location from container
	if current_location:
		current_location.queue_free()

	# Load new location and add to container
	var new_location = location_scene.instantiate()
	location_container.add_child(new_location)
	current_location = new_location

	# Add player to new location
	if player:
		current_location.add_child(player)
		_position_player_in_location()

	# Move crate to location if it exists
	_position_crate_in_location()

func _swap_entire_scene(location_scene: PackedScene):
	# Store references to persistent systems
	var ui_system = get_tree().get_first_node_in_group("game_ui")
	var audio_system = get_tree().get_first_node_in_group("audio_manager")

	# Remove persistent systems from tree but don't free them
	if ui_system:
		ui_system.get_parent().remove_child(ui_system)
	if audio_system:
		audio_system.get_parent().remove_child(audio_system)

	# Store the old scene reference
	var old_scene = get_tree().current_scene

	# Load new location
	var new_location = location_scene.instantiate()
	get_tree().root.add_child(new_location)
	get_tree().current_scene = new_location
	current_location = new_location

	# Re-add persistent systems to new scene
	if ui_system:
		new_location.add_child(ui_system)
	if audio_system:
		new_location.add_child(audio_system)

	# Remove old scene
	if old_scene and old_scene != new_location:
		old_scene.queue_free()

	# Add player to new scene
	if player:
		current_location.add_child(player)
		_position_player_in_location()

	# Move crate to location if it exists
	_position_crate_in_location()

func _position_player_in_location():
	if not player:
		return

	# Look for spawn point in the new location
	var spawn_point = current_location.get_node_or_null("PlayerSpawn")
	if spawn_point:
		player.global_position = spawn_point.global_position
		print("[LocationManager] Player positioned at spawn point: ", spawn_point.global_position)
	else:
		# Default position
		player.global_position = Vector3(0, 1, 0)
		print("[LocationManager] Player positioned at default location")

func _position_crate_in_location():
	if not player_crate:
		return

	# Position crate near player
	var crate_position = player.global_position + Vector3(2, 0, 0)
	player_crate.global_position = crate_position

	# Re-parent crate to new scene if needed
	var crate_parent = player_crate.get_parent()
	if crate_parent and crate_parent != current_location:
		crate_parent.remove_child(player_crate)
		current_location.add_child(player_crate)

	print("[LocationManager] Crate positioned in new location at: ", crate_position)

func _fade_screen(fade_in: bool) -> void:
	var overlay = ColorRect.new()
	overlay.color = Color.BLACK
	overlay.color.a = 1.0 if fade_in else 0.0
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 1000  # Ensure it's on top

	# Add to current scene's UI layer or root
	var ui_parent = _get_ui_parent()
	ui_parent.add_child(overlay)

	# Animate fade
	var tween = create_tween()
	var target_alpha = 0.0 if fade_in else 1.0
	tween.tween_property(overlay, "color:a", target_alpha, 0.5)
	await tween.finished

	# Clean up if fading out
	if not fade_in:
		overlay.queue_free()

func _get_ui_parent() -> Node:
	var current_scene = get_tree().current_scene

	# Try to find UI layer
	var ui_layer = current_scene.get_node_or_null("UI")
	if ui_layer:
		return ui_layer

	# Try to find Canvas layer
	var canvas = current_scene.get_node_or_null("CanvasLayer")
	if canvas:
		return canvas

	# Fallback to current scene
	return current_scene

func is_in_location() -> bool:
	return current_location != null and current_location.scene_file_path != main_kitchen_scene.resource_path

func get_current_location_name() -> String:
	if not current_location:
		return "Kitchen"

	var scene_path = current_location.scene_file_path
	if scene_path.is_empty():
		return "Unknown Location"

	var file_name = scene_path.get_file().get_basename()
	return file_name.capitalize().replace("_", " ")
