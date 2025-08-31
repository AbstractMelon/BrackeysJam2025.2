extends Node

signal judging_started()
signal judge_comment(judge_name: String, comment: String, comment_type: String)
signal judge_reaction(judge_name: String, reaction: String)
signal judging_complete()
signal update_victim(player_name: String)
signal judge_focus_requested(judge_key: String)
signal judge_voice_requested(judge_key: String, mood: String)

@export var single_comment_per_judge: bool = true
@export var comment_display_time: float = 4.0
@export var typing_speed: float = 0.03

@export var judge_data: Dictionary = {
	"granny_butterworth": {
		"name": "Granny Butterworth",
		"praise_threshold": 50,
		"initial_moods": {"patience": 1.0, "nostalgia": 1.0},
		"comment_pool": ["primary", "story", "technical", "emotional"],
		"comment_sequence": [
			{"type": "primary", "chance": 1.0},
			{"type": "story", "chance": 0.6},
			{"type": "technical", "chance": 0.7},
			{"type": "emotional", "chance": 0.5}
		],
		"comments": {
			"primary": {
				"type": "comment",
				"score_tiers": {
					80: ["Oh darling, this could win the county fair three years running!", "Well dearie, this is simply scrumptious. Brings a tear to my eye.", "My stars, I haven't tasted something this good since 1947!", "Bless your heart, this is exactly how my mother used to make them!", "Sweetie, you've got the touch! This is pure magic!"],
					50: ["Not terrible, love, but I've had better at Tuesday bingo night.", "It's edible, dear, which is more than I expected.", "Sweetie, I'd serve this to guests I don't like very much.", "Well, it's not the worst thing I've ever tasted, bless your heart.", "Dearie, this needs a bit more love in the mixing bowl."],
					25: ["Oh sweetie, were you trying to bake or to start a fire?", "This wouldn't fool a raccoon on garbage day.", "Bless your heart, dear, but this belongs in the compost.", "My stars, what happened in that oven?", "Dearie, I think the recipe got lost in translation."],
					0: ["Good heavens, what IS this? An attempt on my life?", "This belongs in a museum exhibit about kitchen crimes.", "Darling, if I swallow this, ring the doctor immediately.", "My stars, this is a war crime against baking!", "Sweetie, I think you've invented a new form of punishment."]
				}
			},
			"story": {
				"type": "comment", "comment_type": "PERSONAL_STORY",
				"score_tiers": {
					70: ["This reminds me of my mother's kitchen on Sunday mornings. The whole house would smell like heaven!", "Oh darling, this takes me back to my wedding day. The baker made the most perfect biscuits I've ever tasted.", "My stars, this is just like what my Aunt Bessie used to make. She had the magic touch, just like you!"],
					0: ["This reminds me of my first attempt at baking. I was so proud until I tasted it. We all start somewhere, dearie!", "Oh honey, this brings back memories of the time I forgot to add flour. The results were... educational.", "Sweetie, this reminds me of my neighbor's cooking. God rest her soul, but that woman couldn't boil water!"]
				}
			},
			"technical": {
				"type": "comment", "comment_type": "OBSERVATION",
				"conditionals": [
					{"condition": "ingredients_lt", "value": 3, "lines": ["Lazy baking, dear. Where's the love?", "I counted the ingredients and got bored.", "This recipe looks shorter than my grocery list."]},
					{"condition": "ingredients_gt", "value": 8, "lines": ["My word, you've got everything but the kitchen sink in here!", "Sweetie, sometimes less is more in baking.", "Dearie, you're trying too hard."]},
					{"condition": "attribute", "value": "Radioactive", "lines": ["It's glowing! I suppose that makes it festive?", "My grandson's nightlight is dimmer than this biscuit.", "Mercy, I can feel my bones vibrating already."]}
				]
			},
			"emotional": {
				"type": "reaction",
				"score_tiers": {
					80: ["*wipes away a tear* Oh, this is just beautiful!", "*clutches heart* My stars, this is pure joy!", "*beams with pride* Darling, you've made an old woman very happy!"],
					0: ["*winces slightly* Oh dear...", "*forces a smile* Bless your heart...", "*looks concerned* Sweetie, are you feeling alright?"]
				}
			}
		}
	},
	"rordan_gamsey": {
		"name": "Rordan Gamsey",
		"praise_threshold": 60,
		"initial_moods": {"rage": 1.0, "standards": 1.0},
		"comment_pool": ["primary", "technical", "comparison"],
		"comment_sequence": [
			{"type": "primary", "chance": 1.0},
			{"type": "technical", "chance": 0.8},
			{"type": "comparison", "chance": 0.6},
			{"type": "outburst", "chance": 0.7, "condition": "rage_gt", "value": 1.2}
		],
		"comments": {
			"primary": {
				"type": "comment",
				"score_tiers": {
					90: ["THIS IS WHAT I'M TALKING ABOUT! Perfect texture, perfect flavor! BEAUTIFUL!", "FINALLY! Something that doesn't make me want to scream.", "YES! You actually remembered how to bake!"],
					60: ["Not bad, but it's MISSING SOMETHING! Where's the passion?!", "It's edible, but it's not blowing my socks off!", "This is fine. And I hate fine."],
					30: ["DRY AS A DESERT! This biscuit is an insult to bakers everywhere!", "I've eaten cardboard with more moisture!", "Are you sure this isn't a building material?"],
					0: ["WHAT IS THIS?! Did you even TRY?! Absolutely DREADFUL!", "This isn't food, it's a war crime!", "I wouldn't feed this to my worst enemy!"]
				}
			},
			"technical": {
				"type": "comment", "comment_type": "TECHNICAL_ANALYSIS",
				"conditionals": [
					{"condition": "ingredients_lt", "value": 3, "lines": ["WHERE ARE THE INGREDIENTS?! This is baking, not a minimalist art project!", "I've seen more complexity in a saltine cracker!"]},
					{"condition": "attribute", "value": "Rotten", "lines": ["GET THIS GARBAGE OUT OF MY SIGHT!", "I'm not touching that. Health inspectors would faint!", "This should be buried in a hazmat site!"]},
					{"condition": "score_lt", "value": 25, "lines": ["The texture is WRONG! The flavor is WRONG! Everything is WRONG!", "This violates every principle of baking!"]}
				]
			},
			"comparison": {
				"type": "comment", "comment_type": "COMPARISON",
				"score_tiers": {
					80: ["This could stand up to the finest Parisian patisseries!", "I've had worse at three-Michelin-starred restaurants!"],
					0: ["I've had better food in school cafeterias!", "This makes airline food look gourmet!", "I've seen better baking in prison!"]
				}
			},
			"outburst": {
				"type": "reaction",
				"lines": ["*throws hands in air* I CAN'T TAKE THIS ANYMORE!", "*slams fist on table* THIS IS MADNESS!", "*pulls hair* WHY DO I DO THIS TO MYSELF?!"]
			}
		}
	},
	"professor_biscotti": {
		"name": "Professor Biscotti",
		"praise_threshold": 75,
		"initial_moods": {"curiosity": 1.0, "precision": 1.0},
		"comment_pool": ["scientific", "complexity", "theoretical"],
		"comment_sequence": [
			{"type": "scientific", "chance": 1.0},
			{"type": "complexity", "chance": 0.7},
			{"type": "theoretical", "chance": 0.5},
			{"type": "research", "chance": 0.4, "condition": "curiosity_gt", "value": 1.1}
		],
		"comments": {
			"scientific": {
				"type": "comment", "comment_type": "TECHNICAL_ANALYSIS",
				"score_tiers": {
					# Using complexity score (ingredients + attributes)
					8: ["Fascinating! The interplay here demonstrates sophisticated flavor chemistry.", "A triumph of technique! Bold, daring, and scientifically intriguing.", "This could be published in the Journal of Experimental Gastronomy!"],
					5: ["An adequate attempt at complexity, though somewhat inconsistent.", "There is evidence of innovation, if not complete execution.", "Ambitious, though a bit rough around the edges."],
					3: ["Rather simplistic. Where is the creative spark?", "This feels like an undergraduate's first attempt at baking.", "Competent, but hardly memorable."],
					0: ["This exhibits a fundamental misunderstanding of baking principles.", "From a methodological standpoint, a complete disaster.", "Hardly worthy of analysis. A culinary failure."]
				}
			},
			"complexity": {
				"type": "comment", "comment_type": "OBSERVATION",
				"conditionals": [
					{"condition": "ingredients_gt", "value": 6, "lines": ["The ingredient complexity suggests advanced understanding of flavor interactions.", "Multiple components indicate sophisticated approach to recipe development."]},
					{"condition": "ingredients_lt", "value": 3, "lines": ["Minimalism in baking can be elegant, but this is just lazy.", "One ingredient? This is culinary nihilism."]},
					{"condition": "attribute", "value": "Radioactive", "lines": ["Intriguing use of radioactive elements! Unconventional indeed.", "A glowing biscuit? The molecular implications are concerning."]}
				]
			},
			"theoretical": {
				"type": "comment", "comment_type": "TECHNICAL_ANALYSIS",
				"score_tiers": {
					75: ["Clearly demonstrates technical proficiency.", "A sound execution of theoretical principles.", "This shows advanced understanding of baking mechanics."],
					0: ["A failure of basic technique.", "Poor execution undermines any theoretical promise.", "This belongs in a case study of what not to do."]
				}
			},
			"research": {
				"type": "comment", "comment_type": "SUGGESTION",
				"lines": ["This warrants further investigation in controlled laboratory conditions.", "I would recommend additional research into the underlying mechanisms.", "This presents an interesting case for academic study." ]
			}
		}
	}
}

var current_players: Array[GameState.PlayerData] = []
var judging_in_progress: bool = false
var judge_mood_modifiers: Dictionary = {}
var skip_requested: bool = false
var typewriter_effect: TypewriterEffect
var judge_presentation: JudgePresentation

func start_judging(players: Array[GameState.PlayerData]):
	current_players = players
	judging_in_progress = true
	skip_requested = false
	_initialize_judge_moods()
	_setup_typewriter_effect()
	_setup_judge_presentation()
	judging_started.emit()
	_begin_judging_sequence()

func skip_judging():
	skip_requested = true
	if typewriter_effect and typewriter_effect.is_currently_typing():
		typewriter_effect.skip_to_end()

func _initialize_judge_moods():
	judge_mood_modifiers.clear()
	for judge_key in judge_data:
		judge_mood_modifiers[judge_key] = judge_data[judge_key]["initial_moods"].duplicate()

func _setup_typewriter_effect():
	var game_ui = get_tree().get_first_node_in_group("game_ui")
	if game_ui:
		typewriter_effect = game_ui.get_typewriter_effect()
		if typewriter_effect:
			typewriter_effect.set_typing_speed(typing_speed)
			if not typewriter_effect.typing_finished.is_connected(_on_typewriter_finished):
				typewriter_effect.typing_finished.connect(_on_typewriter_finished)

func _setup_judge_presentation():
	judge_presentation = get_tree().get_first_node_in_group("judge_presentation")
	if judge_presentation:
		judge_presentation.start_judge_presentation()

func _begin_judging_sequence():
	var sorted_players = current_players.duplicate()
	sorted_players.sort_custom(func(a, b): return a.round_score < b.round_score)

	for player in sorted_players:
		if skip_requested: break
		await _judge_player_biscuit(player)
		if not skip_requested:
			await get_tree().create_timer(1.0).timeout
		_update_judge_moods(player)

	if judge_presentation:
		judge_presentation.end_judge_presentation()

	judging_complete.emit()
	judging_in_progress = false

func _judge_player_biscuit(player: GameState.PlayerData):
	if not player.current_biscuit or skip_requested: return
	update_victim.emit(player.name)

	for judge_key in judge_data:
		if skip_requested: return
		var judge = judge_data[judge_key]
		var biscuit = player.current_biscuit

		if single_comment_per_judge:
			var comment_pool = _get_available_comment_types(judge_key)
			var chosen_type = comment_pool.pick_random()
			if chosen_type:
				await _deliver_comment(judge_key, biscuit, chosen_type)
				await _wait_for_comment_completion()
		else:
			for comment_info in judge.get("comment_sequence", []):
				if skip_requested: return
				if not _check_mood_condition(judge_key, comment_info): continue

				if randf() < comment_info.get("chance", 1.0):
					await _deliver_comment(judge_key, biscuit, comment_info["type"])
					await get_tree().create_timer(0.8).timeout

			if not skip_requested: await get_tree().create_timer(1.5).timeout

func _get_available_comment_types(judge_key: String) -> Array[String]:
	var judge = judge_data[judge_key]

	# Cast to Array and then rebuild into Array[String]
	var raw_pool: Array = judge.get("comment_pool", [])
	var pool: Array[String] = []
	for item in raw_pool:
		pool.append(str(item))  # force as string in case the array has mixed types

	if _check_mood_condition(judge_key, {"condition": "rage_gt", "value": 1.2}):
		pool.append("outburst")
	if _check_mood_condition(judge_key, {"condition": "curiosity_gt", "value": 1.1}):
		pool.append("research")

	return pool

func _deliver_comment(judge_key: String, biscuit: GameState.BiscuitData, category: String):
	var judge = judge_data[judge_key]
	var category_data = judge["comments"].get(category)
	if not category_data: return

	var comment_lines: Array[String] = []
	if "lines" in category_data:
		var raw_lines: Array = category_data["lines"]
		for l in raw_lines:
			comment_lines.append(str(l))
	elif "conditionals" in category_data:
		for conditional in category_data["conditionals"]:
			if _check_biscuit_condition(biscuit, conditional):
				for l in conditional["lines"]:
					comment_lines.append(str(l))
	elif "score_tiers" in category_data:
		var score = biscuit.total_points
		if category == "scientific":
			score = biscuit.ingredients.size() + biscuit.special_attributes.size()

		var tiers = category_data["score_tiers"].keys()
		tiers.sort()
		tiers.reverse()
		for tier_score in tiers:
			if score >= tier_score:
				var raw_lines: Array = category_data["score_tiers"][tier_score]
				for l in raw_lines:
					comment_lines.append(str(l))
				break

	if comment_lines.is_empty(): return

	# Focus camera on current judge
	judge_focus_requested.emit(judge_key)
	if judge_presentation:
		await judge_presentation.focus_on_judge(judge_key)

	var text = comment_lines.pick_random()
	var name = judge["name"]
	var type = category_data.get("type", "comment")

	# Determine mood and play voice
	var mood = _determine_mood_for_comment(judge_key, biscuit, category, text)
	judge_voice_requested.emit(judge_key, mood)
	if judge_presentation:
		judge_presentation.play_voice_line(judge_key, mood)

	if type == "reaction":
		judge_reaction.emit(name, text)
	else:
		var comment_type_str = category_data.get("comment_type", "OBSERVATION")
		if category == "primary":
			var threshold = judge.get("praise_threshold", 60)
			comment_type_str = "PRAISE" if biscuit.total_points > threshold else "CRITICISM"
		judge_comment.emit(name, text, comment_type_str)
		
	print("%s: %s" % [name, text])

func _check_biscuit_condition(biscuit: GameState.BiscuitData, conditional: Dictionary) -> bool:
	match conditional["condition"]:
		"ingredients_lt": return biscuit.ingredients.size() < conditional["value"]
		"ingredients_gt": return biscuit.ingredients.size() > conditional["value"]
		"attribute": return conditional["value"] in biscuit.special_attributes
		"score_lt": return biscuit.total_points < conditional["value"]
	return false

func _check_mood_condition(judge_key: String, comment_info: Dictionary) -> bool:
	if not "condition" in comment_info: return true
	var moods = judge_mood_modifiers[judge_key]
	match comment_info["condition"]:
		"rage_gt": return moods.get("rage", 0.0) > comment_info["value"]
		"curiosity_gt": return moods.get("curiosity", 0.0) > comment_info["value"]
	return true

func _update_judge_moods(player: GameState.PlayerData):
	var biscuit = player.current_biscuit
	if not biscuit: return

	if biscuit.total_points > 70: judge_mood_modifiers["granny_butterworth"]["patience"] += 0.1
	else: judge_mood_modifiers["granny_butterworth"]["patience"] -= 0.1

	if biscuit.total_points < 30: judge_mood_modifiers["rordan_gamsey"]["rage"] += 0.2
	elif biscuit.total_points > 90: judge_mood_modifiers["rordan_gamsey"]["rage"] -= 0.1

	if biscuit.ingredients.size() > 5: judge_mood_modifiers["professor_biscotti"]["curiosity"] += 0.1

func _wait_for_comment_completion():
	if typewriter_effect and typewriter_effect.is_currently_typing():
		await typewriter_effect.typing_finished
	else:
		await get_tree().create_timer(comment_display_time).timeout

func _on_typewriter_finished():
	pass

func _determine_mood_for_comment(judge_key: String, biscuit: GameState.BiscuitData, category: String, comment_text: String) -> String:
	var score = biscuit.total_points

	# Check for specific mood indicators in text
	var lower_comment = comment_text.to_lower()
	if "beautiful" in lower_comment or "perfect" in lower_comment or "scrumptious" in lower_comment:
		return "Happy"
	elif "terrible" in lower_comment or "disaster" in lower_comment or "dreadful" in lower_comment:
		return "Angry"
	elif "not terrible" in lower_comment or "edible" in lower_comment or "adequate" in lower_comment:
		return "Disappointed"
	elif "reminds me" in lower_comment and score < 30:
		return "Sad"

	# Use judge presentation system if available
	if judge_presentation:
		return judge_presentation.determine_mood_from_comment(judge_key, comment_text, category, score)

	# Fallback mood determination
	match judge_key:
		"granny_butterworth":
			if score >= 70: return "Happy"
			elif score >= 40: return "Disappointed"
			elif score >= 20: return "Sad"
			else: return "Angry"
		"rordan_gamsey":
			if score >= 80: return "Happy"
			elif score >= 50: return "Disappointed"
			else: return "Angry"
		"professor_biscotti":
			if score >= 75: return "Happy"
			elif score >= 50: return "Disappointed"
			elif score >= 25: return "Sad"
			else: return "Disappointed"

	return "Disappointed"

func is_judging() -> bool:
	return judging_in_progress
