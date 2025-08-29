extends Modifier
class_name CameraFlip

func _init():
	types = [Globals.ModifierType.OTHER]
	name = "Topsy Turvy"
	description = "Flips camera upside down"

func _on_modifier_created():
	pass

func _on_modifier_gained():
	var player = GameManager.get_player() 
	print("Topsy Turvy modifier applied: Camera flipped upside down!")
	_flip_camera(player, true)

func _on_modifier_removed():
	var player = GameManager.get_player()
	print("Topsy Turvy modifier removed: Camera returned to normal")
	_flip_camera(player, false)


func _flip_camera(player: FirstPersonController, flip: bool):
	if player and player.camera:
		player.camera.rotation_degrees.z = 180 if flip else 0

func _trigger():
	# This modifier's effect is permanent while active
	pass
