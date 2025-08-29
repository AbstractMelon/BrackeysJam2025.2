extends Modifier
class_name ExtraShiny

func _init():
	types = [Globals.ModifierType.OTHER]
	name = "Shiny Hunter"
	description = "+10% chance of shiny items"

func _on_modifier_created():
	pass

func _on_modifier_gained():
	print("Shiny Hunter modifier applied: +10% chance for shiny items!")
	# Increase global shiny chance
	if GameManager:
		GameManager.shiny_chance += 0.10

func _on_modifier_removed():
	print("Shiny Hunter modifier removed")
	# Decrease global shiny chance
	if GameManager:
		GameManager.shiny_chance = max(0.0, GameManager.shiny_chance - 0.10)

func _trigger():
	# This modifier's effect is passive
	pass
