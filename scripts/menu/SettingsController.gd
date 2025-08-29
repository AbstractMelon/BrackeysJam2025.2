extends Control
class_name SettingsController

@onready var master_volume_slider: HSlider = $CenterContainer/Panel/MarginContainer/VBoxContainer/AudioSection/MasterVolumeContainer/MasterVolumeSlider
@onready var master_volume_value: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/AudioSection/MasterVolumeContainer/MasterVolumeValue
@onready var music_volume_slider: HSlider = $CenterContainer/Panel/MarginContainer/VBoxContainer/AudioSection/MusicVolumeContainer/MusicVolumeSlider
@onready var music_volume_value: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/AudioSection/MusicVolumeContainer/MusicVolumeValue
@onready var sfx_volume_slider: HSlider = $CenterContainer/Panel/MarginContainer/VBoxContainer/AudioSection/SFXVolumeContainer/SFXVolumeSlider
@onready var sfx_volume_value: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/AudioSection/SFXVolumeContainer/SFXVolumeValue
@onready var sensitivity_slider: HSlider = $CenterContainer/Panel/MarginContainer/VBoxContainer/GameplaySection/SensitivityContainer/SensitivitySlider
@onready var sensitivity_value: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/GameplaySection/SensitivityContainer/SensitivityValue

signal settings_closed()

var settings_data: Dictionary = {}
var config_file: ConfigFile

func _ready():
	# Show mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Initialize config file
	config_file = ConfigFile.new()
	load_settings()
	apply_settings()

func _input(event):
	# Allow escape key to close settings
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func load_settings():
	# Load settings from file or use defaults
	var error = config_file.load("user://settings.cfg")

	if error != OK:
		# File doesn't exist, use defaults
		settings_data = get_default_settings()
	else:
		# Load from file
		settings_data = {
			"master_volume": config_file.get_value("audio", "master_volume", 1.0),
			"music_volume": config_file.get_value("audio", "music_volume", 1.0),
			"sfx_volume": config_file.get_value("audio", "sfx_volume", 1.0),
			"mouse_sensitivity": config_file.get_value("gameplay", "mouse_sensitivity", 0.003)
		}

func save_settings():
	# Save current settings to file
	config_file.set_value("audio", "master_volume", settings_data.master_volume)
	config_file.set_value("audio", "music_volume", settings_data.music_volume)
	config_file.set_value("audio", "sfx_volume", settings_data.sfx_volume)
	config_file.set_value("gameplay", "mouse_sensitivity", settings_data.mouse_sensitivity)

	var error = config_file.save("user://settings.cfg")
	if error != OK:
		print("Failed to save settings: ", error)

func get_default_settings() -> Dictionary:
	return {
		"master_volume": 1.0,
		"music_volume": 1.0,
		"sfx_volume": 1.0,
		"mouse_sensitivity": 0.003
	}

func apply_settings():
	# Update UI controls
	master_volume_slider.value = settings_data.master_volume
	music_volume_slider.value = settings_data.music_volume
	sfx_volume_slider.value = settings_data.sfx_volume
	sensitivity_slider.value = settings_data.mouse_sensitivity

	# Update value labels
	_update_volume_labels()
	_update_sensitivity_label()

	# Apply to game systems
	if AudioManager:
		AudioManager.master_volume = settings_data.master_volume
		AudioManager.music_volume = settings_data.music_volume
		AudioManager.sfx_volume = settings_data.sfx_volume

	# Apply mouse sensitivity to player if in game
	var player = get_tree().get_first_node_in_group("player") as FirstPersonController
	if player:
		player.sensitivity = settings_data.mouse_sensitivity

func _update_volume_labels():
	master_volume_value.text = str(int(settings_data.master_volume * 100)) + "%"
	music_volume_value.text = str(int(settings_data.music_volume * 100)) + "%"
	sfx_volume_value.text = str(int(settings_data.sfx_volume * 100)) + "%"

func _update_sensitivity_label():
	sensitivity_value.text = str(settings_data.mouse_sensitivity)

func _on_master_volume_changed(value: float):
	settings_data.master_volume = value
	master_volume_value.text = str(int(value * 100)) + "%"

	# Apply immediately
	if AudioManager:
		AudioManager.master_volume = value

func _on_music_volume_changed(value: float):
	settings_data.music_volume = value
	music_volume_value.text = str(int(value * 100)) + "%"

	# Apply immediately
	if AudioManager:
		AudioManager.music_volume = value

func _on_sfx_volume_changed(value: float):
	settings_data.sfx_volume = value
	sfx_volume_value.text = str(int(value * 100)) + "%"

	# Apply immediately
	if AudioManager:
		AudioManager.sfx_volume = value

func _on_sensitivity_changed(value: float):
	settings_data.mouse_sensitivity = value
	sensitivity_value.text = str(value)

	# Apply immediately to player if in game
	var player = get_tree().get_first_node_in_group("player") as FirstPersonController
	if player:
		player.sensitivity = value

func _on_reset_pressed():
	# Reset to defaults
	settings_data = get_default_settings()
	apply_settings()
	print("Settings reset to defaults")

func _on_back_pressed():
	# Save settings and close
	save_settings()
	settings_closed.emit()
	queue_free()

# Static function to open settings menu
static func open_settings_menu(parent_node: Node) -> SettingsController:
	var settings_scene = preload("res://scenes/UI/settings_menu.tscn")
	var settings_instance = settings_scene.instantiate()
	parent_node.add_child(settings_instance)
	return settings_instance
