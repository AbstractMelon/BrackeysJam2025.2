extends Modifier
class_name SugarRush

func _on_modifier_created() -> void:
	name = "Sugar Rush"
	description = "Move 1.5x faster"
	types.append(Globals.ModifierType.STATMULT)

# Called when the modifier is gained
func _get_multiplicative_player_stats(stats : PlayerStats) -> PlayerStats:
	stats.walk_speed *= 1.5
	stats.sprint_speed *= 1.5
	return stats
