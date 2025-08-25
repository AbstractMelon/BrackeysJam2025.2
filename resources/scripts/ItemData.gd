extends Resource
class_name ItemData

@export var item_name: String = "New Item"
@export var point_value: int = 10
@export var zone_type: String = "jungle"  # jungle, lava, ice, cave, cliff
@export var icon: Texture2D
@export var mesh: Mesh
@export var material: Material
@export var is_shiny: bool = false
@export var shiny_multiplier: float = 2.0
