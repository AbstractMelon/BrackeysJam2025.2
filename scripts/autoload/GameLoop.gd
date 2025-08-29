extends Node

signal state_changed(new_state: GameState.State)
signal round_started(round_number: int)
signal round_ended(round_number: int)
signal player_eliminated(player: GameState.PlayerData)
signal game_over(winner: GameState.PlayerData)
signal timer_updated(time_left: float)

const NPC_NAMES: Array[String] = [
	"Chef Crumbleton", "Baker Betty", "Flour Power Fred",
	"Dough Master Dan", "Sweet Sally", "Crispy Carl", "Buttery Bob"
]

var baking_time: float = 30.0  # 5 minutes - 300 seconds
var current_state: GameState.State = GameState.State.MENU
var current_round: int = 1
var baking_timer: float = 0.0
var players: Array[GameState.PlayerData] = []
var human_player: GameState.PlayerData
var alive_players: Array[GameState.PlayerData] = []
var stations: Array[Vector3] = [Vector3(0, 0, 0), Vector3(0, 0, 0), Vector3(0, 0, 0), Vector3(0, 0, 0), Vector3(0, 0, 0), Vector3(0, 0, 0), Vector3(0, 0, 0), Vector3(0, 0, 0), ]
var round_difficulty: float = 1.0


@onready var timer: Timer = Timer.new()
@onready var npc_controller = NPCController.new()

func _ready():
	add_child(timer)
	add_child(npc_controller)
	timer.timeout.connect(_on_timer_timeout)

func start_new_game():
	_initialize_players()
	current_round = 1
	round_difficulty = 1.0
	change_state(GameState.State.SETUP)

func _initialize_players():
	players.clear()
	alive_players.clear()

	# Create human player
	human_player = GameState.PlayerData.new(0, "You", true)
	human_player.station_position = stations[0]
	players.append(human_player)
	alive_players.append(human_player)

	# Create NPC players
	for i in range(7):
		var npc = GameState.PlayerData.new(i + 1, NPC_NAMES[i], false)
		npc.station_position = stations[i + 1]
		players.append(npc)
		alive_players.append(npc)

	_assign_mixing_pots()

func _assign_mixing_pots():
	var game_scene = get_tree().current_scene
	if not game_scene:
		return

	# Human pot 
	var mixing_pot = game_scene.get_node("LocationContainer/Kitchen/MixingPot") as MixingPot
	if mixing_pot:
		human_player.mixing_pot = mixing_pot

	# NPC pots
	var npc_pots_parent = game_scene.get_node("LocationContainer/Kitchen/MixingPots")
	if npc_pots_parent:
		var pots = npc_pots_parent.get_children()
		var npc_index = 0
		
		# Assign pots to NPC players only
		for player in players:
			if not player.is_human and npc_index < pots.size():
				player.mixing_pot = pots[npc_index]
				npc_index += 1

func change_state(new_state: GameState.State):
	var old_state = current_state
	current_state = new_state
	_handle_state_change(old_state, new_state)
	state_changed.emit(new_state)

func _handle_state_change(_old_state: GameState.State, new_state: GameState.State):
	match new_state:
		GameState.State.SETUP:
			_setup_round()
		GameState.State.BAKING:
			_start_baking_phase()
		GameState.State.JUDGING:
			_start_judging_phase()
		GameState.State.ELIMINATION:
			_start_elimination_phase()
		GameState.State.MODIFIER_SELECTION:
			_start_modifier_selection()
		GameState.State.GAME_OVER:
			_handle_game_over()
		GameState.State.VICTORY:
			_handle_victory()

func _setup_round():
	print("Setting up round ", current_round)
	round_difficulty = 1.0 + (current_round - 1) * 0.3  # Increase difficulty each round

	# Reset player scores for this round
	for player in alive_players:
		player.round_score = 0
		player.current_biscuit = null

	# Spawn items based on difficulty
	_spawn_round_items()

	# Start baking phase
	change_state(GameState.State.BAKING)

func _spawn_round_items():
	var item_spawner = get_tree().get_first_node_in_group("item_spawner")
	if item_spawner and item_spawner.has_method("spawn_items_for_round"):
		var item_count = int(8 + current_round * 2)  # More items each round
		item_spawner.spawn_items_for_round(item_count, round_difficulty)

func _start_baking_phase():
	print("Baking phase started! Round ", current_round)
	baking_timer = baking_time

	round_started.emit(current_round)

	# Start NPC baking behavior
	npc_controller.start_baking(alive_players.filter(func(p): return not p.is_human), round_difficulty)

	# Start countdown timer
	timer.wait_time = 0.1  # Update every 100ms for smooth timer
	timer.start()

func _on_timer_timeout():
	if current_state == GameState.State.BAKING:
		baking_timer -= 0.1
		timer_updated.emit(baking_timer)

		if baking_timer <= 0:
			end_baking_phase()

func end_baking_phase():
	print("Baking phase ended!")
	timer.stop()
	npc_controller.stop_baking()

	# Generate biscuits for all players
	_generate_all_biscuits()

	change_state(GameState.State.JUDGING)

func _generate_all_biscuits():
	for player in alive_players:
		if player.mixing_pot:
			var points = player.mixing_pot.get_current_points()
			player.current_biscuit = GameState.BiscuitData.new()
			player.current_biscuit.generate_from_pot(player.mixing_pot, points)
			player.round_score = points

func _start_judging_phase():
	print("Judging phase started!")
	# This will trigger the judge cutscene
	JudgeSystem.start_judging(alive_players)

func _start_elimination_phase():
	print("Elimination phase started!")

	# Find player with worst biscuit
	var worst_player = _find_worst_player()
	if worst_player:
		_eliminate_player(worst_player)

func _find_worst_player() -> GameState.PlayerData:
	var worst_score = INF
	var worst_player = null

	for player in alive_players:
		if player.current_biscuit and player.round_score < worst_score:
			worst_score = player.round_score
			worst_player = player

	return worst_player

func _eliminate_player(player: GameState.PlayerData):
	print("Eliminating player: ", player.name)
	player.is_alive = false
	alive_players.erase(player)
	player_eliminated.emit(player)

	# Check win/lose conditions
	if not human_player.is_alive:
		change_state(GameState.State.GAME_OVER)
	elif alive_players.size() <= 1:
		change_state(GameState.State.VICTORY)
	else:
		await wait(3)
		change_state(GameState.State.MODIFIER_SELECTION)

func _start_modifier_selection():
	print("Modifier selection phase started!")
	# Show modifier selection UI to human player
	var ui = get_tree().get_first_node_in_group("game_ui")
	if ui and ui.has_method("show_modifier_selection"):
		ui.show_modifier_selection()

func on_modifier_selected():
	# Called when human player selects a modifier
	current_round += 1
	round_ended.emit(current_round - 1)
	change_state(GameState.State.SETUP)

func _handle_game_over():
	print("Game Over!")
	game_over.emit(null)
		
	await wait(3.0)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	SceneManager.goto_scene("res://scenes/main_menu.tscn", 3)

func _handle_victory():
	print("Victory!")
	game_over.emit(human_player)
	
	await wait(3.0)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	SceneManager.goto_scene("res://scenes/main_menu.tscn", 3)

func force_end_baking():
	# Called when player presses end baking button
	if current_state == GameState.State.BAKING:
		end_baking_phase()

func get_time_remaining() -> float:
	return baking_timer

func get_alive_players() -> Array[GameState.PlayerData]:
	return alive_players

func get_current_round() -> int:
	return current_round

func is_human_player_alive() -> bool:
	return human_player.is_alive

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
