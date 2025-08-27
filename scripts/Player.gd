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

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var speed: float

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

func _ready():
	# Add to groups for detection
	add_to_group("player")

	# Capture the mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

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
		velocity.y = jump_velocity

	# Handle sprint
	if Input.is_action_pressed("sprint"):
		speed = sprint_speed
	else:
		speed = walk_speed

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
	var velocity_clamped = clamp(velocity.length(), 0.5, sprint_speed * 2)
	var target_fov = base_fov + fov_change * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	move_and_slide()

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * bob_freq) * bob_amp
	pos.x = cos(time * bob_freq / 2) * bob_amp
	return pos

func _input(event):
	# Toggle mouse capture with Escape key
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
