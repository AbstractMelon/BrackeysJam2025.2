extends Node3D
class_name GameController

signal game_started()
signal game_ended()

@onready var player: FirstPersonController = $Player
@onready var mixing_pot: MixingPot = $LocationContainer/Kitchen/MixingPot
@onready var item_spawner: ItemSpawner = $LocationContainer/Kitchen/ItemSpawner
@onready var game_ui: GameUI = $GameUI

@export var npc_mixing_pots: Array[MixingPot] = []

func _ready():
	add_to_group("game_controller")

	# Wait for autoloads to be ready
	call_deferred("_initialize_game")

func _initialize_game():
	# Connect signals
	GameLoop.state_changed.connect(_on_game_state_changed)
	GameLoop.round_started.connect(_on_round_started)
	GameLoop.round_ended.connect(_on_round_ended)
	GameLoop.player_eliminated.connect(_on_player_eliminated)
	GameLoop.game_over.connect(_on_game_over)

	JudgeSystem.judging_started.connect(_on_judging_started)
	JudgeSystem.judge_comment.connect(_on_judge_comment)
	JudgeSystem.judging_complete.connect(_on_judging_complete)

	# Start the game
	GameLoop.start_new_game()

func _on_game_state_changed(new_state: GameState.State):
	match new_state:
		GameState.State.SETUP:
			_setup_round()
		GameState.State.BAKING:
			_start_baking()
		GameState.State.JUDGING:
			_start_judging()
		GameState.State.ELIMINATION:
			_handle_elimination()
		GameState.State.MODIFIER_SELECTION:
			_show_modifier_selection()
		GameState.State.GAME_OVER:
			_handle_game_over()
		GameState.State.VICTORY:
			_handle_victory()

func _setup_round():
	print("[GameController] Setting up round ", GameLoop.get_current_round())

	# Reset player mixing pot
	if mixing_pot:
		mixing_pot.mixed_items.clear()
		mixing_pot.base_points = 0
		mixing_pot.update_ui()

	# Reset NPC mixing pots
	for pot in npc_mixing_pots:
		if pot:
			pot.mixed_items.clear()
			pot.base_points = 0
			pot.update_ui()

	# Assign pots to alive players
	_assign_pots_to_players()

func _assign_pots_to_players():
	var alive_players = GameLoop.get_alive_players()
	var pot_index = 0

	for player in alive_players:
		if player.is_human:
			player.mixing_pot = mixing_pot
		else:
			if pot_index < npc_mixing_pots.size():
				player.mixing_pot = npc_mixing_pots[pot_index]
				pot_index += 1

func _start_baking():
	print("[GameController] Starting baking phase")
	game_started.emit()

	# Enable player movement if disabled
	if player:
		player.set_physics_process(true)
		player.set_process_input(true)

func _start_judging():
	print("[GameController] Starting judging phase")

	# Disable player movement during judging
	#if player:
		#player.set_physics_process(false)
		#player.set_process_input(false)

func _handle_elimination():
	print("[GameController] Handling elimination")

	# The GameLoop handles the actual elimination logic
	# We just need to update the visual representation

func _show_modifier_selection():
	print("[GameController] Showing modifier selection")
	# UI handles this automatically

func _handle_game_over():
	print("[GameController] Game Over!")
	game_ended.emit()

	# Disable player controls
	if player:
		player.set_physics_process(false)
		player.set_process_input(false)

	# Stop all spawning
	if item_spawner:
		item_spawner.stop_round_spawning()

func _handle_victory():
	print("[GameController] Victory!")
	game_ended.emit()

	# Disable player controls
	if player:
		player.set_physics_process(false)
		player.set_process_input(false)

	# Stop all spawning
	if item_spawner:
		item_spawner.stop_round_spawning()

	# Maybe play victory animation/sound

func _on_round_started(round_number: int):
	print("[GameController] Round ", round_number, " started")

func _on_round_ended(round_number: int):
	print("[GameController] Round ", round_number, " ended")

func _on_player_eliminated(player: GameState.PlayerData):
	print("[GameController] Player eliminated: ", player.name)

	# Hide their mixing pot if it's an NPC
	if not player.is_human and player.mixing_pot:
		player.mixing_pot.visible = false

func _on_game_over(winner: GameState.PlayerData):
	if winner:
		print("[GameController] Game won by: ", winner.name)
	else:
		print("[GameController] Game over - player eliminated")

func _on_judging_started():
	print("[GameController] Judging cutscene started")

func _on_judge_comment(judge_name: String, comment: String, comment_type: int):
	# Show comment in UI
	if game_ui:
		game_ui.show_judge_comment(judge_name, comment)

func _on_judging_complete():
	print("[GameController] Judging complete")
	GameLoop.change_state(GameState.State.ELIMINATION)

func get_player_mixing_pot() -> MixingPot:
	return mixing_pot

func get_npc_mixing_pots() -> Array[MixingPot]:
	return npc_mixing_pots

func restart_game():
	# Reset everything and start a new game
	GameLoop.start_new_game()

func quit_to_menu():
	SceneManager.load_scene("res://scenes/main_menu.tscn")
