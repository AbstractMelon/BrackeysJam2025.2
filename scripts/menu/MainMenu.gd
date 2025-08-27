extends Control
class_name MainMenu

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var options_button: Button = $VBoxContainer/OptionsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var title_label: Label = $TitleLabel

func _ready():
	# Connect buttons
	start_button.pressed.connect(_on_start_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Ensure mouse is visible in menu
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_start_pressed():
	print("Starting new game...")
	SceneManager.load_scene("res://scenes/game.tscn")

func _on_options_pressed():
	print("Options not implemented yet")
	# TODO: Implement options menu

func _on_quit_pressed():
	get_tree().quit()

func _input(event):
	# Allow escape key to quit from main menu
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
