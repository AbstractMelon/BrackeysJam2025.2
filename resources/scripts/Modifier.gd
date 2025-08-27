extends Resource
class_name Modifier

# Array of ModifierTypes to hold data on what the modifier actually does
var types : Array[Globals.ModifierType]
var name : String
var description : String

func _get_additive_score(values : ScoreData) -> ScoreData:
	# Called when getting base points and multiplier
	return values

func _get_multiplicitive_score(values : ScoreData) -> ScoreData:
	# Called when getting multiplied points and multiplier
	return values

func _get_player_stats(values : PlayerStats) -> PlayerStats:
	return values
	
func _get_additive_player_stats(values : PlayerStats) -> PlayerStats:
	return values

func _get_multiplicative_player_stats(values : PlayerStats) -> PlayerStats:
	return values

func _trigger() -> void:
	pass

func _on_modifier_gained() -> void:
	# Called when the modifier is gained
	pass

func _on_modifier_removed() -> void:
	# Called when the modifier is removed
	pass
