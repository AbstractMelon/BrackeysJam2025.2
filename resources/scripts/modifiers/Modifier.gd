extends Resource
class_name Modifier

var _types : Array[Globals.ModifierType]
var _name : String
var _description : String
# Array of ModifierTypes to hold data on what the modifier actually does

func _get_additive_score(values : ScoreData) -> ScoreData:
	return values
# Called when getting base points and multiplier

func _get_multiplicitive_score(values : ScoreData) -> ScoreData:
	return values
# Called when getting multiplied points and multiplier

func _get_player_stats(values : PlayerStats) -> PlayerStats:
	return values
	
func _get_additive_player_stats(values : PlayerStats) -> PlayerStats:
	return values

func _get_multiplicative_player_stats(values : PlayerStats) -> PlayerStats:
	return values

func _trigger() -> void:
	pass

func _on_modifier_gained() -> void:
	pass
# Called when the modifier is gained

func _on_modifier_removed() -> void:
	pass
# Called when the modifier is removed
