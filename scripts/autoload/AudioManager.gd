extends Node

var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 1.0

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx_players: int = 10

func _ready():
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	
	for i in max_sfx_players:
		var player = AudioStreamPlayer.new()
		add_child(player)
		sfx_players.append(player)

func play_music(stream: AudioStream, fade_in: bool = true):
	if fade_in and music_player.playing:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80, 0.3)
		await tween.finished
	
	music_player.stream = stream
	music_player.volume_db = linear_to_db(music_volume * master_volume)
	music_player.play()
	
	if fade_in:
		music_player.volume_db = -80
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", linear_to_db(music_volume * master_volume), 0.5)

func play_sfx(stream: AudioStream, pitch_variation: float = 0.0):
	var player = get_available_sfx_player()
	if not player:
		return
	
	player.stream = stream
	player.volume_db = linear_to_db(sfx_volume * master_volume)
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.play()

func play_random_sfx_group(streams: Array[AudioStream], pitch_variation: float = 0.0):
	play_sfx(streams[randi_range(0, len(streams))], pitch_variation)

func get_available_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	return null

func stop_music():
	music_player.stop()
