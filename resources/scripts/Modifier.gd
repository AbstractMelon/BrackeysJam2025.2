extends Resource
class_name GameModifier

enum ModifierType {
	POINT_MULTIPLIER,
	ZONE_BUFF,
	SPEED_JUMP,
	WEIGHT_CARRY,
	DOUBLE_CHANCE,
	BONUS_DECAY,
	BONUS_GROWTH,
	RESET_BONUS,
	SHINY_CHANCE,
	FLIP_CAMERA,
	JERRY,
	HEIGHT_INCREASE,
	POISON_RESIST,
	AUSTRALIA
}

@export var modifier_name: String = "New Modifier"
@export var modifier_type: ModifierType
@export var description: String = ""
@export var value: float = 1.0
@export var zone_target: String = ""  # For zone-specific buffs
@export var icon: Texture2D
