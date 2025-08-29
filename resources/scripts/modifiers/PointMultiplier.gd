extends Modifier
class_name PointMultiplier

func _init():
	types = [Globals.ModifierType.MULTIPLIERMULT]
	name = "Lucky Charm+"
	description = "2x point multiplier for all items"

func _get_multiplicitive_score(values: ScoreData) -> ScoreData:
	values.multiplier *= 2.0
	return values

func _on_modifier_created():
	pass

func _on_modifier_gained():
	print("Point multiplier modifier applied: 2x points!")

func _on_modifier_removed():
	print("Point multiplier modifier removed")
