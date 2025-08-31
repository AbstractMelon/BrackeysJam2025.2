extends Node3D
class_name JudgePresentation

signal camera_transition_complete()

@export_group("Camera Settings")
@export var transition_duration: float = 1.5
@export var camera_offset: Vector3 = Vector3(0, 1.8, 2.5)
@export var camera_look_offset: Vector3 = Vector3(0, 1.5, 0)

@export_group("Audio Settings")
@export var voice_volume: float = 0.0

@onready var camera_rig: Node3D = $CameraRig
@onready var judge_camera: Camera3D = $CameraRig/JudgeCamera

@onready var granny_audio: AudioStreamPlayer3D = $AudioPlayers/GrannyAudio
@onready var rordan_audio: AudioStreamPlayer3D = $AudioPlayers/RordanAudio
@onready var professor_audio: AudioStreamPlayer3D = $AudioPlayers/ProfessorAudio

var voice_clips: Dictionary = {}
var audio_players: Dictionary = {}
var judge_nodes: Dictionary = {}
var current_judge: String = ""
var original_camera: Camera3D
var is_presenting: bool = false
var camera_tween: Tween

func _ready():
	_setup_audio_players()
	_load_voice_clips()
	_setup_camera()
	_find_judge_nodes()

func _setup_audio_players():
	audio_players = {
		"granny_butterworth": granny_audio,
		"rordan_gamsey": rordan_audio,
		"professor_biscotti": professor_audio
	}

	# Set up audio properties
	for player in audio_players.values():
		player.volume_db = voice_volume
		player.max_distance = 20.0
		player.unit_size = 1.0

func _load_voice_clips():
	voice_clips = {
		"granny_butterworth": {
			"Happy": preload("res://assets/audio/voice/granny_butterworth/GrannyHappy.ogg"),
			"Sad": preload("res://assets/audio/voice/granny_butterworth/GrannySad.ogg"),
			"Angry": preload("res://assets/audio/voice/granny_butterworth/GrannyAngry.ogg"),
			"Disappointed": preload("res://assets/audio/voice/granny_butterworth/GrannyDisappointed.ogg")
		},
		"rordan_gamsey": {
			"Happy": preload("res://assets/audio/voice/rordan_gamsey/GamseyHappy.ogg"),
			"Sad": preload("res://assets/audio/voice/rordan_gamsey/GamseySad.ogg"),
			"Angry": preload("res://assets/audio/voice/rordan_gamsey/GamseyAngry.ogg"),
			"Disappointed": preload("res://assets/audio/voice/rordan_gamsey/GamseyDisappointed.ogg")
		},
		"professor_biscotti": {
			"Happy": preload("res://assets/audio/voice/professor_biscotti/BiscottiHappy.ogg"),
			"Sad": preload("res://assets/audio/voice/professor_biscotti/BiscottiSad.ogg"),
			"Angry": preload("res://assets/audio/voice/professor_biscotti/BiscottiAngry.ogg"),
			"Disappointed": preload("res://assets/audio/voice/professor_biscotti/BiscottiDisappointed.ogg")
		}
	}

func _setup_camera():
	judge_camera.current = false
	var viewport = get_viewport()
	if viewport:
		original_camera = viewport.get_camera_3d()

func _find_judge_nodes():
	# Find the existing judge nodes in the kitchen scene
	var grandma = get_node_or_null("../../LocationContainer/Kitchen/Judges/Grandma")
	var rordon = get_node_or_null("../../LocationContainer/Kitchen/Judges/Rordon")
	var biscotti = get_node_or_null("../../LocationContainer/Kitchen/Judges/Biscotti")

	if grandma:
		judge_nodes["granny_butterworth"] = grandma
		print("[JudgePresentation] Found Granny at: ", grandma.global_position)
	else:
		print("[JudgePresentation] WARNING: Could not find Grandma judge node")

	if rordon:
		judge_nodes["rordan_gamsey"] = rordon
		print("[JudgePresentation] Found Rordan at: ", rordon.global_position)
	else:
		print("[JudgePresentation] WARNING: Could not find Rordon judge node")

	if biscotti:
		judge_nodes["professor_biscotti"] = biscotti
		print("[JudgePresentation] Found Professor at: ", biscotti.global_position)
	else:
		print("[JudgePresentation] WARNING: Could not find Biscotti judge node")

	if judge_nodes.is_empty():
		print("[JudgePresentation] ERROR: No judge nodes found! Check scene structure.")

func start_judge_presentation():
	if is_presenting:
		print("[JudgePresentation] Already presenting, ignoring start request")
		return

	print("[JudgePresentation] Starting judge presentation")
	is_presenting = true

	# Store original camera
	var viewport = get_viewport()
	if viewport:
		original_camera = viewport.get_camera_3d()
		print("[JudgePresentation] Stored original camera: ", original_camera)

	# Switch to judge camera
	if original_camera:
		original_camera.current = false
	judge_camera.current = true
	print("[JudgePresentation] Switched to judge camera")

func end_judge_presentation():
	if not is_presenting:
		print("[JudgePresentation] Not currently presenting, ignoring end request")
		return

	print("[JudgePresentation] Ending judge presentation")
	is_presenting = false

	# Switch back to original camera
	judge_camera.current = false
	if original_camera:
		original_camera.current = true
		print("[JudgePresentation] Switched back to original camera")

	current_judge = ""

func focus_on_judge(judge_key: String):
	print("[JudgePresentation] Focusing camera on judge: ", judge_key)

	if not judge_key in judge_nodes:
		print("[JudgePresentation] ERROR: Unknown judge: ", judge_key)
		return

	current_judge = judge_key
	var judge_node = judge_nodes[judge_key]
	var target_position = judge_node.global_position + camera_offset
	var look_target = judge_node.global_position + camera_look_offset

	print("[JudgePresentation] Moving camera to position: ", target_position)

	# Kill any existing tween
	if camera_tween:
		camera_tween.kill()

	camera_tween = create_tween()
	camera_tween.set_parallel(true)

	# Animate camera position
	camera_tween.tween_property(camera_rig, "global_position", target_position, transition_duration)

	# Animate camera look direction
	var tween_method = func(progress: float):
		judge_camera.look_at(look_target, Vector3.UP)

	camera_tween.tween_method(tween_method, 0.0, 1.0, transition_duration)

	await camera_tween.finished
	print("[JudgePresentation] Camera transition complete for ", judge_key)
	camera_transition_complete.emit()

func play_voice_line(judge_key: String, mood: String):
	print("[JudgePresentation] Playing voice line for ", judge_key, " with mood: ", mood)

	if not judge_key in voice_clips:
		print("[JudgePresentation] ERROR: No voice clips for judge: ", judge_key)
		return

	if not mood in voice_clips[judge_key]:
		print("[JudgePresentation] ERROR: No voice clip for mood: ", mood, " for judge: ", judge_key)
		return

	if not judge_key in audio_players:
		print("[JudgePresentation] ERROR: No audio player for judge: ", judge_key)
		return

	var audio_player = audio_players[judge_key]
	var voice_clip = voice_clips[judge_key][mood]

	if not audio_player:
		print("[JudgePresentation] ERROR: Audio player is null for judge: ", judge_key)
		return

	if not voice_clip:
		print("[JudgePresentation] ERROR: Voice clip is null for judge: ", judge_key, " mood: ", mood)
		return

	print("[JudgePresentation] Playing voice clip for ", judge_key)
	audio_player.stream = voice_clip
	audio_player.play()

func determine_mood_from_comment(judge_key: String, comment: String, comment_type: String, score: int) -> String:
	# Determine mood based on judge personality and comment content
	match judge_key:
		"granny_butterworth":
			if score >= 70:
				return "Happy"
			elif score >= 40:
				return "Disappointed"
			elif score >= 20:
				return "Sad"
			else:
				return "Angry"

		"rordan_gamsey":
			if score >= 80:
				return "Happy"
			elif score >= 50:
				return "Disappointed"
			elif score >= 25:
				return "Angry"
			else:
				return "Angry"  # Rordan is almost always angry

		"professor_biscotti":
			if score >= 75:
				return "Happy"
			elif score >= 50:
				return "Disappointed"
			elif score >= 25:
				return "Sad"
			else:
				return "Disappointed"

	return "Disappointed"  # Default mood

func stop_all_audio():
	for player in audio_players.values():
		if player.playing:
			player.stop()

func is_camera_active() -> bool:
	return judge_camera.current

func get_current_judge() -> String:
	return current_judge
