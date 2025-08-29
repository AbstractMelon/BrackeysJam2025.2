extends CharacterBody3D
class_name FirstPersonController

# Movement variables
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var sensitivity: float = 0.003

# Bob variables
@export var bob_freq: float = 2.4
@export var bob_amp: float = 0.08
var t_bob: float = 0.0

# FOV variables
@export var base_fov: float = 75.0
@export var fov_change: float = 1.5

# Footsteps variables
@export var footstep_interval: float = 0.5
@export var sprint_footstep_interval: float = 0.3
@export var footstep_volume: float = -50.0
var footstep_timer: float = 0.0
var last_velocity: Vector3 = Vector3.ZERO

# Footstep audio arrays for different surfaces
var concrete_footsteps: Array[AudioStream]
var grass_footsteps: Array[AudioStream]
var wood_footsteps: Array[AudioStream]
var metal_footsteps: Array[AudioStream]

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var speed: float

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var footstep_player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()

var stats : PlayerStats

func _ready():
	# Add to groups for detection
	add_to_group("player")

	# Capture the mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Setup footstep audio
	add_child(footstep_player)
	footstep_player.volume_db = footstep_volume
	footstep_player.max_distance = 20.0
	footstep_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE

	# Load footstep audio files
	_load_footstep_sounds()

	# Set stats
	update_stats()
	ModifierManager.modifiers_changed.connect(update_stats)

func _unhandled_input(event):
	# Handle mouse look
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * sensitivity)
		camera.rotate_x(-event.relative.y * sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta):
	# Handle gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = stats.jump_velocity

	# Handle sprint
	if Input.is_action_pressed("sprint"):
		speed = stats.sprint_speed
	else:
		speed = stats.walk_speed

	# Get the input direction and handle the movement/deceleration
	var input_dir = Vector2.ZERO

	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_back"):
		input_dir.y += 1
	if Input.is_action_pressed("move_forward"):
		input_dir.y -= 1

	# Get the movement direction relative to the player's rotation
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if is_on_floor():
		if direction != Vector3.ZERO:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		# Air control (reduced)
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)

	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)

	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, stats.sprint_speed * 2)
	var target_fov = base_fov + fov_change * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	move_and_slide()

	# Handle footsteps
	_handle_footsteps(delta)

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * bob_freq) * bob_amp
	pos.x = cos(time * bob_freq / 2) * bob_amp
	return pos

func update_stats() -> void:
	stats = PlayerStats.new()
	stats.extra_height = 0.0
	stats.jump_velocity = jump_velocity
	stats.sprint_speed = sprint_speed
	stats.walk_speed = walk_speed

	ModifierManager.get_modified_stats(stats)

	# TODO: Extra height needs to affect things

func _handle_footsteps(delta):
	if not is_on_floor():
		return

	# Check if player is moving
	var horizontal_velocity = Vector2(velocity.x, velocity.z)
	var is_moving = horizontal_velocity.length() > 0.1

	if not is_moving:
		footstep_timer = 0.0
		return

	# Update footstep timer
	footstep_timer += delta

	# Determine interval based on speed
	var current_interval = sprint_footstep_interval if Input.is_action_pressed("sprint") else footstep_interval

	if footstep_timer >= current_interval:
		_play_footstep()
		footstep_timer = 0.0

func _play_footstep():
	var surface_type = _detect_surface()
	var footstep_sounds: Array[AudioStream]

	match surface_type:
		"grass":
			footstep_sounds = grass_footsteps
		"wood":
			footstep_sounds = wood_footsteps
		"metal":
			footstep_sounds = metal_footsteps
		_:
			footstep_sounds = concrete_footsteps

	if footstep_sounds.size() > 0:
		var random_sound = footstep_sounds[randi() % footstep_sounds.size()]
		if random_sound:
			footstep_player.stream = random_sound
			footstep_player.pitch_scale = randf_range(0.9, 1.1)  # Slight pitch variation
			footstep_player.play()

func _detect_surface() -> String:
	# Cast a ray down to detect surface type
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position,
		global_position + Vector3(0, -2, 0)
	)

	var result = space_state.intersect_ray(query)
	if result and result.collider:
		# Try to detect surface based on material or groups
		if result.collider.is_in_group("grass"):
			return "grass"
		elif result.collider.is_in_group("wood"):
			return "wood"
		elif result.collider.is_in_group("metal"):
			return "metal"

	return "concrete"  # Default

func _load_footstep_sounds():
	# Load concrete footsteps
	concrete_footsteps = [
		preload("res://assets/audio/SFX/footstep1.ogg"),
		preload("res://assets/audio/SFX/footstep2.ogg"),
		preload("res://assets/audio/SFX/footstep3.ogg"),
		preload("res://assets/audio/SFX/footstep4.ogg"),
		preload("res://assets/audio/SFX/footstep5.ogg"),
		preload("res://assets/audio/SFX/footstep6.ogg"),
		preload("res://assets/audio/SFX/footstep7.ogg"),
		preload("res://assets/audio/SFX/footstep8.ogg"),
		preload("res://assets/audio/SFX/footstep9.ogg")
	]

	# Load grass footsteps
	grass_footsteps = [
		preload("res://assets/audio/SFX/footstepgrass1.ogg"),
		preload("res://assets/audio/SFX/footstepgrass2.ogg"),
		preload("res://assets/audio/SFX/footstepgrass3.ogg")
	]

	# For now, use concrete sounds for wood and metal (can be replaced later)
	wood_footsteps = concrete_footsteps.duplicate()
	metal_footsteps = concrete_footsteps.duplicate()

func _input(event):
	# Toggle mouse capture with Escape key
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
