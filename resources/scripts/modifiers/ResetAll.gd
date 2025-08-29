extends Modifier
class_name ResetAll

func _init():
	types = [Globals.ModifierType.OTHER]
	name = "Fresh Start"
	description = "Resets all modifiers, +200 points"

func _get_additive_score(values: ScoreData) -> ScoreData:
	values.points += 200
	return values

func _on_modifier_created():
	pass

func _on_modifier_gained():
	print("Fresh Start modifier applied: Resetting all modifiers and adding 200 points!")

	# Remove all other modifiers except this one
	var modifiers_to_remove = []
	for modifier in ModifierManager.get_modifiers():
		if modifier != self:
			modifiers_to_remove.append(modifier)

	# Remove them after collecting to avoid modifying array while iterating
	for modifier in modifiers_to_remove:
		ModifierManager.remove_modifier(modifier, false)

	# Remove self after one frame to ensure points are applied
	call_deferred("_remove_self")

func _remove_self():
	ModifierManager.remove_modifier(self)

func _on_modifier_removed():
	print("Fresh Start modifier removed - all modifiers reset!")
