extends Control
class_name TutorialController

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var skip_label: Label = $SkipLabel

func _ready():
	# Connect video finished signal
	if video_player:
		video_player.finished.connect(_on_video_finished)

	# Show mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event):
	# Allow escape key to skip tutorial
	if event.is_action_pressed("ui_cancel"):
		_exit_tutorial()

func _on_video_finished():
	_exit_tutorial()

func _exit_tutorial():
	SceneManager.goto_scene("res://scenes/main_menu.tscn", 1.0)
