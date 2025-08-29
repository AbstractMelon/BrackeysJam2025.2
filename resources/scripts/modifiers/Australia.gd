extends Modifier
class_name Australia

@export var flag_texture: Texture2D = preload("res://assets/textures/australia.png")

func _init():
	types = [Globals.ModifierType.OTHER]
	name = "Australia"
	description = "Every material is replaced with the Australian flag"

func _on_modifier_gained():
	print("Australia modifier applied: Everything is now Australia!")
	var root = GameManager.get_world()
	if root:
		_replace_with_flags(root)
	GameManager.node_added.connect(_on_node_added)

func _on_modifier_removed():
	print("Australia modifier removed: Assets returned to normal")
	var root = GameManager.get_world()
	if root:
		_restore_assets(root)
	if GameManager.node_added.is_connected(_on_node_added):
		GameManager.node_added.disconnect(_on_node_added)

func _replace_with_flags(node: Node):
	if node is MeshInstance3D and node.mesh:
		if not node.has_meta("original_materials"):
			var originals: Array = []
			for i in range(node.mesh.get_surface_count()):
				originals.append(node.get_surface_override_material(i))
			node.set_meta("original_materials", originals)

		var mat := StandardMaterial3D.new()
		mat.albedo_texture = flag_texture
		mat.uv1_triplanar = true
		for i in range(node.mesh.get_surface_count()):
			node.set_surface_override_material(i, mat)

	for child in node.get_children():
		_replace_with_flags(child)

func _restore_assets(node: Node):
	if node is MeshInstance3D and node.has_meta("original_materials"):
		var originals: Array = node.get_meta("original_materials")
		for i in range(min(node.mesh.get_surface_count(), originals.size())):
			node.set_surface_override_material(i, originals[i])
		node.remove_meta("original_materials")

	for child in node.get_children():
		_restore_assets(child)

func _on_node_added(node: Node):
	_replace_with_flags(node)

func _trigger():
	pass
