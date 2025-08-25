extends StaticBody3D
class_name MixingPot

@onready var mixing_area: Area3D = $MixingArea
@onready var ui_label: Label3D = $UILabel

var mixed_items: Array[PickupableItem] = []
var total_points: int = 0

signal item_mixed(item: PickupableItem, points: int)
signal mixing_complete(total_points: int)

func _ready():
	mixing_area.body_entered.connect(_on_item_entered)
	update_ui()

func _on_item_entered(body):
	if body is PickupableItem and not body.is_being_carried:
		mix_item(body)

func mix_item(item: PickupableItem):
	if not item or item in mixed_items:
		return
	
	# Calculate points with game manager modifiers
	var points = GameManager.calculate_item_points(item)
	mixed_items.append(item)
	total_points += points
	
	# Remove item from world
	item.queue_free()
	
	update_ui()
	item_mixed.emit(item, points)

func complete_mixing() -> int:
	var final_points = total_points
	mixed_items.clear()
	total_points = 0
	update_ui()
	mixing_complete.emit(final_points)
	return final_points

func update_ui():
	if ui_label:
		ui_label.text = "Mixed: %d items\nPoints: %d" % [mixed_items.size(), total_points]

func get_current_points() -> int:
	return total_points
