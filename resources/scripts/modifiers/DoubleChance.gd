extends Modifier
class_name DoubleChance

func _init():
	types = [Globals.ModifierType.OTHER]
	name = "Double or Nothing"
	description = "1/3 chance to double the score of each item collected"

var double_chance: float = 0.333  # 1/3 chance

func _get_additive_score(values: ScoreData) -> ScoreData:
	# Check each ingredient for double chance
	for ingredient in values.ingredients:
		if randf() < double_chance:
			values.points += ingredient.point_value
			print("Double chance triggered for ", ingredient.item_name, "! Bonus points added.")

	return values

func _on_modifier_created():
	pass

func _on_modifier_gained():
	print("Double or Nothing modifier applied: 1/3 chance to double item scores!")

func _on_modifier_removed():
	print("Double or Nothing modifier removed")
