extends Node

# Game state
var current_round: int = 1
var total_score: int = 0

# Modifier effects
var double_chance: float = 0.0
var shiny_chance: float = 0.05
var camera_flipped: bool = false
var player_height_bonus: float = 0.0
var poison_resistance: float = 0.0
var player: Node = null

signal round_completed(score: int)
signal score_updated(new_score: int)
signal node_added(node)

func _ready():
	player = get_tree().get_first_node_in_group("player")
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node):
	node_added.emit(node)

func get_player() -> Node:
	if player and player.is_inside_tree():
		return player
		
	player = get_tree().get_first_node_in_group("player")
	return player

func get_world() -> Node:
	return get_tree().get_current_scene()

func calculate_item_points(item: PickupableItem) -> int:
	if not item or not item.item_data:
		return 0
	
	var base_points = item.get_point_value()
	var final_points = float(base_points)
	
	# Apply global point multiplier
	
	return int(final_points)
	
func reset_all_modifiers():
	ModifierManager.reset_modifiers()

func complete_round(mixing_pot_points: int):
	total_score += mixing_pot_points
	current_round += 1
	
	# Apply decay modifiers
	
	round_completed.emit(mixing_pot_points)
	score_updated.emit(total_score)

func add_score(points: int):
	total_score += points
	score_updated.emit(total_score)

func should_spawn_shiny_item() -> bool:
	return randf() < shiny_chance
