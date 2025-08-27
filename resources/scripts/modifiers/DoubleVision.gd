extends Modifier
class_name DoubleVision

# Called when the modifier is gained
func _on_modifier_gained() -> void:
	name = "Double Vision"
	description = "2x chance for shiny items"
	types.append(Globals.ModifierType.OTHER)
	
	GameManager.shiny_chance_bonus *= 2

func _on_modifier_removed() -> void:
	GameManager.shiny_chance_bonus /= 2
