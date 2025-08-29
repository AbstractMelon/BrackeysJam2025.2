extends Modifier
class_name EscalatingBonus

var initial_bonus: float = 0.0
var growth_per_round: float = 20.0
var current_bonus: float

func _init():
	types = [Globals.ModifierType.POINTADD]
	name = "Escalating Bonus"
	description = "+0 initially, +20 per round"
	current_bonus = initial_bonus

func _get_additive_score(values: ScoreData) -> ScoreData:
	values.points += current_bonus
	return values

func _on_modifier_created():
	current_bonus = initial_bonus

func _on_modifier_gained():
	print("Escalating Bonus modifier applied: +", current_bonus, " points this round!")
	# Connect to round end signal to increase bonus
	if GameLoop.round_ended.is_connected(_on_round_ended):
		GameLoop.round_ended.disconnect(_on_round_ended)
	GameLoop.round_ended.connect(_on_round_ended)

func _on_modifier_removed():
	print("Escalating Bonus modifier removed")
	if GameLoop.round_ended.is_connected(_on_round_ended):
		GameLoop.round_ended.disconnect(_on_round_ended)

func _on_round_ended(round_number: int):
	current_bonus += growth_per_round
	print("Escalating Bonus increased to: ", current_bonus, " points")
