extends Control
class_name BiscuitInfoDisplay

@onready var panel: Panel = $Panel
@onready var biscuit_name: Label = $Panel/MarginContainer/VBoxContainer/BiscuitName
@onready var description: Label = $Panel/MarginContainer/VBoxContainer/Description
@onready var base_points_label: Label = $Panel/MarginContainer/VBoxContainer/PointsContainer/BasePointsLabel
@onready var modifier_points_label: Label = $Panel/MarginContainer/VBoxContainer/PointsContainer/ModifierPointsLabel
@onready var total_points_label: Label = $Panel/MarginContainer/VBoxContainer/PointsContainer/TotalPointsLabel
@onready var ingredients_list: RichTextLabel = $Panel/MarginContainer/VBoxContainer/IngredientsList
@onready var special_attributes: RichTextLabel = $Panel/MarginContainer/VBoxContainer/SpecialAttributes

var display_tween: Tween
var is_visible: bool = false

func _ready():
	# Start hidden
	panel.modulate.a = 0.0
	visible = false

func show_biscuit_info(biscuit: GameState.BiscuitData):
	if not biscuit:
		return

	# Update biscuit information
	update_biscuit_display(biscuit)

	# Show with fade animation
	visible = true
	is_visible = true

	if display_tween:
		display_tween.kill()
	display_tween = create_tween()
	display_tween.tween_property(panel, "modulate:a", 1.0, 0.3)

func hide_biscuit_info():
	if not is_visible:
		return

	is_visible = false

	if display_tween:
		display_tween.kill()
	display_tween = create_tween()
	display_tween.tween_property(panel, "modulate:a", 0.0, 0.25)
	display_tween.tween_callback(func(): visible = false)

func update_biscuit_display(biscuit: GameState.BiscuitData):
	# Update name
	biscuit_name.text = biscuit.name

	# Update description
	description.text = biscuit.description

	# Update points
	base_points_label.text = "Base Points: " + str(biscuit.base_points)
	modifier_points_label.text = "Modifier: +" + str(biscuit.modifier_points)
	total_points_label.text = "Total: " + str(biscuit.total_points)

	# Color-code total points
	if biscuit.total_points >= 80:
		total_points_label.modulate = Color.GREEN
	elif biscuit.total_points >= 40:
		total_points_label.modulate = Color.YELLOW
	else:
		total_points_label.modulate = Color.RED

	# Update ingredients list
	var ingredients_text = ""
	for ingredient in biscuit.ingredients:
		if ingredient:
			ingredients_text += "• " + ingredient.item_name
			if ingredient.is_shiny:
				ingredients_text += " ✨"
			ingredients_text += " (" + str(ingredient.point_value) + " pts)\n"

	ingredients_list.text = ingredients_text

	# Update special attributes
	var attributes_text = ""
	for attribute in biscuit.special_attributes:
		match attribute:
			"Radioactive":
				attributes_text += "[color=green]Radioactive[/color] "
			"Spicy":
				attributes_text += "[color=red]Spicy[/color] "
			"Sweet":
				attributes_text += "[color=pink]Sweet[/color] "
			"Rotten":
				attributes_text += "[color=brown]Rotten[/color] "
			"Shiny":
				attributes_text += "[color=gold]Shiny[/color] "
			_:
				attributes_text += "[color=gray]" + attribute + "[/color] "

	special_attributes.text = attributes_text

func is_display_visible() -> bool:
	return is_visible

# Static function to create and show biscuit info
static func show_biscuit_info_for(biscuit: GameState.BiscuitData, parent_node: Node) -> BiscuitInfoDisplay:
	var info_scene = preload("res://scenes/UI/biscuit_info_display.tscn")
	var info_instance = info_scene.instantiate()
	parent_node.add_child(info_instance)
	info_instance.show_biscuit_info(biscuit)
	return info_instance

func _exit_tree():
	if display_tween:
		display_tween.kill()
