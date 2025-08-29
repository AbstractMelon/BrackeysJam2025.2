extends RichTextLabel
class_name TypewriterEffect

signal typing_finished()
signal character_typed(character: String)

@export var typing_speed: float = 0.05  # Time between characters
@export var auto_start: bool = false
@export var skip_on_input: bool = true

var full_text: String = ""
var current_index: int = 0
var is_typing: bool = false
var typing_timer: Timer

func _ready():
	typing_timer = Timer.new()
	typing_timer.wait_time = typing_speed
	typing_timer.timeout.connect(_type_next_character)
	add_child(typing_timer)

	if auto_start and text != "":
		start_typewriter(text)

func _input(event):
	if skip_on_input and is_typing:
		if event.is_pressed() and (event is InputEventKey or event is InputEventMouseButton):
			skip_to_end()

func start_typewriter(new_text: String):
	full_text = new_text
	current_index = 0
	is_typing = true
	text = ""

	if full_text.length() == 0:
		typing_finished.emit()
		return

	typing_timer.start()

func _type_next_character():
	if current_index >= full_text.length():
		finish_typing()
		return

	var character = full_text[current_index]
	text += character
	current_index += 1

	character_typed.emit(character)

	# Adjust timing for punctuation
	if character in ".!?":
		typing_timer.wait_time = typing_speed * 3  # Pause longer after sentences
	elif character in ",;:":
		typing_timer.wait_time = typing_speed * 2  # Pause for commas and semicolons
	else:
		typing_timer.wait_time = typing_speed

func skip_to_end():
	if not is_typing:
		return

	typing_timer.stop()
	text = full_text
	current_index = full_text.length()
	finish_typing()

func finish_typing():
	is_typing = false
	typing_timer.stop()
	typing_finished.emit()

func is_currently_typing() -> bool:
	return is_typing

func set_typing_speed(new_speed: float):
	typing_speed = new_speed
	if typing_timer:
		typing_timer.wait_time = typing_speed

func pause_typing():
	if is_typing:
		typing_timer.paused = true

func resume_typing():
	if is_typing:
		typing_timer.paused = false

func stop_typing():
	is_typing = false
	typing_timer.stop()
	current_index = 0
	text = ""
