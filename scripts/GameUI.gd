extends Control
class_name GameUI

signal end_baking_pressed()
signal modifier_selected(modifier_name: String)
signal location_selected(location_scene: PackedScene)

@onready var timer_label: Label = $TimerPanel/TimerLabel
@onready var round_label: Label = $RoundPanel/RoundLabel
@onready var player_count_label: Label = $RoundPanel/PlayerCountLabel
@onready var end_baking_button: Button = $EndBakingButton
@onready var modifier_panel: Panel = $ModifierPanel
@onready var modifier_buttons: VBoxContainer = $ModifierPanel/VBoxContainer
@onready var location_panel: Panel = $LocationPanel
@onready var location_buttons: VBoxContainer = $LocationPanel/VBoxContainer

# Message labels
@onready var elimination_message: Label = $Labels/EliminationMessage
@onready var victory_message: Label = $Labels/VictoryMessage
@onready var defeat_message: Label = $Labels/DefeatMessage

# Judge commenting
@onready var judge_panel: Panel = $Judging
@onready var current_victim: Label = $Judging/CurrentVictim
@onready var judge_comment: Label = $Judging/JudgeComment
@onready var skip_judging_label: Label = $Judging/SkipJudgingButton

func _ready():
	add_to_group("game_ui")
	end_baking_button.pressed.connect(_on_end_baking_pressed)

	# Hide panels
	modifier_panel.hide()
	location_panel.hide()
	judge_panel.hide()

	# Hide all message elements initially
	elimination_message.hide()
	victory_message.hide()
	defeat_message.hide()
	judge_comment.hide()

	# Connect to GameLoop signals
	GameLoop.state_changed.connect(_on_state_changed)
	GameLoop.timer_updated.connect(_on_timer_updated)
	GameLoop.round_started.connect(_on_round_started)
	GameLoop.player_eliminated.connect(_on_player_eliminated)

	JudgeSystem.update_victim.connect(_on_update_victim)

func _input(event: InputEvent) -> void:
	if event.is_action("skip") and GameState.State.JUDGING:
		JudgeSystem.skip_judging()
		skip_judging_label.text = "Skip requested, please wait..."

func _on_state_changed(new_state: GameState.State):
	match new_state:
		GameState.State.BAKING:
			_show_baking_ui()
		GameState.State.JUDGING:
			_show_judging_ui()
		GameState.State.MODIFIER_SELECTION:
			_show_modifier_selection_ui()
		GameState.State.GAME_OVER, GameState.State.VICTORY:
			_show_game_over_ui(new_state)
		_:
			#_hide_all_ui()
			pass

func _show_baking_ui():
	timer_label.show()
	round_label.show()
	player_count_label.show()
	end_baking_button.show()
	modifier_panel.hide()
	location_panel.hide()
	judge_panel.hide()

	# Hide message elements during baking
	elimination_message.hide()
	victory_message.hide()
	defeat_message.hide()
	judge_comment.hide()

func _show_judging_ui():
	end_baking_button.hide()
	elimination_message.hide()
	judge_panel.show()
	skip_judging_label.show()
	# Keep timer and round info visible during judging

func _show_modifier_selection_ui():
	skip_judging_label.text = "Press \"R\" to skip"
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	show_modifier_selection()

func _show_game_over_ui(state: GameState.State):
	timer_label.hide()
	end_baking_button.hide()
	modifier_panel.hide()
	elimination_message.hide()
	judge_comment.hide()
	skip_judging_label.hide()

	if state == GameState.State.VICTORY:
		_show_victory_message()
	else:
		_show_defeat_message()

func _hide_all_ui():
	print("Hiding all UI")
	timer_label.hide()
	round_label.hide()
	player_count_label.hide()
	end_baking_button.hide()
	modifier_panel.hide()
	location_panel.hide()
	elimination_message.hide()
	victory_message.hide()
	defeat_message.hide()
	judge_panel.hide()
	skip_judging_label.hide()

func _on_timer_updated(time_left: float):
	var minutes = int(time_left / 60)
	var seconds = int(time_left) % 60
	timer_label.text = "Time: %02d:%02d" % [minutes, seconds]

	# Change color based on remaining time
	if time_left < 30:
		timer_label.modulate = Color.RED
	elif time_left < 60:
		timer_label.modulate = Color.YELLOW
	else:
		timer_label.modulate = Color.WHITE

func _on_round_started(round_number: int):
	round_label.text = "Round " + str(round_number)
	_update_player_count()

func _on_player_eliminated(player: GameState.PlayerData):
	judge_panel.hide()
	skip_judging_label.hide()
	_update_player_count()
	_show_elimination_message(player.name)

func _update_player_count():
	var alive_count = GameLoop.get_alive_players().size()
	player_count_label.text = "Players Remaining: " + str(alive_count)

func _on_end_baking_pressed():
	end_baking_pressed.emit()
	GameLoop.force_end_baking()

func show_modifier_selection():
	modifier_panel.show()
	end_baking_button.hide()
	timer_label.hide()

	# Clear existing buttons
	for child in modifier_buttons.get_children():
		child.queue_free()

	# Create buttons for 3 random modifiers
	var selected_modifiers = ModifierManager.get_random_modifiers(3)

	for i in range(min(3, selected_modifiers.size())):
		var button = Button.new()
		button.text = "%s - %s" % [selected_modifiers[i].name, selected_modifiers[i].description]
		button.custom_minimum_size.y = 60
		button.pressed.connect(_on_modifier_button_pressed.bind(selected_modifiers[i]))
		modifier_buttons.add_child(button)

func _on_modifier_button_pressed(modifier: Modifier):
	modifier_selected.emit(modifier)
	_apply_modifier(modifier)
	modifier_panel.hide()
	# Show location selection after modifier selection
	_show_location_selection()

func _apply_modifier(modifier : Modifier):
	# Apply the selected modifier to the game
	ModifierManager.apply_modifier(modifier)
	return

func _enable_item_preview():
	# Enable tooltips showing item values
	var pickup_items = get_tree().get_nodes_in_group("pickup_items")
	for item in pickup_items:
		if item.has_method("show_value_preview"):
			item.show_value_preview(true)

func _show_elimination_message(player_name: String):
	elimination_message.text = player_name + " has been eliminated!"
	elimination_message.modulate = Color.RED
	elimination_message.show()

	# Fade out after 3 seconds
	var tween = create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(elimination_message, "modulate:a", 0.0, 1.0)
	tween.tween_callback(elimination_message.hide)
	tween.tween_callback(func(): elimination_message.modulate.a = 1.0) # Reset alpha for next use

func _show_victory_message():
	_hide_all_ui()
	victory_message.show()

func _show_defeat_message():
	_hide_all_ui()
	print("Showing death message")
	defeat_message.show()
	print("Showed death message")

func show_judge_comment(judge_name: String, comment: String):
	judge_comment.text = judge_name + ": " + comment
	judge_comment.show()

func _show_location_selection():
	location_panel.show()

	# Clear existing buttons
	for child in location_buttons.get_children():
		child.queue_free()

	# Get 3 random locations from LocationManager
	var available_locations = LocationManager.get_random_locations(3)

	for i in range(min(3, available_locations.size())):
		var location_scene = available_locations[i]
		var button = Button.new()

		# Extract location name from scene path
		var location_name = location_scene.resource_path.get_file().get_basename()
		location_name = location_name.capitalize().replace("_", " ")

		button.text = location_name
		button.custom_minimum_size.y = 60
		button.pressed.connect(_on_location_button_pressed.bind(location_scene))
		location_buttons.add_child(button)

func _on_location_button_pressed(location_scene: PackedScene):
	location_selected.emit(location_scene)
	location_panel.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Teleport to selected location
	LocationManager.teleport_to_location(location_scene)

	# Continue with next round
	GameLoop.on_modifier_selected()

func _on_update_victim(player_name: String):
	current_victim.text = "Currently Judging: " + player_name
