extends Node

enum State {
	MENU,
	SETUP,
	BAKING,
	JUDGING,
	ELIMINATION,
	MODIFIER_SELECTION,
	GAME_OVER,
	VICTORY
}

# Player data structure
class PlayerData:
	var player_id: int
	var name: String
	var is_human: bool
	var is_alive: bool = true
	var mixing_pot: MixingPot
	var station_position: Vector3
	var current_biscuit: BiscuitData
	var total_score: int = 0
	var round_score: int = 0

	func _init(id: int, player_name: String, human: bool = false):
		player_id = id
		name = player_name
		is_human = human

# Biscuit data structure
class BiscuitData:
	var name: String
	var description: String
	var base_points: int
	var modifier_points: int
	var total_points: int
	var ingredients: Array[ItemData] = []
	var special_attributes: Array[String] = []
	var texture: Texture2D
	var mesh: Mesh

	func generate_from_pot(pot: MixingPot, points: int):
		ingredients = pot.mixed_items.duplicate()
		base_points = pot.base_points
		total_points = points
		modifier_points = points - base_points
		_generate_biscuit_properties()

	func _generate_biscuit_properties():
		var attributes: Array[String] = []
		var name_parts = ["Basic"]
		var descriptions = []

		# Check for special item attributes
		for item in ingredients:
			if "radioactive" in item.item_name.to_lower():
				attributes.append("Radioactive")
				name_parts.append("Glowing")
				descriptions.append("emits a faint green glow")

			if "spicy" in item.item_name.to_lower():
				attributes.append("Spicy")
				name_parts.append("Fiery")
				descriptions.append("burns the tongue")

			if "sweet" in item.item_name.to_lower():
				attributes.append("Sweet")
				name_parts.append("Heavenly")
				descriptions.append("melts in your mouth")

			if "rotten" in item.item_name.to_lower():
				attributes.append("Rotten")
				name_parts.append("Cursed")
				descriptions.append("smells questionable")

		# Point-based modifiers
		if total_points > 100:
			name_parts.append("Supreme")
			descriptions.append("crafted to perfection")
		elif total_points > 75:
			name_parts.append("Deluxe")
			descriptions.append("expertly prepared")
		elif total_points > 50:
			name_parts.append("Quality")
			descriptions.append("well-made")
		elif total_points < 20:
			name_parts.append("Disappointing")
			descriptions.append("barely edible")

		# Generate final name and description
		if name_parts.size() > 1:
			name_parts.erase("Basic")

		name = " ".join(name_parts) + " Biscuit"

		if descriptions.size() > 0:
			description = "A biscuit that " + descriptions[0]
			for i in range(1, descriptions.size()):
				description += " and " + descriptions[i]
		else:
			description = "A simple biscuit"

		special_attributes = attributes
