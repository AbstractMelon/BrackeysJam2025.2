extends Node

# Game state
var current_round: int = 1
var total_score: int = 0

# Modifier effects
var double_chance: float = 0.0
var shiny_chance_bonus: float = 0.0
var camera_flipped: bool = false
var player_height_bonus: float = 0.0
var poison_resistance: float = 0.0
var australia_mode: bool = false

signal round_completed(score: int)
signal score_updated(new_score: int)

func _ready():
	pass

func calculate_item_points(item: PickupableItem) -> int:
	if not item or not item.item_data:
		return 0
	
	var base_points = item.get_point_value()
	var final_points = float(base_points)
	
	# Apply global point multiplier
	
	return int(final_points)
	
func apply_camera_flip():
	var player = get_tree().get_first_node_in_group("player") as FirstPersonController
	if player and player.camera:
		if camera_flipped:
			player.camera.rotation_degrees.z = 180
		else:
			player.camera.rotation_degrees.z = 0

func apply_australia_mode():
	if australia_mode:
		print("Australia mode activated! 🇦🇺")
		# Add texture replacement here

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
	var base_chance = 0.05  # 5% base chance
	return randf() < (base_chance + shiny_chance_bonus)
