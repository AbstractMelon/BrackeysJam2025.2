extends Node3D

@export var scene_transition_time: float = 1.0

# Camera animation export
@export_group("Camera Animation")
@export var camera: Camera3D
@export var enable_camera_animation: bool = true
@export var camera_animation_duration: float = 13.0

# Keyframe positions and rotations 
@export var keyframe_positions: Array[Vector3] = []
@export var keyframe_rotations: Array[Vector3] = []  # Euler angles in degrees
@export var keyframe_timings: Array[float] = []  # When each keyframe should be reached (0-1)

# Animation easing
@export var position_easing: Tween.EaseType = Tween.EASE_IN_OUT
@export var rotation_easing: Tween.EaseType = Tween.EASE_IN_OUT

var tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_cutscene()

func start_cutscene():
	if enable_camera_animation and camera:
		animate_camera()
	
	handover_delay(13.7)

func animate_camera():
	if keyframe_positions.size() < 2:
		return
	
	tween = create_tween()
	tween.set_parallel(true)  # Allow position and rotation to animate simultaneously
	
	# Set initial position and rotation
	camera.position = keyframe_positions[0]
	camera.rotation_degrees = keyframe_rotations[0]
	
	# Create animation for each keyframe
	for i in range(1, keyframe_positions.size()):
		var timing = keyframe_timings[i] if i < keyframe_timings.size() else float(i) / float(keyframe_positions.size() - 1)
		var delay = timing * camera_animation_duration
		
		# Position animation
		var pos_tween = tween.tween_method(
			set_camera_position,
			camera.position,
			keyframe_positions[i],
			0.5  # Duration between keyframes
		)
		pos_tween.set_delay(delay)
		pos_tween.set_ease(position_easing)
		
		# Rotation animation
		var rot_tween = tween.tween_method(
			set_camera_rotation,
			camera.rotation_degrees,
			keyframe_rotations[i],
			0.5
		)
		rot_tween.set_delay(delay)
		rot_tween.set_ease(rotation_easing)

func set_camera_position(pos: Vector3):
	if camera:
		camera.position = pos

func set_camera_rotation(rot: Vector3):
	if camera:
		camera.rotation_degrees = rot

func handover_delay(length: float):
	await get_tree().create_timer(length - (scene_transition_time / 2)).timeout
	SceneManager.goto_scene("res://scenes/game.tscn", scene_transition_time)

# Add manual camera position helpers for easier setup
func _input(event):
	# Only works in editor/debug builds
	if OS.is_debug_build() and event.is_action_pressed("ui_accept"):
		print("Current camera position: ", camera.position)
		print("Current camera rotation: ", camera.rotation_degrees)
