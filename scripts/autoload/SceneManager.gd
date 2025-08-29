extends Node

signal scene_changed

var current_scene = null
var is_transitioning = false

func _ready():
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)

func goto_scene(path: String, transition_duration: float = 0.3):
	if is_transitioning:
		return
	is_transitioning = true

	# Simple fade transition
	var tween = create_tween()
	var overlay = ColorRect.new()
	overlay.color = Color.BLACK
	overlay.color.a = 0.0
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().root.add_child(overlay)

	# Fade out
	tween.tween_property(overlay, "color:a", 1.0, transition_duration / 2)
	await tween.finished

	# Change scene immediately without additional fade
	call_deferred("_deferred_goto_scene", path, overlay, transition_duration / 2)

func _deferred_goto_scene(path: String, overlay: ColorRect, fade_out_time: float):
	current_scene.free()
	var new_scene = ResourceLoader.load(path)
	current_scene = new_scene.instantiate()
	get_tree().root.add_child(current_scene)
	get_tree().current_scene = current_scene

	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.0, fade_out_time)
	await tween.finished
	overlay.queue_free()
	is_transitioning = false
	scene_changed.emit()
