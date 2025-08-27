extends Modifier
class_name HeightAdvantage

func _on_modifier_created() -> void:
	name = "Height Advantage"
	description = "See over counters better"
	types.append(Globals.ModifierType.STATADD)

# Called when the modifier is gained
func _get_additive_player_stats(stats : PlayerStats) -> PlayerStats:
	stats.extra_height += 1.0
	return stats
