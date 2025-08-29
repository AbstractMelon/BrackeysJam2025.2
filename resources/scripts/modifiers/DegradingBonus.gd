extends Modifier
class_name DegradingBonus

var initial_bonus: float = 100.0
var decay_per_round: float = 20.0
var current_bonus: float

func _init():
	types = [Globals.ModifierType.POINTADD]
	name = "Degrading Bonus"
	description = "+100 points initially, -20 per round"
	current_bonus = initial_bonus

func _get_additive_score(values: ScoreData) -> ScoreData:
	if current_bonus > 0:
		values.points += current_bonus
	return values

func _on_modifier_created():
	current_bonus = initial_bonus

func _on_modifier_gained():
	print("Degrading Bonus modifier applied: +", current_bonus, " points this round!")
	# Connect to round end signal to decay bonus
	if GameLoop.round_ended.is_connected(_on_round_ended):
		GameLoop.round_ended.disconnect(_on_round_ended)
	GameLoop.round_ended.connect(_on_round_ended)

func _on_modifier_removed():
	print("Degrading Bonus modifier removed")
	if GameLoop.round_ended.is_connected(_on_round_ended):
		GameLoop.round_ended.disconnect(_on_round_ended)

func _on_round_ended(round_number: int):
	current_bonus -= decay_per_round
	print("Degrading Bonus decayed to: ", current_bonus, " points")

	# Remove modifier if bonus becomes negative
	if current_bonus <= 0:
		print("Degrading Bonus has expired!")
		ModifierManager.remove_modifier(self)
