extends Node
class_name NPCController

signal npc_action_completed(npc: GameState.PlayerData, action: String)

var active_npcs: Array[GameState.PlayerData] = []
var baking_difficulty: float = 1.0
var is_baking: bool = false
var MixingPotScene := preload("res://scenes/components/mixing_pot.tscn") 

# NPC behavior timers
var npc_timers: Dictionary = {}
var item_spawner: Node

func _ready():
	# Find item spawner in scene
	call_deferred("_find_item_spawner")

func _find_item_spawner():
	item_spawner = get_tree().get_first_node_in_group("item_spawner")

func start_baking(npcs: Array[GameState.PlayerData], difficulty: float):
	active_npcs = npcs
	baking_difficulty = difficulty
	is_baking = true

	# Initialize timers for each NPC
	for npc in active_npcs:
		npc_timers[npc.player_id] = 0.0

	# Start NPC behavior
	_initialize_npc_pots()

func _initialize_npc_pots():
	# Create mixing pots for NPCs if they don't have them
	for npc in active_npcs:
		if not npc.mixing_pot:
			npc.mixing_pot = _create_npc_mixing_pot(npc)

func _create_npc_mixing_pot(npc: GameState.PlayerData) -> MixingPot:
	var pot = MixingPotScene.instantiate() as MixingPot
	pot.name = "NPC_MixingPot_" + str(npc.player_id)
	add_child(pot)
	return pot

func stop_baking():
	is_baking = false
	active_npcs.clear()
	npc_timers.clear()

func _process(delta):
	if not is_baking:
		return

	for npc in active_npcs:
		if npc.player_id in npc_timers:
			npc_timers[npc.player_id] += delta
			_update_npc_behavior(npc, delta)

func _update_npc_behavior(npc: GameState.PlayerData, delta: float):
	var timer_value = npc_timers[npc.player_id]

	# NPCs collect items at different intervals based on difficulty
	var collection_interval = _get_npc_collection_interval(npc)

	if fmod(timer_value, collection_interval) < delta:
		_npc_collect_item(npc)

func _get_npc_collection_interval(npc: GameState.PlayerData) -> float:
	# Base interval modified by difficulty and NPC "skill level"
	var base_interval = 8.0  # 8 seconds base
	var npc_skill = _get_npc_skill_level(npc)
	var difficulty_modifier = 1.0 / baking_difficulty

	return base_interval * difficulty_modifier * (2.0 - npc_skill)

func _get_npc_skill_level(npc: GameState.PlayerData) -> float:
	# Different NPCs have different skill levels
	match npc.name:
		"Chef Crumbleton":
			return 0.9  # Very skilled
		"Baker Betty":
			return 0.8  # Skilled
		"Flour Power Fred":
			return 0.7  # Good
		"Dough Master Dan":
			return 0.8  # Skilled
		"Sweet Sally":
			return 0.6  # Average
		"Crispy Carl":
			return 0.5  # Below average
		"Buttery Bob":
			return 0.4  # Poor
		_:
			return 0.5  # Default

func _npc_collect_item(npc: GameState.PlayerData):
	if not item_spawner or not npc.mixing_pot:
		return

	# Get available items from spawner
	var available_items = _get_available_items()
	if available_items.is_empty():
		return

	# NPC item selection strategy based on skill and round
	var selected_item = _select_item_for_npc(npc, available_items)
	if selected_item:
		_npc_add_item_to_pot(npc, selected_item)

func _get_available_items() -> Array:
	# Get items that are currently spawned in the world
	var items = []
	var pickup_items = get_tree().get_nodes_in_group("pickup_items")

	for item in pickup_items:
		if item is PickupableItem and not item.is_being_carried:
			items.append(item)

	return items

func _select_item_for_npc(npc: GameState.PlayerData, available_items: Array) -> PickupableItem:
	if available_items.is_empty():
		return null

	var npc_skill = _get_npc_skill_level(npc)

	# Higher skill NPCs make better choices
	if npc_skill > 0.7 and randf() < 0.7:
		# Smart selection - prefer high value items
		return _select_best_item(available_items)
	elif npc_skill > 0.4 and randf() < 0.5:
		# Decent selection - avoid obviously bad items
		return _select_decent_item(available_items)
	else:
		# Random selection
		return available_items[randi() % available_items.size()]

func _select_best_item(available_items: Array) -> PickupableItem:
	var best_item = null
	var best_value = -1

	for item in available_items:
		if item is PickupableItem and item.item_data:
			var value = item.get_point_value()
			if value > best_value:
				best_value = value
				best_item = item

	return best_item if best_item else available_items[randi() % available_items.size()]

func _select_decent_item(available_items: Array) -> PickupableItem:
	# Filter out items that are obviously bad (negative value, rotten, etc.)
	var decent_items = []

	for item in available_items:
		if item is PickupableItem and item.item_data:
			var item_name = item.item_data.item_name.to_lower()
			var point_value = item.get_point_value()

			# Avoid obviously bad items
			if point_value >= 5 and not ("rotten" in item_name or "poison" in item_name or "cursed" in item_name):
				decent_items.append(item)

	if decent_items.is_empty():
		return available_items[randi() % available_items.size()]
	else:
		return decent_items[randi() % decent_items.size()]

func _npc_add_item_to_pot(npc: GameState.PlayerData, item: PickupableItem):
	if not npc.mixing_pot or not item:
		return

	# Simulate the NPC picking up and mixing the item
	var points = GameManager.calculate_item_points(item)
	npc.mixing_pot.base_points += points
	npc.mixing_pot.mixed_items.append(item.item_data)

	# Remove item from world
	item.queue_free()

	# Update NPC pot score data
	npc.mixing_pot.update_score_data()

	npc_action_completed.emit(npc, "item_collected")

	print("NPC ", npc.name, " collected ", item.item_data.item_name, " for ", points, " points")

func get_npc_progress(npc: GameState.PlayerData) -> Dictionary:
	var progress = {
		"items_collected": 0,
		"current_points": 0,
		"skill_level": _get_npc_skill_level(npc)
	}

	if npc.mixing_pot:
		progress.items_collected = npc.mixing_pot.mixed_items.size()
		progress.current_points = npc.mixing_pot.get_current_points()

	return progress

func get_all_npc_progress() -> Dictionary:
	var all_progress = {}
	for npc in active_npcs:
		all_progress[npc.player_id] = get_npc_progress(npc)
	return all_progress
