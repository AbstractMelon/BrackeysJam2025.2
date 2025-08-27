extends Modifier
class_name TimeLord

func _on_modifier_created() -> void:
	name = "Time Lord"
	description = "10% more baking time"
	types.append(Globals.ModifierType.OTHER)

# Called when the modifier is gained
func _on_modifier_gained() -> void:
	GameLoop.baking_time *= 1.1

func _on_modifier_removed() -> void:
	GameManager.shiny_chance /= 1.1
