extends Control
class_name ItemTooltip

@onready var background: NinePatchRect = $Background
@onready var item_name_label: Label = $Background/ItemName
@onready var points_label: Label = $Background/Points
@onready var shiny_label: Label = $Background/ShinyBonus

var is_visible: bool = false
var fade_tween: Tween

func _ready():
	# Start hidden
	modulate.a = 0.0
	visible = false
	
	# Make sure tooltip appears above other UI elements
	z_index = 100
	
	if not _are_nodes_ready():
		print("WARNING: Some tooltip nodes are missing!")
		print("Background: ", background)
		print("ItemName: ", item_name_label) 
		print("Points: ", points_label)
		print("ShinyBonus: ", shiny_label)

func show_tooltip(item_data: ItemData, mouse_position: Vector2):
	if not item_data:
		return
	
	# Update tooltip content
	update_tooltip_content(item_data)
	
	# Position tooltip near mouse but keep it on screen
	position_tooltip(mouse_position)
	
	# Show with fade animation
	visible = true
	is_visible = true
	
	if fade_tween:
		fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.2)

func hide_tooltip():
	if not is_visible:
		return
		
	is_visible = false
	
	if fade_tween:
		fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.15)
	fade_tween.tween_callback(func(): visible = false)

func update_tooltip_content(item_data: ItemData):
	# Get zone information
	var zone_name = get_zone_name(item_data.zone_type)
	
	# Set item name
	item_name_label.text = item_data.item_name + " - " + zone_name
	
	# Calculate and display points
	var base_points = item_data.point_value
	var final_points = base_points
	
	if item_data.is_shiny:
		final_points = int(base_points * item_data.shiny_multiplier)
		points_label.text = "Points: %d (base: %d)" % [final_points, base_points]
		shiny_label.text = "Shiny! (×%.1f multiplier)" % item_data.shiny_multiplier
		shiny_label.visible = true
	else:
		points_label.text = "Points: %d" % final_points
		shiny_label.visible = false
	
	# Adjust background size to fit content
	await get_tree().process_frame  # Wait for labels to update

func get_zone_name(zone_type: ItemData.Zones) -> String:
	match zone_type:
		ItemData.Zones.JUNGLE:
			return "Jungle"
		ItemData.Zones.LAVA:
			return "Lava"
		ItemData.Zones.ICE:
			return "Ice"
		ItemData.Zones.CAVE:
			return "Cave"
		ItemData.Zones.CLIFF:
			return "Cliff"
		ItemData.Zones.UTILITY:
			return "Utility"
		_:
			return str(zone_type)

func position_tooltip(mouse_pos: Vector2):
	# Get viewport size
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Offset from mouse cursor
	var offset = Vector2(15, -10)
	var desired_pos = mouse_pos + offset
	
	# Make sure tooltip stays on screen
	var tooltip_size = get_tooltip_size()
	
	# Check right edge
	if desired_pos.x + tooltip_size.x > viewport_size.x:
		desired_pos.x = mouse_pos.x - tooltip_size.x - 15
	
	# Check bottom edge
	if desired_pos.y + tooltip_size.y > viewport_size.y:
		desired_pos.y = mouse_pos.y - tooltip_size.y + 10
	
	# Check left edge
	desired_pos.x = max(5, desired_pos.x)
	
	# Check top edge
	desired_pos.y = max(5, desired_pos.y)
	
	position = desired_pos

func get_tooltip_size() -> Vector2:
	# Force layout update to get accurate size
	if background:
		return background.size
	return Vector2(200, 100)  # Fallback size
	
func _are_nodes_ready() -> bool:
	return (background != null and 
			item_name_label != null and 
			points_label != null and 
			shiny_label != null)
