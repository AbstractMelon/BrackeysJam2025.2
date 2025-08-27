extends Modifier
class_name LuckyCharm

func _on_modifier_created() -> void:
	name = "Lucky Charm"
	description = "Gain 0.15 more point multiplier"
	types.append(Globals.ModifierType.MULTIPLIERADD)

# Called when the modifier is gained
func _get_additive_score(data : ScoreData) -> ScoreData:
	data.multiplier += 0.15
	return data
