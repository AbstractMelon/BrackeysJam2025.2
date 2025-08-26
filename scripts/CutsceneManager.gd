extends Node
class_name CutsceneManager

signal cutscene_started(cutscene_type: String)
signal cutscene_finished(cutscene_type: String)

enum CutsceneType {
	JUDGING,
	ELIMINATION,
	VICTORY,
	DEFEAT
}

var is_playing: bool = false
var current_cutscene: CutsceneType
var player_camera: Camera3D
var original_player_position: Vector3
var original_camera_transform: Transform3D
var cutscene_camera: Camera3D

@onready var tween: Tween

func _ready():
	add_to_group("cutscene_manager")

func start_judging_cutscene(players: Array[GameState.PlayerData]):
	if is_playing:
		return

	current_cutscene = CutsceneType.JUDGING
	is_playing = true
	cutscene_started.emit("judging")

	_setup_cutscene_camera()
	await _play_judging_sequence(players)
	_cleanup_cutscene()

	cutscene_finished.emit("judging")
	is_playing = false

func start_elimination_cutscene(eliminated_player: GameState.PlayerData):
	if is_playing:
		return

	current_cutscene = CutsceneType.ELIMINATION
	is_playing = true
	cutscene_started.emit("elimination")

	_setup_cutscene_camera()
	await _play_elimination_sequence(eliminated_player)
	_cleanup_cutscene()

	cutscene_finished.emit("elimination")
	is_playing = false

func start_victory_cutscene():
	if is_playing:
		return

	current_cutscene = CutsceneType.VICTORY
	is_playing = true
	cutscene_started.emit("victory")

	_setup_cutscene_camera()
	await _play_victory_sequence()
	_cleanup_cutscene()

	cutscene_finished.emit("victory")
	is_playing = false

func start_defeat_cutscene():
	if is_playing:
		return

	current_cutscene = CutsceneType.DEFEAT
	is_playing = true
	cutscene_started.emit("defeat")

	_setup_cutscene_camera()
	await _play_defeat_sequence()
	_cleanup_cutscene()

	cutscene_finished.emit("defeat")
	is_playing = false

func _setup_cutscene_camera():
	# Find player and their camera
	var player = get_tree().get_first_node_in_group("player") as FirstPersonController
	if player and player.camera:
		player_camera = player.camera
		original_camera_transform = player_camera.global_transform

		# Disable player input during cutscene
		player.set_physics_process(false)
		player.set_process_input(false)

	# Create cutscene camera
	cutscene_camera = Camera3D.new()
	cutscene_camera.name = "CutsceneCamera"
	get_tree().current_scene.add_child(cutscene_camera)

	# Position camera for wide shot of judges area
	cutscene_camera.global_position = Vector3(0, 5, 15)  # High angle overlooking the judges
	cutscene_camera.look_at(Vector3(0, 2, 10), Vector3.UP)

	# Make cutscene camera current
	cutscene_camera.current = true

func _cleanup_cutscene():
	# Restore player camera
	if player_camera:
		player_camera.current = true

		# Re-enable player input
		var player = get_tree().get_first_node_in_group("player") as FirstPersonController
		if player:
			player.set_physics_process(true)
			player.set_process_input(true)

	# Remove cutscene camera
	if cutscene_camera:
		cutscene_camera.queue_free()
		cutscene_camera = null

func _play_judging_sequence(players: Array[GameState.PlayerData]) -> void:
	print("=== JUDGING CUTSCENE BEGINS ===")

	# Camera sweep of all the biscuits
	await _camera_sweep_biscuits(players)

	# Focus on judges
	await _focus_on_judges()

	# Judge each biscuit with camera movements
	var sorted_players = players.duplicate()
	sorted_players.sort_custom(func(a, b): return a.round_score < b.round_score)

	for player in sorted_players:
		await _judge_single_biscuit(player)
		await get_tree().create_timer(1.0).timeout

	print("=== JUDGING CUTSCENE ENDS ===")

func _camera_sweep_biscuits(players: Array[GameState.PlayerData]) -> void:
	if not cutscene_camera:
		return

	tween = create_tween()

	# Start from high angle
	var start_pos = Vector3(-8, 6, 8)
	var end_pos = Vector3(8, 6, 8)

	cutscene_camera.global_position = start_pos
	cutscene_camera.look_at(Vector3(0, 1, 3), Vector3.UP)

	# Sweep across the kitchen
	tween.tween_method(_update_camera_sweep, 0.0, 1.0, 3.0)
	await tween.finished

func _update_camera_sweep(progress: float):
	if not cutscene_camera:
		return

	var start_pos = Vector3(-8, 6, 8)
	var end_pos = Vector3(8, 6, 8)

	cutscene_camera.global_position = start_pos.lerp(end_pos, progress)
	cutscene_camera.look_at(Vector3(0, 1, 3), Vector3.UP)

func _focus_on_judges() -> void:
	if not cutscene_camera:
		return

	tween = create_tween()

	# Move camera to judges area
	var judge_focus_pos = Vector3(0, 3, 12)
	var judge_look_at = Vector3(0, 2, 8)

	tween.parallel().tween_property(cutscene_camera, "global_position", judge_focus_pos, 2.0)
	tween.parallel().tween_method(_look_at_judges, cutscene_camera.global_transform.basis.z,
		(judge_look_at - judge_focus_pos).normalized(), 2.0)

	await tween.finished

func _look_at_judges(direction: Vector3):
	if cutscene_camera:
		cutscene_camera.look_at(cutscene_camera.global_position - direction, Vector3.UP)

func _judge_single_biscuit(player: GameState.PlayerData) -> void:
	if not cutscene_camera:
		return

	print("--- Judging ", player.name, "'s biscuit ---")

	# Focus camera on the player's biscuit area
	var station_pos = player.station_position
	if station_pos:
		tween = create_tween()

		var biscuit_focus_pos = station_pos + Vector3(0, 2, 3)
		var biscuit_look_at = station_pos + Vector3(0, 1, 0)

		tween.parallel().tween_property(cutscene_camera, "global_position", biscuit_focus_pos, 1.5)
		tween.parallel().tween_method(_look_at_biscuit,
			cutscene_camera.global_transform.origin, biscuit_look_at, 1.5)

		await tween.finished

	# Show biscuit details (this would trigger UI elements)
	_show_biscuit_details(player.current_biscuit)
	await get_tree().create_timer(2.0).timeout

	# Return to judges view
	await _focus_on_judges()

func _look_at_biscuit(target_pos: Vector3):
	if cutscene_camera:
		cutscene_camera.look_at(target_pos, Vector3.UP)

func _show_biscuit_details(biscuit: GameState.BiscuitData):
	if not biscuit:
		return

	# This would trigger UI to show biscuit name, description, points, etc.
	print("Biscuit: ", biscuit.name)
	print("Description: ", biscuit.description)
	print("Points: ", biscuit.total_points)

func _play_elimination_sequence(eliminated_player: GameState.PlayerData) -> void:
	print("=== ELIMINATION CUTSCENE BEGINS ===")

	if not cutscene_camera:
		return

	# Focus on eliminated player's station
	var station_pos = eliminated_player.station_position
	if station_pos:
		tween = create_tween()

		var focus_pos = station_pos + Vector3(0, 3, 5)
		cutscene_camera.global_position = focus_pos
		cutscene_camera.look_at(station_pos + Vector3(0, 1, 0), Vector3.UP)

		# Dramatic zoom in
		tween.tween_property(cutscene_camera, "fov", 30, 2.0)  # Narrow FOV for drama
		await tween.finished

		await get_tree().create_timer(2.0).timeout

		# Zoom back out
		tween = create_tween()
		tween.tween_property(cutscene_camera, "fov", 75, 1.0)  # Return to normal FOV
		await tween.finished

	print("=== ELIMINATION CUTSCENE ENDS ===")

func _play_victory_sequence() -> void:
	print("=== VICTORY CUTSCENE BEGINS ===")

	if not cutscene_camera:
		return

	# Triumphant camera movement
	tween = create_tween()

	# Start low and sweep upward
	var start_pos = Vector3(0, 1, 8)
	var end_pos = Vector3(0, 8, 12)

	cutscene_camera.global_position = start_pos
	cutscene_camera.look_at(Vector3(0, 2, 0), Vector3.UP)

	tween.parallel().tween_property(cutscene_camera, "global_position", end_pos, 4.0)
	tween.parallel().tween_method(_victory_camera_rotation, 0.0, 360.0, 4.0)

	await tween.finished

	print("=== VICTORY CUTSCENE ENDS ===")

func _victory_camera_rotation(angle: float):
	if cutscene_camera:
		var radius = 12.0
		var x = cos(deg_to_rad(angle)) * radius
		var z = sin(deg_to_rad(angle)) * radius
		cutscene_camera.global_position = Vector3(x, 8, z)
		cutscene_camera.look_at(Vector3(0, 2, 0), Vector3.UP)

func _play_defeat_sequence() -> void:
	print("=== DEFEAT CUTSCENE BEGINS ===")

	if not cutscene_camera:
		return

	# Somber camera movement
	tween = create_tween()

	# Slow zoom on player's failed biscuit
	var player_station = Vector3(-4.53201, -0.745121, 1.25715)  # Human player station
	var focus_pos = player_station + Vector3(0, 2, 4)

	cutscene_camera.global_position = focus_pos
	cutscene_camera.look_at(player_station + Vector3(0, 1, 0), Vector3.UP)

	tween.tween_property(cutscene_camera, "fov", 20, 3.0)  # Slow dramatic zoom
	await tween.finished

	await get_tree().create_timer(2.0).timeout

	print("=== DEFEAT CUTSCENE ENDS ===")

func skip_cutscene():
	# Allow players to skip cutscenes
	if is_playing and tween:
		tween.kill()
		_cleanup_cutscene()
		cutscene_finished.emit(_get_cutscene_name())
		is_playing = false

func _get_cutscene_name() -> String:
	match current_cutscene:
		CutsceneType.JUDGING: return "judging"
		CutsceneType.ELIMINATION: return "elimination"
		CutsceneType.VICTORY: return "victory"
		CutsceneType.DEFEAT: return "defeat"
		_: return "unknown"

func is_cutscene_playing() -> bool:
	return is_playing
