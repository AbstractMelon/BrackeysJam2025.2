extends Node

signal judging_started()
signal judge_comment(judge_name: String, comment: String)
signal judging_complete()

enum Judge {
	GRANNY_BUTTERWORTH,
	RORDAN_GAMSEY,
	PROFESSOR_BISCOTTI
}

var judge_data = {
	Judge.GRANNY_BUTTERWORTH: {
		"name": "Granny Butterworth",
		"personality": "sweet_but_brutal",
		"loves": ["sweet", "traditional", "homemade"],
		"hates": ["artificial", "overseasoned", "pretentious"]
	},
	Judge.RORDAN_GAMSEY: {
		"name": "Rordan Gamsey",
		"personality": "angry_perfectionist",
		"loves": ["custard_cream", "moist", "properly_baked"],
		"hates": ["dry", "burnt", "undercooked", "bland"]
	},
	Judge.PROFESSOR_BISCOTTI: {
		"name": "Professor Biscotti",
		"personality": "academic_analyzer",
		"loves": ["complexity", "technique", "innovation"],
		"hates": ["simple", "unoriginal", "poorly_executed"]
	}
}

var current_players: Array[GameState.PlayerData] = []
var judging_in_progress: bool = false

func start_judging(players: Array[GameState.PlayerData]):
	current_players = players
	judging_in_progress = true
	judging_started.emit()

	# Start judging cutscene
	_begin_judging_sequence()

func _begin_judging_sequence():
	print("=== JUDGING BEGINS ===")

	# Sort players by score for judging order (worst to best)
	var sorted_players = current_players.duplicate()
	sorted_players.sort_custom(func(a, b): return a.round_score < b.round_score)

	# Judge each biscuit
	for player in sorted_players:
		await _judge_player_biscuit(player)
		await get_tree().create_timer(2.0).timeout  # Pause between judgments

	judging_complete.emit()
	judging_in_progress = false

func _judge_player_biscuit(player: GameState.PlayerData):
	if not player.current_biscuit:
		return

	print("\n--- Judging ", player.name, "'s biscuit ---")

	# Each judge comments on the biscuit
	await _granny_butterworth_judges(player)
	await get_tree().create_timer(1.5).timeout

	await _rordan_gamsey_judges(player)
	await get_tree().create_timer(1.5).timeout

	await _professor_biscotti_judges(player)
	await get_tree().create_timer(1.0).timeout

func _granny_butterworth_judges(player: GameState.PlayerData):
	var biscuit = player.current_biscuit
	var comments = []

	# Sweet personality but brutal honesty
	if biscuit.total_points > 80:
		comments.append("Well dearie, this is absolutely delightful! Reminds me of my dear departed husband's favorite.")
	elif biscuit.total_points > 50:
		comments.append("Not terrible, love, but I've had better at church bake sales.")
	elif biscuit.total_points > 25:
		comments.append("Oh sweetie, what were you thinking? This wouldn't feed my cat!")
	else:
		comments.append("Bless your heart, dear. Perhaps consider taking up knitting instead.")

	# Check for specific attributes
	if "Sweet" in biscuit.special_attributes:
		comments.append("At least you got the sweetness right, poppet.")

	if "Radioactive" in biscuit.special_attributes:
		comments.append("I may be old, but I'm not blind! This thing is glowing!")

	if "Rotten" in biscuit.special_attributes:
		comments.append("Did you fish these ingredients from a garbage bin? Disgraceful!")

	if biscuit.ingredients.size() < 3:
		comments.append("Lazy baking, dear. Where's the love? Where's the effort?")

	var final_comment = comments[randi() % comments.size()]
	judge_comment.emit("Granny Butterworth", final_comment)
	print("Granny Butterworth: ", final_comment)

func _rordan_gamsey_judges(player: GameState.PlayerData):
	var biscuit = player.current_biscuit
	var comments = []

	# Always angry, hates dry food, loves custard creams
	var has_custard = false
	for ingredient in biscuit.ingredients:
		if "custard" in ingredient.item_name.to_lower() or "cream" in ingredient.item_name.to_lower():
			has_custard = true
			break

	if has_custard:
		comments.append("FINALLY! Someone who understands the beauty of custard! Magnificent!")
	elif biscuit.total_points > 90:
		comments.append("THIS IS WHAT I'M TALKING ABOUT! Perfect texture, perfect flavor! BEAUTIFUL!")
	elif biscuit.total_points > 60:
		comments.append("Not bad, but it's MISSING SOMETHING! Where's the passion?!")
	elif biscuit.total_points > 30:
		comments.append("DRY AS A DESERT! This biscuit is an insult to bakers everywhere!")
	else:
		comments.append("WHAT IS THIS?! Did you even TRY?! This is absolutely DREADFUL!")

	# Special reactions
	if "Dry" in biscuit.name.to_lower() or biscuit.ingredients.size() < 2:
		comments.append("DRY! DRY! DRY! I've eaten cardboard with more moisture!")

	if "Spicy" in biscuit.special_attributes:
		comments.append("TOO MUCH SPICE! Are you trying to burn my tongue off?!")

	if "Rotten" in biscuit.special_attributes:
		comments.append("GET THIS GARBAGE OUT OF MY SIGHT! Absolutely revolting!")

	var final_comment = comments[randi() % comments.size()]
	judge_comment.emit("Rordan Gamsey", final_comment)
	print("Rordan Gamsey: ", final_comment)

func _professor_biscotti_judges(player: GameState.PlayerData):
	var biscuit = player.current_biscuit
	var comments = []

	# Academic overanalyzer
	var complexity_score = biscuit.ingredients.size() + biscuit.special_attributes.size()

	if complexity_score > 8:
		comments.append("Fascinating! The interplay between these ingredients demonstrates a sophisticated understanding of flavor chemistry.")
	elif complexity_score > 5:
		comments.append("An adequate attempt at culinary complexity, though I detect some theoretical inconsistencies in your approach.")
	elif complexity_score > 3:
		comments.append("Rather simplistic in its construction. Where is the innovation? The creative tension?")
	else:
		comments.append("This exhibits a fundamental misunderstanding of basic baking principles. Disappointing.")

	# Analyze specific aspects
	if biscuit.total_points > 75:
		comments.append("The execution here shows clear evidence of technical proficiency and theoretical understanding.")
	elif biscuit.total_points < 25:
		comments.append("From a methodological standpoint, this represents a complete failure of basic technique.")

	# Special attribute analysis
	if "Radioactive" in biscuit.special_attributes:
		comments.append("Intriguing use of radioactive elements! Most unconventional. The molecular implications are... concerning.")

	if biscuit.special_attributes.size() > 2:
		comments.append("The multi-layered attribute profile suggests an ambitious, if not entirely successful, experimental approach.")

	if biscuit.ingredients.size() == 1:
		comments.append("Minimalism in baking can be elegant, but this appears to be mere laziness rather than artistic choice.")

	var final_comment = comments[randi() % comments.size()]
	judge_comment.emit("Professor Biscotti", final_comment)
	print("Professor Biscotti: ", final_comment)

func get_judge_name(judge: Judge) -> String:
	return judge_data[judge].name

func get_judge_personality(judge: Judge) -> String:
	return judge_data[judge].personality

func is_judging() -> bool:
	return judging_in_progress
