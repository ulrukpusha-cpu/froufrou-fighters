extends TestCase
## Phase 7 : IA à trois difficultés, sans connaissance des commandes futures du joueur.

const AI_SIDE: int = GameConstants.SIDE_P2
const SEED: int = 7

var bench: CombatBench


func before_each() -> void:
	bench = CombatBench.new()


func after_each() -> void:
	bench.free_bench()


func _build(p1_id: StringName, ai_id: StringName, distance: float, profile: AIProfile, rng_seed: int = SEED) -> AIController:
	assert_true(bench.build(tree.root, p1_id, ai_id, distance), "Le banc de combat doit se construire")
	var ai := AIController.new(profile, rng_seed)
	bench.set_controller(AI_SIDE, ai)
	return ai


## Variante purement défensive d'un profil (isole la qualité de garde).
func _defensive(level: AIProfile.Difficulty) -> AIProfile:
	var profile: AIProfile = AIProfile.load_profile(level).duplicate() as AIProfile
	profile.aggression = 0.0
	profile.throw_chance = 0.0
	profile.jump_chance = 0.0
	profile.special_chance = 0.0
	profile.counter_chance = 0.0
	profile.dodge_chance = 0.0
	profile.punish_chance = 0.0
	profile.manages_spacing = false
	return profile


func test_profiles_scale_with_difficulty() -> void:
	var easy: AIProfile = AIProfile.load_profile(AIProfile.Difficulty.EASY)
	var normal: AIProfile = AIProfile.load_profile(AIProfile.Difficulty.NORMAL)
	var hard: AIProfile = AIProfile.load_profile(AIProfile.Difficulty.HARD)
	assert_eq([easy.difficulty, normal.difficulty, hard.difficulty],
		[AIProfile.Difficulty.EASY, AIProfile.Difficulty.NORMAL, AIProfile.Difficulty.HARD], "Profils chargés")
	assert_true(easy.reaction_frames > normal.reaction_frames and normal.reaction_frames > hard.reaction_frames,
		"Réactions de plus en plus rapides")
	assert_true(easy.block_chance < normal.block_chance and normal.block_chance < hard.block_chance, "Défense croissante")
	assert_true(easy.punish_chance < normal.punish_chance and normal.punish_chance < hard.punish_chance, "Punition croissante")
	assert_false(easy.manages_spacing, "FACILE ne gère pas la distance")
	assert_true(normal.manages_spacing and hard.manages_spacing, "NORMAL et DIFFICILE gèrent la distance")


func test_ai_approaches_and_attacks() -> void:
	var ai: AIController = _build(FighterRegistry.K_BLAZE, FighterRegistry.AMAZONE, 800.0,
		AIProfile.load_profile(AIProfile.Difficulty.NORMAL))
	var hurt: bool = bench.step_until(func() -> bool: return bench.p1.health < bench.p1.data.max_health, 600)
	assert_true(hurt, "L'IA s'approche et touche un adversaire immobile")
	assert_not_null(ai, "IA créée")


func test_hard_blocks_far_more_than_easy() -> void:
	var easy_ratio: float = _block_ratio(AIProfile.Difficulty.EASY)
	bench.free_bench()
	bench = CombatBench.new()
	var hard_ratio: float = _block_ratio(AIProfile.Difficulty.HARD)
	assert_true(hard_ratio >= 0.6, "DIFFICILE pare la majorité des attaques lourdes (%.2f)" % hard_ratio)
	assert_true(easy_ratio <= 0.4, "FACILE pare rarement (%.2f)" % easy_ratio)


func _block_ratio(level: AIProfile.Difficulty) -> float:
	_build(FighterRegistry.K_BLAZE, FighterRegistry.AMAZONE, 180.0, _defensive(level))
	for i: int in 10:
		bench.p1_input.add_step(1, Vector2i.ZERO, InputFrame.KICK)
		bench.p1_input.add_step(50)
	bench.step(520)
	var contacts: int = 0
	var blocked: int = 0
	for hit: Array in bench.hits:
		if hit[0] == bench.p1:
			contacts += 1
			blocked += 1 if hit[3] else 0
	assert_true(contacts >= 5, "Assez d'attaques au contact (%d)" % contacts)
	return float(blocked) / maxi(contacts, 1)


func test_ai_never_reads_future_inputs() -> void:
	var profile: AIProfile = AIProfile.load_profile(AIProfile.Difficulty.NORMAL)
	var shared_frames: int = 60
	var log_a: Array[Vector3i] = _ai_log(profile, shared_frames, InputFrame.KICK, Vector2i.ZERO)
	bench.free_bench()
	bench = CombatBench.new()
	var log_b: Array[Vector3i] = _ai_log(profile, shared_frames, 0, Vector2i.LEFT)
	# Les deux scénarios ne diffèrent qu'à partir de la frame 61, trop loin pour un contact
	# physique : l'IA ne peut s'en apercevoir qu'à 61 + 1 + reaction_frames. Une IA qui
	# lirait les commandes à venir du joueur divergerait avant.
	var horizon: int = shared_frames + 1 + profile.reaction_frames
	assert_eq(log_a.slice(0, horizon), log_b.slice(0, horizon), "Décisions identiques tant que rien n'est visible")


## Commandes produites par l'IA à chaque frame.
func _ai_log(profile: AIProfile, shared_frames: int, late_buttons: int, late_direction: Vector2i) -> Array[Vector3i]:
	var ai: AIController = _build(FighterRegistry.K_BLAZE, FighterRegistry.AMAZONE, 1200.0, profile)
	bench.p1_input.add_step(shared_frames)
	bench.p1_input.add_step(30, late_direction, late_buttons)
	var entries: Array[Vector3i] = []
	for i: int in shared_frames + profile.reaction_frames + 20:
		bench.step()
		entries.append(ai.get_last_output())
	return entries


func test_hard_ai_combos_into_ultimate() -> void:
	_build(FighterRegistry.AMAZONE, FighterRegistry.K_BLAZE, 200.0, AIProfile.load_profile(AIProfile.Difficulty.HARD))
	bench.p2.add_gauge(GameConstants.SUPER_GAUGE_MAX)
	var started: Array[MoveData] = []
	bench.p2.move_started.connect(func(move: MoveData) -> void: started.append(move))
	var best_combo: Array[int] = [0]
	bench.simulation.combo_tracker.combo_finished.connect(
		func(side: int, hits: int, _damage: int) -> void:
			if side == AI_SIDE:
				best_combo[0] = maxi(best_combo[0], hits))
	bench.step(400)
	assert_true(bench.p2.data.ultimate_move in started, "DIFFICILE place son ultime")
	assert_true(best_combo[0] >= 3, "DIFFICILE enchaîne un combo d'au moins 3 coups (%d)" % best_combo[0])


func test_counter_fighter_uses_royal_counter() -> void:
	var profile: AIProfile = _defensive(AIProfile.Difficulty.HARD)
	profile.block_chance = 0.0
	profile.counter_chance = 1.0
	_build(FighterRegistry.K_BLAZE, FighterRegistry.AMAZONE, 300.0, profile)
	var countered: Array[bool] = []
	bench.p2.counter_triggered.connect(func(_a: Fighter, _s: MoveData) -> void: countered.append(true))
	bench.p1_input.add_step(1, Vector2i.ZERO, InputFrame.SPECIAL)
	bench.step(60)
	assert_eq(countered.size(), 1, "AMAZONE contre le Magnan Rush perçu à temps")
	assert_eq(bench.p2.health, bench.p2.data.max_health, "Aucun dégât subi")


func test_hard_ai_punishes_whiffed_sweep() -> void:
	var profile: AIProfile = _defensive(AIProfile.Difficulty.HARD)
	profile.block_chance = 0.0
	profile.punish_chance = 1.0
	_build(FighterRegistry.K_BLAZE, FighterRegistry.AMAZONE, 240.0, profile)
	var sweep: MoveData = bench.p1.data.crouch_heavy_attack
	bench.p1_input.add_step(1, Vector2i.DOWN, InputFrame.KICK)
	bench.step(sweep.get_total_frames() + 5)
	assert_true(bench.hits.size() >= 1, "L'IA a frappé")
	if not bench.hits.is_empty():
		assert_eq(bench.hits[0][0], bench.p2, "Le premier impact vient de l'IA (le balayage a raté)")
		assert_eq(bench.hits[0][2], bench.p2.data.heavy_attack, "Punition à l'attaque lourde")
