extends StaticBody3D
class_name MixingPot

@onready var mixing_area: Area3D = $MixingArea
@onready var ui_label: Label3D = $UILabel

var score_data : ScoreData
var base_points : float = 0
var mixed_items : Array[PickupableItem] = []

signal item_mixed(item: PickupableItem, points: int)
signal mixing_complete(total_points: int)

func _ready():
	mixing_area.body_entered.connect(_on_item_entered)
	
	update_score_data()
	
	update_ui()

func update_score_data() -> void:
	score_data = ScoreData.new()
	score_data.points = base_points
	score_data.modifier_count = ModifierManager.get_modifiers().size()
	score_data.multiplier = 1
	
	var ingredients : Array[ItemData] = []
	for mixed_item in mixed_items:
		ingredients.append(mixed_item.item_data)
	score_data.ingredients = ingredients
	
	ModifierManager.get_modified_score(score_data)

func _on_item_entered(body):
	if body is PickupableItem and not body.is_being_carried:
		mix_item(body)

func mix_item(item: PickupableItem):
	if not item or item in mixed_items:
		return
	
	# Calculate points with game manager modifiers
	var points : float = GameManager.calculate_item_points(item)
	base_points += points
	
	mixed_items.append(item)
	update_score_data()
	
	# Remove item from world
	item.queue_free()
	
	update_ui()
	item_mixed.emit(item, points)

func complete_mixing() -> int:
	var final_points = score_data.points * score_data.multiplier
	mixed_items.clear()
	base_points = 0
	update_ui()
	mixing_complete.emit(final_points)
	return final_points

func update_ui():
	if ui_label:
		ui_label.text = "Mixed: %d items\nBase points: %d\nModified points: %d" % [mixed_items.size(), base_points, score_data.points * score_data.multiplier]

func get_current_points() -> int:
	return score_data.points * score_data.multiplier
