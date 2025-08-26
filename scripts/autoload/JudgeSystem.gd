extends Node

signal judging_started()
signal judge_comment(judge_name: String, comment: String, comment_type: String)
signal judge_reaction(judge_name: String, reaction: String)
signal judging_complete()

enum Judge {
	GRANNY_BUTTERWORTH,
	RORDAN_GAMSEY,
	PROFESSOR_BISCOTTI
}

enum CommentType {
	PRAISE,
	CRITICISM,
	OBSERVATION,
	REACTION,
	PERSONAL_STORY,
	TECHNICAL_ANALYSIS,
	EMOTIONAL_RESPONSE,
	COMPARISON,
	SUGGESTION,
	WARNING
}

var judge_data = {
	Judge.GRANNY_BUTTERWORTH: {
		"name": "Granny Butterworth",
		"personality": "sweet_but_brutal",
		"speech_pattern": "southern_gentle",
		"expertise": "traditional_baking",
		"quirks": ["nostalgic", "compassionate", "brutally_honest"]
	},
	Judge.RORDAN_GAMSEY: {
		"name": "Rordan Gamsey",
		"personality": "angry_perfectionist",
		"speech_pattern": "explosive_chef",
		"expertise": "fine_dining",
		"quirks": ["volatile", "passionate", "unforgiving"]
	},
	Judge.PROFESSOR_BISCOTTI: {
		"name": "Professor Biscotti",
		"personality": "academic_analyzer",
		"speech_pattern": "scientific_formal",
		"expertise": "food_science",
		"quirks": ["analytical", "curious", "detached"]
	}
}

var current_players: Array[GameState.PlayerData] = []
var judging_in_progress: bool = false
var judge_mood_modifiers: Dictionary = {}

func start_judging(players: Array[GameState.PlayerData]):
	current_players = players
	judging_in_progress = true
	_initialize_judge_moods()
	judging_started.emit()
	_begin_judging_sequence()

func _initialize_judge_moods():
	judge_mood_modifiers = {
		Judge.GRANNY_BUTTERWORTH: {"patience": 1.0, "nostalgia": 1.0},
		Judge.RORDAN_GAMSEY: {"rage": 1.0, "standards": 1.0},
		Judge.PROFESSOR_BISCOTTI: {"curiosity": 1.0, "precision": 1.0}
	}

func _begin_judging_sequence():
	print("=== JUDGING BEGINS ===")
	var sorted_players = current_players.duplicate()
	sorted_players.sort_custom(func(a, b): return a.round_score < b.round_score)
	
	for player in sorted_players:
		await _judge_player_biscuit(player)
		# await get_tree().create_timer(2.0).timeout
		_update_judge_moods(player)
	
	judging_complete.emit()
	judging_in_progress = false

func _judge_player_biscuit(player: GameState.PlayerData):
	if not player.current_biscuit:
		return
	print("\n--- Judging ", player.name, "'s biscuit ---")
	
	await _granny_butterworth_judges(player)
	# await get_tree().create_timer(1.5).timeout
	await _rordan_gamsey_judges(player)
	# await get_tree().create_timer(1.5).timeout
	await _professor_biscotti_judges(player)
	# await get_tree().create_timer(1.0).timeout

func _update_judge_moods(player: GameState.PlayerData):
	var biscuit = player.current_biscuit
	if not biscuit:
		return
	
	# Granny gets more patient with good biscuits, less with bad ones
	if biscuit.total_points > 70:
		judge_mood_modifiers[Judge.GRANNY_BUTTERWORTH]["patience"] += 0.1
	else:
		judge_mood_modifiers[Judge.GRANNY_BUTTERWORTH]["patience"] -= 0.1
	
	# Rordan gets angrier with bad biscuits, calmer with excellent ones
	if biscuit.total_points < 30:
		judge_mood_modifiers[Judge.RORDAN_GAMSEY]["rage"] += 0.2
	elif biscuit.total_points > 90:
		judge_mood_modifiers[Judge.RORDAN_GAMSEY]["rage"] -= 0.1
	
	# Professor gets more curious with complex biscuits
	if biscuit.ingredients.size() > 5:
		judge_mood_modifiers[Judge.PROFESSOR_BISCOTTI]["curiosity"] += 0.1

# ---------------- Granny Butterworth ----------------
func _granny_butterworth_judges(player: GameState.PlayerData):
	var biscuit = player.current_biscuit
	var patience = judge_mood_modifiers[Judge.GRANNY_BUTTERWORTH]["patience"]
	var nostalgia = judge_mood_modifiers[Judge.GRANNY_BUTTERWORTH]["nostalgia"]
	
	# Primary assessment
	await _granny_primary_assessment(biscuit, patience)
	await get_tree().create_timer(0.8).timeout
	
	# Personal story or memory
	if randf() < 0.6:
		await _granny_personal_story(biscuit, nostalgia)
		await get_tree().create_timer(0.6).timeout
	
	# Technical observation
	if randf() < 0.7:
		await _granny_technical_observation(biscuit)
		await get_tree().create_timer(0.5).timeout
	
	# Emotional response
	if randf() < 0.5:
		await _granny_emotional_response(biscuit, patience)
		await get_tree().create_timer(0.4).timeout

func _granny_primary_assessment(biscuit: GameState.BiscuitData, _patience: float):
	var comments = []
	
	if biscuit.total_points > 80:
		comments = [
			"Oh darling, this could win the county fair three years running!",
			"Well dearie, this is simply scrumptious. Brings a tear to my eye.",
			"My stars, I haven't tasted something this good since 1947!",
			"Bless your heart, this is exactly how my mother used to make them!",
			"Sweetie, you've got the touch! This is pure magic!",
			"Oh my, this reminds me of the bakery on Main Street back in '52!",
			"Darling, this is fit for the governor's table!",
			"My goodness, you've captured the essence of home baking!"
		]
	elif biscuit.total_points > 50:
		comments = [
			"Not terrible, love, but I've had better at Tuesday bingo night.",
			"It's edible, dear, which is more than I expected.",
			"Sweetie, I'd serve this to guests I don't like very much.",
			"Well, it's not the worst thing I've ever tasted, bless your heart.",
			"Dearie, this needs a bit more love in the mixing bowl.",
			"It's got potential, sweetie, but it's not quite there yet.",
			"Oh honey, this is... well, it's certainly a biscuit.",
			"Bless you for trying, dear, but practice makes perfect."
		]
	elif biscuit.total_points > 25:
		comments = [
			"Oh sweetie, were you trying to bake or to start a fire?",
			"This wouldn't fool a raccoon on garbage day.",
			"Bless your heart, dear, but this belongs in the compost.",
			"My stars, what happened in that oven?",
			"Dearie, I think the recipe got lost in translation.",
			"Oh honey, this is a culinary tragedy.",
			"Sweetie, I'm not sure what this is, but it's not a biscuit.",
			"Bless your heart, but this needs divine intervention."
		]
	else:
		comments = [
			"Good heavens, what IS this? An attempt on my life?",
			"This belongs in a museum exhibit about kitchen crimes.",
			"Darling, if I swallow this, ring the doctor immediately.",
			"My stars, this is a war crime against baking!",
			"Sweetie, I think you've invented a new form of punishment.",
			"Oh dear, this is what nightmares are made of.",
			"Bless your heart, but this is pure evil in biscuit form.",
			"My goodness, this should be studied by scientists... for what NOT to do."
		]
	
	var comment = comments.pick_random()
	judge_comment.emit("Granny Butterworth", comment, CommentType.PRAISE if biscuit.total_points > 50 else CommentType.CRITICISM)
	print("Granny Butterworth: ", comment)

func _granny_personal_story(biscuit: GameState.BiscuitData, _nostalgia: float):
	var stories = []
	
	if "Sweet" in biscuit.special_attributes:
		stories = [
			"Reminds me of the time little Tommy tried to make cookies and used a whole bag of sugar. Oh, that boy was bouncing off the walls for days!",
			"The sweetness brings back memories of my grandmother's honey biscuits. She'd always say, 'A little extra sugar never hurt nobody.'",
			"This takes me back to the church bake sale of '63. Sister Margaret's sweet rolls were the talk of the town!"
		]
	elif "Spicy" in biscuit.special_attributes:
		stories = [
			"My word, this reminds me of when cousin Edna tried to make 'exotic' food. We all learned that day that not everything needs hot sauce!",
			"Oh my, this brings back memories of the chili cook-off disaster of '78. Poor Reverend Johnson never lived that down!",
			"Sweetie, this reminds me of the time I accidentally used cayenne instead of cinnamon. The family still talks about it!"
		]
	elif biscuit.total_points > 70:
		stories = [
			"This reminds me of my mother's kitchen on Sunday mornings. The whole house would smell like heaven!",
			"Oh darling, this takes me back to my wedding day. The baker made the most perfect biscuits I've ever tasted.",
			"My stars, this is just like what my Aunt Bessie used to make. She had the magic touch, just like you!"
		]
	else:
		stories = [
			"This reminds me of my first attempt at baking. I was so proud until I tasted it. We all start somewhere, dearie!",
			"Oh honey, this brings back memories of the time I forgot to add flour. The results were... educational.",
			"Sweetie, this reminds me of my neighbor's cooking. God rest her soul, but that woman couldn't boil water!"
		]
	
	if stories.size() > 0:
		var story = stories.pick_random()
		judge_comment.emit("Granny Butterworth", story, CommentType.PERSONAL_STORY)
		print("Granny Butterworth: ", story)

func _granny_technical_observation(biscuit: GameState.BiscuitData):
	var observations = []
	
	if biscuit.ingredients.size() < 3:
		observations = [
			"Lazy baking, dear. Where's the love?",
			"I counted the ingredients and got bored.",
			"This recipe looks shorter than my grocery list.",
			"Sweetie, a biscuit needs more than just flour and water.",
			"Dearie, you're missing the heart of baking - variety!"
		]
	elif biscuit.ingredients.size() > 8:
		observations = [
			"My word, you've got everything but the kitchen sink in here!",
			"Sweetie, sometimes less is more in baking.",
			"Dearie, you're trying too hard. Simple is often better.",
			"Oh my, this is like a culinary treasure hunt!",
			"Bless your heart, but you might be overcomplicating things."
		]
	
	if "Radioactive" in biscuit.special_attributes:
		observations.append_array([
			"It's glowing! I suppose that makes it festive?",
			"My grandson's nightlight is dimmer than this biscuit.",
			"Mercy, I can feel my bones vibrating already.",
			"Sweetie, I think you've invented a new form of lighting!",
			"Oh my, this could power a small village!"
		])
	
	if observations.size() > 0:
		var observation = observations.pick_random()
		judge_comment.emit("Granny Butterworth", observation, CommentType.OBSERVATION)
		print("Granny Butterworth: ", observation)

func _granny_emotional_response(biscuit: GameState.BiscuitData, _patience: float):
	var responses = []
	
	if biscuit.total_points > 80:
		responses = [
			"*wipes away a tear* Oh, this is just beautiful!",
			"*clutches heart* My stars, this is pure joy!",
			"*beams with pride* Darling, you've made an old woman very happy!",
			"*sighs contentedly* This is what heaven tastes like!"
		]
	elif biscuit.total_points < 30:
		responses = [
			"*winces slightly* Oh dear...",
			"*forces a smile* Bless your heart...",
			"*looks concerned* Sweetie, are you feeling alright?",
			"*takes a deep breath* Well, at least you tried..."
		]
	
	if responses.size() > 0:
		var response = responses.pick_random()
		judge_reaction.emit("Granny Butterworth", response)
		print("Granny Butterworth: ", response)

# ---------------- Rordan Gamsey ----------------
func _rordan_gamsey_judges(player: GameState.PlayerData):
	var biscuit = player.current_biscuit
	var rage = judge_mood_modifiers[Judge.RORDAN_GAMSEY]["rage"]
	
	# Primary assessment
	await _rordan_primary_assessment(biscuit, rage)
	await get_tree().create_timer(0.8).timeout
	
	# Technical criticism
	if randf() < 0.8:
		await _rordan_technical_criticism(biscuit)
		await get_tree().create_timer(0.6).timeout
	
	# Comparison to standards
	if randf() < 0.6:
		await _rordan_comparison(biscuit)
		await get_tree().create_timer(0.5).timeout
	
	# Emotional outburst
	if rage > 1.2 and randf() < 0.7:
		await _rordan_emotional_outburst(biscuit)
		await get_tree().create_timer(0.4).timeout

func _rordan_primary_assessment(biscuit: GameState.BiscuitData, _rage: float):
	var comments = []
	
	if biscuit.total_points > 90:
		comments = [
			"THIS IS WHAT I'M TALKING ABOUT! Perfect texture, perfect flavor! BEAUTIFUL!",
			"FINALLY! Something that doesn't make me want to scream.",
			"YES! You actually remembered how to bake!",
			"MAGNIFICENT! This is what baking is supposed to be!",
			"OUTSTANDING! You've restored my faith in humanity!",
			"BRILLIANT! This is pure culinary genius!",
			"EXCEPTIONAL! This could grace the finest restaurants!",
			"PERFECTION! This is what dreams are made of!"
		]
	elif biscuit.total_points > 60:
		comments = [
			"Not bad, but it's MISSING SOMETHING! Where's the passion?!",
			"It's edible, but it's not blowing my socks off!",
			"This is fine. And I hate fine.",
			"ACCEPTABLE! But acceptable is not EXCELLENT!",
			"You're on the right track, but you're not THERE yet!",
			"This shows promise, but promise isn't perfection!",
			"It's not terrible, but it's not great either!",
			"You've got the basics, now show me some MAGIC!"
		]
	elif biscuit.total_points > 30:
		comments = [
			"DRY AS A DESERT! This biscuit is an insult to bakers everywhere!",
			"I've eaten cardboard with more moisture!",
			"Are you sure this isn't a building material?",
			"This is what happens when you don't care about your craft!",
			"UNACCEPTABLE! This is amateur hour!",
			"You call this baking? I call this a tragedy!",
			"This is why I have trust issues with home cooks!",
			"Did you even TRY to make this edible?!"
		]
	else:
		comments = [
			"WHAT IS THIS?! Did you even TRY?! Absolutely DREADFUL!",
			"This isn't food, it's a war crime!",
			"I wouldn't feed this to my worst enemy!",
			"This is an affront to everything I stand for!",
			"I'm calling the health inspector! This is dangerous!",
			"This belongs in a museum of culinary disasters!",
			"I've seen better food in prison cafeterias!",
			"This is proof that some people shouldn't be allowed in kitchens!"
		]
	
	var comment = comments.pick_random()
	judge_comment.emit("Rordan Gamsey", comment, CommentType.CRITICISM if biscuit.total_points < 60 else CommentType.PRAISE)
	print("Rordan Gamsey: ", comment)

func _rordan_technical_criticism(biscuit: GameState.BiscuitData):
	var criticisms = []
	
	if biscuit.ingredients.size() < 3:
		criticisms = [
			"WHERE ARE THE INGREDIENTS?! This is baking, not a minimalist art project!",
			"You've got three ingredients and none of them are interesting!",
			"This is the culinary equivalent of a blank canvas!",
			"I've seen more complexity in a saltine cracker!",
			"You call this a recipe? I call this laziness!"
		]
	
	if "Spicy" in biscuit.special_attributes:
		criticisms.append_array([
			"TOO MUCH SPICE! Are you trying to kill me?!",
			"This isn't a biscuit, it's a weapon!",
			"My tongue is on fire! Who let this happen?!",
			"This is assault with a deadly biscuit!",
			"I need a fire extinguisher for my mouth!"
		])
	
	if "Rotten" in biscuit.special_attributes:
		criticisms.append_array([
			"GET THIS GARBAGE OUT OF MY SIGHT!",
			"I'm not touching that. Health inspectors would faint!",
			"This should be buried in a hazmat site!",
			"This is what nightmares are made of!",
			"I'm calling the CDC! This is a biohazard!"
		])
	
	if biscuit.total_points < 25:
		criticisms.append_array([
			"The texture is WRONG! The flavor is WRONG! Everything is WRONG!",
			"This violates every principle of baking!",
			"You've committed crimes against gastronomy!",
			"This is what happens when you ignore basic technique!",
			"I'm questioning your right to own an oven!"
		])
	
	if criticisms.size() > 0:
		var criticism = criticisms.pick_random()
		judge_comment.emit("Rordan Gamsey", criticism, CommentType.TECHNICAL_ANALYSIS)
		print("Rordan Gamsey: ", criticism)

func _rordan_comparison(biscuit: GameState.BiscuitData):
	var comparisons = []
	
	if biscuit.total_points > 80:
		comparisons = [
			"This could stand up to the finest Parisian patisseries!",
			"I've had worse at three-Michelin-starred restaurants!",
			"This puts some of my own creations to shame!",
			"This is what I expect from a master baker!",
			"This could win international competitions!"
		]
	elif biscuit.total_points < 40:
		comparisons = [
			"I've had better food in school cafeterias!",
			"This makes airline food look gourmet!",
			"I've seen better baking in prison!",
			"This is worse than hospital food!",
			"I've had better biscuits from a vending machine!"
		]
	
	if comparisons.size() > 0:
		var comparison = comparisons.pick_random()
		judge_comment.emit("Rordan Gamsey", comparison, CommentType.COMPARISON)
		print("Rordan Gamsey: ", comparison)

func _rordan_emotional_outburst(_biscuit: GameState.BiscuitData):
	var outbursts = [
		"*throws hands in air* I CAN'T TAKE THIS ANYMORE!",
		"*slams fist on table* THIS IS MADNESS!",
		"*pulls hair* WHY DO I DO THIS TO MYSELF?!",
		"*stares at ceiling* SOMEONE SAVE ME FROM THIS HELL!",
		"*clutches head* MY BRAIN IS MELTING FROM THIS INCOMPETENCE!"
	]
	
	var outburst = outbursts.pick_random()
	judge_reaction.emit("Rordan Gamsey", outburst)
	print("Rordan Gamsey: ", outburst)

# ---------------- Professor Biscotti ----------------
func _professor_biscotti_judges(player: GameState.PlayerData):
	var biscuit = player.current_biscuit
	var curiosity = judge_mood_modifiers[Judge.PROFESSOR_BISCOTTI]["curiosity"]
	
	# Scientific analysis
	await _professor_scientific_analysis(biscuit)
	await get_tree().create_timer(0.8).timeout
	
	# Complexity assessment
	if randf() < 0.7:
		await _professor_complexity_assessment(biscuit)
		await get_tree().create_timer(0.6).timeout
	
	# Theoretical implications
	if randf() < 0.5:
		await _professor_theoretical_implications(biscuit)
		await get_tree().create_timer(0.5).timeout
	
	# Research suggestions
	if curiosity > 1.1 and randf() < 0.4:
		await _professor_research_suggestions(biscuit)
		await get_tree().create_timer(0.4).timeout

func _professor_scientific_analysis(biscuit: GameState.BiscuitData):
	var complexity_score = biscuit.ingredients.size() + biscuit.special_attributes.size()
	var comments = []
	
	if complexity_score > 8:
		comments = [
			"Fascinating! The interplay here demonstrates sophisticated flavor chemistry.",
			"A triumph of technique! Bold, daring, and scientifically intriguing.",
			"This could be published in the Journal of Experimental Gastronomy!",
			"Remarkable complexity! The molecular interactions are quite sophisticated.",
			"An excellent example of advanced culinary science in practice.",
			"The theoretical framework here is quite sound and innovative.",
			"This demonstrates a deep understanding of gastronomic principles.",
			"A masterful application of complex flavor theory."
		]
	elif complexity_score > 5:
		comments = [
			"An adequate attempt at complexity, though somewhat inconsistent.",
			"There is evidence of innovation, if not complete execution.",
			"Ambitious, though a bit rough around the edges.",
			"The approach shows promise, but lacks refinement.",
			"Interesting methodology, though the results are mixed.",
			"A solid foundation with room for improvement.",
			"The concept is sound, but execution needs work.",
			"Promising, though not entirely successful."
		]
	elif complexity_score > 3:
		comments = [
			"Rather simplistic. Where is the creative spark?",
			"This feels like an undergraduate's first attempt at baking.",
			"Competent, but hardly memorable.",
			"Basic technique, lacking in innovation.",
			"A straightforward approach with limited complexity.",
			"Functional, but not particularly interesting.",
			"Standard methodology, nothing remarkable.",
			"Adequate, but uninspired."
		]
	else:
		comments = [
			"This exhibits a fundamental misunderstanding of baking principles.",
			"From a methodological standpoint, a complete disaster.",
			"Hardly worthy of analysis. A culinary failure.",
			"This violates basic principles of food science.",
			"A textbook example of what not to do in baking.",
			"This demonstrates a lack of understanding of fundamentals.",
			"Poor execution undermines any theoretical promise.",
			"This belongs in a case study of culinary failure."
		]
	
	var comment = comments.pick_random()
	judge_comment.emit("Professor Biscotti", comment, CommentType.TECHNICAL_ANALYSIS)
	print("Professor Biscotti: ", comment)

func _professor_complexity_assessment(biscuit: GameState.BiscuitData):
	var assessments = []
	
	if biscuit.ingredients.size() > 6:
		assessments = [
			"The ingredient complexity suggests advanced understanding of flavor interactions.",
			"Multiple components indicate sophisticated approach to recipe development.",
			"The variety of elements shows commendable experimentation.",
			"Complex ingredient matrix demonstrates culinary ambition.",
			"Multiple variables suggest systematic approach to flavor development."
		]
	elif biscuit.ingredients.size() < 3:
		assessments = [
			"Minimalism in baking can be elegant, but this is just lazy.",
			"One ingredient? This is culinary nihilism.",
			"Reducing a biscuit to its atomic parts is not innovation.",
			"The lack of complexity suggests limited understanding of baking science.",
			"This represents an oversimplified approach to culinary arts."
		]
	
	if "Radioactive" in biscuit.special_attributes:
		assessments.append_array([
			"Intriguing use of radioactive elements! Unconventional indeed.",
			"A glowing biscuit? The molecular implications are concerning.",
			"This may violate several international treaties.",
			"The radioactive properties present interesting research opportunities.",
			"This could revolutionize the field of luminescent gastronomy."
		])
	
	if assessments.size() > 0:
		var assessment = assessments.pick_random()
		judge_comment.emit("Professor Biscotti", assessment, CommentType.OBSERVATION)
		print("Professor Biscotti: ", assessment)

func _professor_theoretical_implications(biscuit: GameState.BiscuitData):
	var implications = []
	
	if biscuit.total_points > 75:
		implications = [
			"Clearly demonstrates technical proficiency.",
			"A sound execution of theoretical principles.",
			"This shows advanced understanding of baking mechanics.",
			"The results validate established culinary theories.",
			"This could serve as a case study in successful technique application."
		]
	elif biscuit.total_points < 25:
		implications = [
			"A failure of basic technique.",
			"Poor execution undermines any theoretical promise.",
			"This belongs in a case study of what not to do.",
			"The results contradict fundamental baking principles.",
			"This demonstrates the importance of proper methodology."
		]
	
	if implications.size() > 0:
		var implication = implications.pick_random()
		judge_comment.emit("Professor Biscotti", implication, CommentType.TECHNICAL_ANALYSIS)
		print("Professor Biscotti: ", implication)

func _professor_research_suggestions(_biscuit: GameState.BiscuitData):
	var suggestions = [
		"This warrants further investigation in controlled laboratory conditions.",
		"I would recommend additional research into the underlying mechanisms.",
		"This presents an interesting case for academic study.",
		"Further experimentation could yield valuable insights.",
		"This could form the basis of a comprehensive research paper."
	]
	
	var suggestion = suggestions.pick_random()
	judge_comment.emit("Professor Biscotti", suggestion, CommentType.SUGGESTION)
	print("Professor Biscotti: ", suggestion)

# ---------------- Utility Functions ----------------
func get_judge_name(judge: Judge) -> String:
	return judge_data[judge].name

func get_judge_personality(judge: Judge) -> String:
	return judge_data[judge].personality

func get_judge_speech_pattern(judge: Judge) -> String:
	return judge_data[judge].speech_pattern

func get_judge_expertise(judge: Judge) -> String:
	return judge_data[judge].expertise

func get_judge_quirks(judge: Judge) -> Array[String]:
	return judge_data[judge].quirks

func is_judging() -> bool:
	return judging_in_progress

func get_judge_mood(judge: Judge) -> Dictionary:
	return judge_mood_modifiers.get(judge, {})

func reset_judge_moods():
	_initialize_judge_moods()

# ---------------- Advanced Dialogue System ----------------
func generate_contextual_response(judge: Judge, _biscuit: GameState.BiscuitData, context: String) -> String:
	var responses = []
	
	match judge:
		Judge.GRANNY_BUTTERWORTH:
			if context == "ingredient_quality":
				responses = [
					"The quality of ingredients speaks volumes, dearie.",
					"Good ingredients make good biscuits, that's what my mother always said.",
					"Sweetie, you can taste the love in quality ingredients."
				]
			elif context == "baking_time":
				responses = [
					"Timing is everything in baking, love.",
					"My grandmother used to say, 'Watch the clock, not the recipe.'",
					"Dearie, patience in baking is a virtue."
				]
		
		Judge.RORDAN_GAMSEY:
			if context == "ingredient_quality":
				responses = [
					"QUALITY INGREDIENTS ARE NON-NEGOTIABLE!",
					"You can't polish a turd, and you can't make good biscuits with bad ingredients!",
					"The ingredients make or break the dish! It's that simple!"
				]
			elif context == "baking_time":
				responses = [
					"TIMING IS EVERYTHING! You can't rush perfection!",
					"The difference between good and great is in the timing!",
					"Baking is a science! You can't ignore the laws of physics!"
				]
		
		Judge.PROFESSOR_BISCOTTI:
			if context == "ingredient_quality":
				responses = [
					"The quality of ingredients directly correlates with final product excellence.",
					"Ingredient selection is a critical variable in the baking equation.",
					"The molecular composition of ingredients significantly impacts outcome."
				]
			elif context == "baking_time":
				responses = [
					"Temporal precision is crucial in achieving optimal results.",
					"The relationship between time and temperature is fundamental to success.",
					"Proper timing ensures proper molecular transformation."
				]
	
	return responses.pick_random() if responses.size() > 0 else "Interesting observation."

func generate_emotional_reaction(judge: Judge, intensity: float) -> String:
	var reactions = []
	
	match judge:
		Judge.GRANNY_BUTTERWORTH:
			if intensity > 0.8:
				reactions = ["*clutches pearls*", "*fans self*", "*wipes away tears*"]
			elif intensity > 0.5:
				reactions = ["*nods approvingly*", "*smiles warmly*", "*chuckles softly*"]
			else:
				reactions = ["*sighs*", "*shakes head gently*", "*looks concerned*"]
		
		Judge.RORDAN_GAMSEY:
			if intensity > 0.8:
				reactions = ["*throws hands up*", "*slams table*", "*pulls hair*"]
			elif intensity > 0.5:
				reactions = ["*crosses arms*", "*narrows eyes*", "*taps foot*"]
			else:
				reactions = ["*rolls eyes*", "*scoffs*", "*turns away*"]
		
		Judge.PROFESSOR_BISCOTTI:
			if intensity > 0.8:
				reactions = ["*adjusts glasses excitedly*", "*leans forward*", "*scribbles notes*"]
			elif intensity > 0.5:
				reactions = ["*nods thoughtfully*", "*strokes chin*", "*raises eyebrow*"]
			else:
				reactions = ["*sighs*", "*shakes head*", "*looks disappointed*"]
	
	return reactions.pick_random() if reactions.size() > 0 else "*reacts*" 
