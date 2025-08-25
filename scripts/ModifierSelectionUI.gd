extends Control
class_name ModifierSelectionUI

@onready var modifier_container: HBoxContainer = $VBoxContainer/ModifierContainer
@onready var score_label: Label = $VBoxContainer/ScoreLabel
@onready var round_label: Label = $VBoxContainer/RoundLabel

@export var modifier_button_scene: PackedScene
var available_modifiers: Array[GameModifier] = []

signal modifier_selected(modifier: GameModifier)

func _ready():
	GameManager.round_completed.connect(_on_round_completed)
	GameManager.score_updated.connect(_on_score_updated)
	hide()

func _on_round_completed(score: int):
	show_modifier_selection()

func _on_score_updated(new_score: int):
	if score_label:
		score_label.text = "Total Score: %d" % new_score

func show_modifier_selection():
	available_modifiers = GameManager.get_random_modifiers(3)
	create_modifier_buttons()
	
	# Update UI
	if round_label:
		round_label.text = "Round %d Complete - Choose a Modifier" % GameManager.current_round
	
	show()
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func create_modifier_buttons():
	# Clear existing buttons
	for child in modifier_container.get_children():
		child.queue_free()
	
	# Create new buttons
	for modifier in available_modifiers:
		var button = Button.new()
		button.text = modifier.modifier_name + "\n" + modifier.description
		button.custom_minimum_size = Vector2(200, 100)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		button.pressed.connect(_on_modifier_selected.bind(modifier))
		modifier_container.add_child(button)

func _on_modifier_selected(modifier: GameModifier):
	GameManager.apply_modifier(modifier)
	hide()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	modifier_selected.emit(modifier)
