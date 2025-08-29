extends Control
class_name PauseMenu

@onready var resume_button: Button = $MenuContainer/ResumeButton
@onready var settings_button: Button = $MenuContainer/SettingsButton
@onready var main_menu_button: Button = $MenuContainer/MainMenuButton
@onready var quit_button: Button = $MenuContainer/QuitButton

var settings_menu_scene = preload("res://scenes/UI/settings_menu.tscn")
var settings_menu_instance: Control

func _ready():
	# Initially hide the pause menu
	hide()

	# Connect button signals
	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Make sure the menu processes during pause
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func _input(event):
	if event.is_action_pressed("pause"):
		if visible:
			resume_game()
		else:
			pause_game()

func pause_game():
	show()
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	resume_button.grab_focus()

func resume_game():
	hide()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Close settings menu if open
	if settings_menu_instance and settings_menu_instance.is_inside_tree():
		settings_menu_instance.queue_free()
		settings_menu_instance = null

func _on_resume_pressed():
	resume_game()

func _on_settings_pressed():
	if not settings_menu_instance:
		settings_menu_instance = settings_menu_scene.instantiate()
		get_parent().add_child(settings_menu_instance)

		# Connect to settings menu close signal if it exists
		if settings_menu_instance.has_signal("menu_closed"):
			settings_menu_instance.menu_closed.connect(_on_settings_closed)

	# Show settings menu
	settings_menu_instance.show()
	hide()

func _on_settings_closed():
	if settings_menu_instance:
		settings_menu_instance.queue_free()
		settings_menu_instance = null
	show()

func _on_main_menu_pressed():
	resume_game()
	SceneManager.goto_scene("res://scenes/main_menu.tscn", 1.0)

func _on_quit_pressed():
	get_tree().quit()
