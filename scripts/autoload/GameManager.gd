extends Node

# Game state
var current_round: int = 1
var total_score: int = 0
var active_modifiers: Array[GameModifier] = []

# Modifier effects
var point_multiplier: float = 1.0
var zone_buffs: Dictionary = {}  # zone_name -> multiplier
var speed_multiplier: float = 1.0
var jump_multiplier: float = 1.0
var weight_multiplier: float = 1.0
var double_chance: float = 0.0
var bonus_points: int = 0
var shiny_chance_bonus: float = 0.0
var camera_flipped: bool = false
var player_height_bonus: float = 0.0
var poison_resistance: float = 0.0
var australia_mode: bool = false

# Available modifiers for selection
@export var available_modifiers: Array[GameModifier] = []

signal round_completed(score: int)
signal modifier_applied(modifier: GameModifier)
signal score_updated(new_score: int)

func _ready():
	setup_default_modifiers()

func setup_default_modifiers():
	var modifiers: Array[GameModifier] = [
		create_modifier("Point Multiplier", GameModifier.ModifierType.POINT_MULTIPLIER, "2x points for all items", 2.0),
		create_modifier("Lava Zone Buff", GameModifier.ModifierType.ZONE_BUFF, "3x points for lava items", 3.0, "lava"),
		create_modifier("Speed Boost", GameModifier.ModifierType.SPEED_JUMP, "1.5x movement speed", 1.5),
		create_modifier("Double Chance", GameModifier.ModifierType.DOUBLE_CHANCE, "33% chance to double item points", 0.33),
		create_modifier("Starting Bonus", GameModifier.ModifierType.BONUS_DECAY, "Start with +100 points, lose 20 each round", 100.0),
		create_modifier("Growing Bonus", GameModifier.ModifierType.BONUS_GROWTH, "Gain +20 points each round", 20.0),
		create_modifier("Fresh Start", GameModifier.ModifierType.RESET_BONUS, "Reset all modifiers, gain 2000 points", 2000.0),
		create_modifier("Shiny Hunter", GameModifier.ModifierType.SHINY_CHANCE, "+10% chance for shiny items", 0.1),
		create_modifier("Australia", GameModifier.ModifierType.AUSTRALIA, "Everything becomes Australian", 1.0),
		create_modifier("Jerry", GameModifier.ModifierType.JERRY, "Jerry does nothing", 0.0)
	]
	available_modifiers = modifiers

func create_modifier(name: String, type: GameModifier.ModifierType, desc: String, value: float, zone: String = "") -> GameModifier:
	var modifier = GameModifier.new()
	modifier.modifier_name = name
	modifier.modifier_type = type
	modifier.description = desc
	modifier.value = value
	modifier.zone_target = zone
	return modifier

func calculate_item_points(item: PickupableItem) -> int:
	if not item or not item.item_data:
		return 0
	
	var base_points = item.get_point_value()
	var final_points = float(base_points)
	
	# Apply global point multiplier
	final_points *= point_multiplier
	
	# Apply zone-specific buffs
	if item.item_data.zone_type in zone_buffs:
		final_points *= zone_buffs[item.item_data.zone_type]
	
	# Apply double chance
	if randf() < double_chance:
		final_points *= 2.0
	
	return int(final_points)

func apply_modifier(modifier: GameModifier):
	active_modifiers.append(modifier)
	
	match modifier.modifier_type:
		GameModifier.ModifierType.POINT_MULTIPLIER:
			point_multiplier *= modifier.value
		
		GameModifier.ModifierType.ZONE_BUFF:
			if modifier.zone_target != "":
				zone_buffs[modifier.zone_target] = modifier.value
		
		GameModifier.ModifierType.SPEED_JUMP:
			speed_multiplier *= modifier.value
			jump_multiplier *= modifier.value
			apply_player_modifiers()
		
		GameModifier.ModifierType.WEIGHT_CARRY:
			weight_multiplier *= modifier.value
		
		GameModifier.ModifierType.DOUBLE_CHANCE:
			double_chance = min(double_chance + modifier.value, 1.0)
		
		GameModifier.ModifierType.BONUS_DECAY:
			bonus_points = int(modifier.value - (current_round - 1) * 20)
			bonus_points = max(bonus_points, 0)
		
		GameModifier.ModifierType.BONUS_GROWTH:
			bonus_points += int(modifier.value * current_round)
		
		GameModifier.ModifierType.RESET_BONUS:
			reset_all_modifiers()
			add_score(int(modifier.value))
		
		GameModifier.ModifierType.SHINY_CHANCE:
			shiny_chance_bonus += modifier.value
		
		GameModifier.ModifierType.FLIP_CAMERA:
			camera_flipped = !camera_flipped
			apply_camera_flip()
		
		GameModifier.ModifierType.AUSTRALIA:
			australia_mode = !australia_mode
			apply_australia_mode()
		
		GameModifier.ModifierType.JERRY:
			pass  # Jerry does nothing
	
	modifier_applied.emit(modifier)

func apply_player_modifiers():
	var player = get_tree().get_first_node_in_group("player") as FirstPersonController
	if player:
		player.walk_speed *= speed_multiplier
		player.sprint_speed *= speed_multiplier
		player.jump_velocity *= jump_multiplier

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
	active_modifiers.clear()
	point_multiplier = 1.0
	zone_buffs.clear()
	speed_multiplier = 1.0
	jump_multiplier = 1.0
	weight_multiplier = 1.0
	double_chance = 0.0
	shiny_chance_bonus = 0.0
	camera_flipped = false
	australia_mode = false

func complete_round(mixing_pot_points: int):
	var round_score = mixing_pot_points + bonus_points
	total_score += round_score
	current_round += 1
	
	# Apply decay modifiers
	for modifier in active_modifiers:
		if modifier.modifier_type == GameModifier.ModifierType.BONUS_DECAY:
			bonus_points = max(bonus_points - 20, 0)
	
	round_completed.emit(round_score)
	score_updated.emit(total_score)

func add_score(points: int):
	total_score += points
	score_updated.emit(total_score)

func get_random_modifiers(count: int = 3) -> Array[GameModifier]:
	var shuffled = available_modifiers.duplicate()
	shuffled.shuffle()
	return shuffled.slice(0, min(count, shuffled.size()))

func should_spawn_shiny_item() -> bool:
	var base_chance = 0.05  # 5% base chance
	return randf() < (base_chance + shiny_chance_bonus)
