extends Node

# Array of all current modifiers
var _modifiers : Array[Modifier]

# Array of all modifiers, as scripts (so they can be added in inspector)
@export var _all_modifiers : Array[Script]

# Array of all available modifiers
var _available_modifiers : Array[Modifier]

# Gets base points and multiplier
signal get_additive_score(data : ScoreData)

# Gets multiplied points and multiplier
signal get_multiplicative_score(data: ScoreData)

# Gets base stats
signal get_additive_player_stats(stats: PlayerStats)

# Gets multiplied stats
signal get_multiplicative_player_stats(stats: PlayerStats)

# Triggers any modifiers with type OTHER
signal trigger_modifiers()

# Called whenever the list of multipliers changes
signal modifiers_changed()

# Fills available modifiers
func _ready() -> void:
	for modifier in _all_modifiers:
		_available_modifiers.append(modifier.new())

# Returns modifiers
func get_modifiers() -> Array[Modifier]:
	return _modifiers

# Gets rid of a modifier and informs it, plus removes signals
func remove_modifier(modifier : Modifier, send_signal : bool = true) -> bool:
	if modifier not in _modifiers:
		return false
	_modifiers.erase(modifier)
	
	get_additive_score.disconnect(modifier._get_additive_score)
	get_multiplicative_score.disconnect(modifier._get_multiplicitive_score)
	get_additive_player_stats.disconnect(modifier._get_additive_player_stats)
	get_multiplicative_player_stats.disconnect(modifier._get_multiplicative_player_stats)
	
	_available_modifiers.append(modifier.get_script().new())
	
	modifier._on_modifier_removed()
	modifier.free()
	
	if send_signal:
		modifiers_changed.emit()
	
	return true

# Adds a modifier and informs it, plus connects it to the relevant signals
func apply_modifier(modifier : Modifier) -> bool:
	if modifier in _modifiers:
		return false
	
	_modifiers.append(modifier)
	modifier._on_modifier_gained()
	
	if modifier._types.has(Globals.ModifierType.POINTADD) or modifier._types.has(Globals.ModifierType.MULTIPLIERADD):
		get_additive_score.connect(modifier._get_additive_score)
		
	if modifier._types.has(Globals.ModifierType.MULTIPLIERMULT):
		get_multiplicative_score.connect(modifier._get_multiplicitive_score)
	
	if modifier._types.has(Globals.ModifierType.STATADD):
		get_additive_player_stats.connect(modifier._get_additive_player_stats)
	
	if modifier._types.has(Globals.ModifierType.STATMULT):
		get_multiplicative_player_stats.connect(modifier._get_multiplicative_player_stats)
	
	if modifier._types.has(Globals.ModifierType.OTHER):
		trigger_modifiers.connect(modifier._trigger)
	
	_available_modifiers.erase(modifier)
	
	modifiers_changed.emit()
	
	return true

# Checks if a modifier exists
func contains_modifier(modifier : Modifier) -> bool:
	if modifier in _modifiers:
		return true
	return false

# Returns modified score after letting modifiers adjust it
func get_modified_score(data : ScoreData) -> ScoreData:
	get_additive_score.emit(data)
	get_multiplicative_score.emit(data)
	return data

func get_modified_stats(stats : PlayerStats) -> PlayerStats:
	get_additive_player_stats.emit(stats)
	get_multiplicative_player_stats.emit(stats)
	return stats

func trigger_all_modifiers():
	trigger_modifiers.emit()
	
func get_random_modifiers(count : int) -> Array[Modifier]:
	var shuffled = _available_modifiers.duplicate()
	shuffled.shuffle()
	return shuffled.slice(0, min(count, shuffled.size()))

func reset_modifiers() -> void:
	var modifiers = _modifiers.duplicate()
	for modifier in modifiers:
		remove_modifier(modifier, false)
	
	modifiers_changed.emit()
