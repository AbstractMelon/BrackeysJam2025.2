extends Modifier
class_name Jerry

func _init():
	types = [Globals.ModifierType.OTHER]
	name = "Jerry"
	description = "It's just Jerry."

func _get_additive_score(values: ScoreData) -> ScoreData:
	# Jerry does nothing
	return values

func _get_multiplicitive_score(values: ScoreData) -> ScoreData:
	# Jerry still does nothing
	return values

func _get_additive_player_stats(values: PlayerStats) -> PlayerStats:
	# Jerry continues to do nothing
	return values

func _get_multiplicative_player_stats(values: PlayerStats) -> PlayerStats:
	# Jerry remains committed to doing nothing
	return values

func _trigger():
	# Jerry's trigger also does nothing
	pass

func _on_modifier_created():
	pass

func _on_modifier_gained():
	print("Jerry has joined the party! He's not doing anything, but he's here.")

func _on_modifier_removed():
	print("Jerry has left. Nobody noticed because he wasn't doing anything anyway.")
