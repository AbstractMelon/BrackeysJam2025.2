extends StaticBody3D
class_name MixingPot

@export var is_npc_pot: bool = false
@export var npc_name: String = "" # Only used if is_npc_pot is true

@export var potAudio: Array[AudioStream]

@onready var mixing_area: Area3D = $MixingArea
@onready var ui_label: Label3D = $UILabel

var score_data : ScoreData
var base_points : float = 0
var mixed_items : Array[ItemData] = []

signal item_mixed(item: PickupableItem, points: int)
signal mixing_complete(total_points: int)

func _ready():
	# If it's an NPC pot, no need for collision signals
	if not is_npc_pot:
		mixing_area.body_entered.connect(_on_item_entered)
	
	update_score_data()
	update_ui()

func update_score_data() -> void:
	score_data = ScoreData.new()
	score_data.points = base_points
	score_data.modifier_count = ModifierManager.get_modifiers().size()
	score_data.multiplier = 1
	
	var ingredients : Array[ItemData] = []
	for data in mixed_items:
		ingredients.append(data)
	score_data.ingredients = ingredients
	
	ModifierManager.get_modified_score(score_data)

func _on_item_entered(body):
	if is_npc_pot:
		return # NPCs don’t mix this way
	if body is PickupableItem and not body.is_being_carried:
		# Don't accept utility items
		if body.item_data.zone_type == ItemData.Zones.UTILITY:
			return
		mix_item(body)

func mix_item(item: PickupableItem):
	if is_npc_pot:
		return # Ignore human-style mixing
	if not item or item in mixed_items:
		return
	
	var points : float = GameManager.calculate_item_points(item)
	base_points += points
	
	mixed_items.append(item.item_data)
	update_score_data()
	
	item.queue_free()
	update_ui()
	item_mixed.emit(item, points)
	AudioManager.play_random_sfx_group(potAudio)

func complete_mixing() -> int:
	var final_points = score_data.points * score_data.multiplier
	mixed_items.clear()
	base_points = 0
	update_ui()
	mixing_complete.emit(final_points)
	return final_points

func update_ui():
	if not ui_label:
		return
	
	if is_npc_pot:
		# Just show NPC info
		ui_label.text = "%s's Pot\nPoints: %d" % [npc_name, get_current_points()]
	else:
		# Full breakdown for human pot
		ui_label.text = "Your Pot\nMixed: %d items\nBase points: %d\nModified points: %d" % [
			mixed_items.size(),
			base_points,
			get_current_points()
		]

func get_current_points() -> int:
	return score_data.points * score_data.multiplier
