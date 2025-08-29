extends Node

var settings_menu: SettingsController = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_play_pressed() -> void:
	SceneManager.goto_scene("res://scenes/game.tscn", 2.0)


func _on_settings_pressed() -> void:
	if not settings_menu:
		settings_menu = SettingsController.open_settings_menu(get_tree().current_scene)
		settings_menu.settings_closed.connect(_on_settings_closed)


func _on_settings_closed() -> void:
	settings_menu = null


func _on_credits_pressed() -> void:
	SceneManager.goto_scene("res://scenes/UI/credits_menu.tscn", 1.0)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_tutorial_pressed() -> void:
	SceneManager.goto_scene("res://scenes/tutorial.tscn", 2.0)
