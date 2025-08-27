extends Modifier
class_name PoisonResistance

func _on_modifier_created() -> void:
	name = "Poison Resistance"
	description = "Immune to negative food effects"
	types.append(Globals.ModifierType.OTHER)

# Called when the modifier is gained
func _on_modifier_gained() -> void:
	GameManager.poison_resistance += 1

func _on_modifier_removed() -> void:
	GameManager.poison_resistance -= 1
