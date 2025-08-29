extends Control
class_name CreditsController

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var back_button: Button = $ScrollContainer/VBoxContainer/BackButton

var scroll_speed: float = 30.0  # Pixels per second
var auto_scroll: bool = true
var scroll_tween: Tween

func _ready():
	# Show mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Start auto-scroll after a brief delay
	await get_tree().create_timer(1.0).timeout
	start_auto_scroll()

func _input(event):
	# Allow escape key to go back
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

	# Stop auto-scroll if user interacts
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		if event is InputEventMouseButton and event.pressed:
			stop_auto_scroll()

	# Scroll controls
	if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
		stop_auto_scroll()

func start_auto_scroll():
	if not auto_scroll:
		return

	scroll_tween = create_tween()
	scroll_tween.set_loops()

	# Calculate total scroll distance
	var content_height = $ScrollContainer/VBoxContainer.size.y
	var container_height = scroll_container.size.y
	var max_scroll = max(0, content_height - container_height)

	if max_scroll > 0:
		# Scroll down
		var scroll_time = max_scroll / scroll_speed
		scroll_tween.tween_method(_set_scroll_position, 0, max_scroll, scroll_time)

		# Pause at bottom
		scroll_tween.tween_interval(3.0)

		# Scroll back to top
		scroll_tween.tween_method(_set_scroll_position, max_scroll, 0, scroll_time * 0.5)

		# Pause at top
		scroll_tween.tween_interval(2.0)

func stop_auto_scroll():
	auto_scroll = false
	if scroll_tween:
		scroll_tween.kill()

func _set_scroll_position(position: float):
	scroll_container.scroll_vertical = int(position)

func _on_back_pressed():
	SceneManager.goto_scene("res://scenes/main_menu.tscn", 1.0)

func _exit_tree():
	if scroll_tween:
		scroll_tween.kill()
