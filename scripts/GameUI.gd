extends Control
class_name GameUI

signal end_baking_pressed()
signal modifier_selected(modifier_name: String)

@onready var timer_label: Label = $TimerPanel/TimerLabel
@onready var round_label: Label = $RoundPanel/RoundLabel
@onready var player_count_label: Label = $RoundPanel/PlayerCountLabel
@onready var end_baking_button: Button = $EndBakingButton
@onready var modifier_panel: Panel = $ModifierPanel
@onready var modifier_buttons: VBoxContainer = $ModifierPanel/VBoxContainer

@onready var elimination_message: Label = $Labels/EliminationMessage
@onready var victory_message: Label = $Labels/VictoryMessage
@onready var defeat_message: Label = $Labels/DefeatMessage
@onready var judge_comment: RichTextLabel = $Labels/JudgeComment

var available_modifiers: Array[String] = [
	"Double Vision - 2x chance for shiny items",
	"Height Advantage - See over counters better",
	"Poison Resistance - Immune to negative food effects",
	"Quick Hands - 25% faster item pickup",
	"Lucky Charm - 15% point bonus to all items",
	"Iron Stomach - Can eat questionable ingredients safely",
	"Master Chef - Know item values before picking up",
	"Time Lord - Slow down time by 10% during baking"
]

func _ready():
	add_to_group("game_ui")
	end_baking_button.pressed.connect(_on_end_baking_pressed)
	modifier_panel.hide()
	
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
			_hide_all_ui()

func _show_baking_ui():
	timer_label.show()
	round_label.show()
	player_count_label.show()
	end_baking_button.show()
	modifier_panel.hide()
	
	# Hide message elements during baking
	elimination_message.hide()
	victory_message.hide()
	defeat_message.hide()
	judge_comment.hide()

func _show_judging_ui():
	end_baking_button.hide()
	elimination_message.hide()
	# Keep timer and round info visible during judging

func _show_modifier_selection_ui():
	show_modifier_selection()

func _show_game_over_ui(state: GameState.State):
	timer_label.hide()
	end_baking_button.hide()
	modifier_panel.hide()
	elimination_message.hide()
	judge_comment.hide()

	if state == GameState.State.VICTORY:
		_show_victory_message()
	else:
		_show_defeat_message()

func _hide_all_ui():
	timer_label.hide()
	round_label.hide()
	player_count_label.hide()
	end_baking_button.hide()
	modifier_panel.hide()
	elimination_message.hide()
	victory_message.hide()
	defeat_message.hide()
	judge_comment.hide()

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
	var selected_modifiers = available_modifiers.duplicate()
	selected_modifiers.shuffle()

	for i in range(min(3, selected_modifiers.size())):
		var button = Button.new()
		button.text = selected_modifiers[i]
		button.custom_minimum_size.y = 60
		button.pressed.connect(_on_modifier_button_pressed.bind(selected_modifiers[i]))
		modifier_buttons.add_child(button)

func _on_modifier_button_pressed(modifier_name: String):
	modifier_selected.emit(modifier_name)
	_apply_modifier(modifier_name)
	modifier_panel.hide()
	GameLoop.on_modifier_selected()

func _apply_modifier(modifier_name: String):
	# Apply the selected modifier to the game
	if "Double Vision" in modifier_name:
		GameManager.shiny_chance_bonus += 0.1
	elif "Height Advantage" in modifier_name:
		GameManager.player_height_bonus += 0.5
	elif "Poison Resistance" in modifier_name:
		GameManager.poison_resistance = 1.0
	elif "Quick Hands" in modifier_name:
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("set_pickup_speed_bonus"):
			player.set_pickup_speed_bonus(0.25)
	elif "Lucky Charm" in modifier_name:
		ModifierManager.add_global_point_bonus(0.15)
	elif "Iron Stomach" in modifier_name:
		GameManager.poison_resistance = 1.0
	elif "Master Chef" in modifier_name:
		# Enable item value preview
		_enable_item_preview()
	elif "Time Lord" in modifier_name:
		Engine.time_scale = 0.9

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
	defeat_message.show()

func show_judge_comment(judge_name: String, comment: String):
	judge_comment.text = "[b]" + judge_name + ":[/b] " + comment
	judge_comment.show()

	# Remove after 5 seconds
	var tween = create_tween()
	tween.tween_interval(5.0)
	tween.tween_property(judge_comment, "modulate:a", 0.0, 1.0)
	tween.tween_callback(judge_comment.hide)
	tween.tween_callback(func(): judge_comment.modulate.a = 1.0) # Reset alpha for next use
