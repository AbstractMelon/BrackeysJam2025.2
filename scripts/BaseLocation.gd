extends Node3D
class_name BaseLocation

signal return_requested()

@onready var return_pad: Area3D = $ReturnPad

func _ready():
	if return_pad:
		return_pad.body_entered.connect(_on_return_pad_body_entered)
		return_requested.connect(LocationManager.return_to_kitchen)
	else:
		print("[BaseLocation] Warning: No ReturnPad found in ", name)

func _on_return_pad_body_entered(body):
	if body.is_in_group("player"):
		print("[BaseLocation] Player stepped on return pad")
		return_requested.emit() 
