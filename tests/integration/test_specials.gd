extends TestCase
## Phase 6 : Magnan Rush, Royal Counter, ultimes, annulations vers les spéciaux,
## compteur de combos et mode assisté.

const CLOSE: float = 180.0
const MID_RANGE: float = 300.0

var bench: CombatBench


func before_each() -> void:
	bench = CombatBench.new()


func after_each() -> void:
	bench.free_bench()


func _build(p1_id: StringName, p2_id: StringName, distance: float) -> bool:
	var ok: bool = bench.build(tree.root, p1_id, p2_id, distance)
	assert_true(ok, "Le banc de combat doit se construire")
	return ok


func _hits_with(move: MoveData) -> int:
	var count: int = 0
	for hit: Array in bench.hits:
		if hit[2] == move:
			count += 1
	return count


func test_magnan_rush_three_hits_then_knockdown() -> void:
	if not _build(FighterRegistry.K_BLAZE, FighterRegistry.AMAZONE, MID_RANGE):
		return
	var rush: MoveData = bench.p1.data.special_move
	var states: Array[Fighter.State] = []
	bench.p2.hit_received.connect(func(_a: Fighter, _m: MoveData, _b: bool) -> void: states.append(bench.p2.get_state()))
	bench.p1_input.add_step(1, Vector2i.ZERO, InputFrame.SPECIAL)
	bench.step(90)
	assert_eq(_hits_with(rush), 3, "Magnan Rush touche 3 fois")
	assert_eq(states, [Fighter.State.HITSTUN, Fighter.State.HITSTUN, Fighter.State.KNOCKDOWN] as Array[Fighter.State],
		"Seul le dernier impact fait chuter")
	assert_eq(bench.p2.health, bench.p2.data.max_health - rush.damage * 3, "Dégâts des 3 impacts")


func test_royal_counter_reverses_a_strike() -> void:
	if not _build(FighterRegistry.AMAZONE, FighterRegistry.K_BLAZE, CLOSE):
		return
	var countered: Array[MoveData] = []
	bench.p1.counter_triggered.connect(func(_a: Fighter, stance: MoveData) -> void: countered.append(stance))
	bench.p1_input.add_step(1, Vector2i.ZERO, InputFrame.SPECIAL)
	bench.p2_input.add_step(3)
	bench.p2_input.add_step(1, Vector2i.ZERO, InputFrame.PUNCH)
	bench.step(80)
	var strike: MoveData = bench.p1.data.special_move.counter_follow_up
	assert_eq(countered.size(), 1, "Le contre se déclenche")
	assert_eq(bench.p1.health, bench.p1.data.max_health, "AMAZONE ne subit aucun dégât")
	assert_eq(_hits_with(strike), 1, "La riposte royale touche")
	assert_eq(bench.p2.health, bench.p2.data.max_health - strike.damage, "Dégâts de la riposte")


func test_throw_beats_royal_counter() -> void:
	if not _build(FighterRegistry.AMAZONE, FighterRegistry.K_BLAZE, CLOSE):
		return
	bench.p1_input.add_step(1, Vector2i.ZERO, InputFrame.SPECIAL)
	bench.p2_input.add_step(5)
	bench.p2_input.add_step(1, Vector2i.ZERO, InputFrame.THROW_BUTTONS)
	bench.step(40)
	assert_eq(_hits_with(bench.p2.data.throw_move), 1, "La projection passe la posture de contre")
	assert_eq(bench.p1.health, bench.p1.data.max_health - bench.p2.data.throw_move.damage, "AMAZONE est projetée")


func test_ultimate_requires_full_gauge() -> void:
	if not _build(FighterRegistry.K_BLAZE, FighterRegistry.AMAZONE, 900.0):
		return
	var started: Array[MoveData] = []
	bench.p1.move_started.connect(func(move: MoveData) -> void: started.append(move))
	bench.p1_input.add_step(1, Vector2i.DOWN, InputFrame.SPECIAL)
	bench.step(2)
	assert_eq(started[0], bench.p1.data.special_move, "Sans jauge : Bas + Spécial donne le spécial")
	bench.step(80)
	bench.p1.add_gauge(GameConstants.SUPER_GAUGE_MAX)
	bench.p1_input.clear_steps()
	bench.p1_input.add_step(1, Vector2i.DOWN, InputFrame.SPECIAL)
	bench.step(2)
	assert_eq(started.back(), bench.p1.data.ultimate_move, "Jauge pleine : l'ultime part")
	assert_eq(bench.p1.gauge, 0, "L'ultime consomme toute la jauge")
	assert_true(bench.p1.is_invulnerable(), "Invulnérable au démarrage de l'ultime")


func test_buffered_down_special_still_gives_ultimate() -> void:
	if not _build(FighterRegistry.K_BLAZE, FighterRegistry.AMAZONE, CLOSE):
		return
	bench.p1.add_gauge(GameConstants.SUPER_GAUGE_MAX)
	bench.p1_input.add_step(1, Vector2i.ZERO, InputFrame.KICK)
	bench.p1_input.add_step(9)
	# Bas + Spécial pendant le gel d'impact, Bas relâché avant que l'annulation ne parte.
	bench.p1_input.add_step(1, Vector2i.DOWN, InputFrame.SPECIAL)
	bench.step(120)
	# Régression : la direction était relue au moment de l'annulation, donnant le spécial.
	assert_true(_hits_with(bench.p1.data.ultimate_move) >= 1, "L'intention « Bas + Spécial » est mémorisée")
	assert_eq(_hits_with(bench.p1.data.special_move), 0, "Pas de Magnan Rush à la place")


func test_ultimate_lands_full_damage() -> void:
	if not _build(FighterRegistry.AMAZONE, FighterRegistry.K_BLAZE, MID_RANGE):
		return
	var ultimate: MoveData = bench.p1.data.ultimate_move
	bench.p1.add_gauge(GameConstants.SUPER_GAUGE_MAX)
	bench.p1_input.add_step(1, Vector2i.DOWN, InputFrame.SPECIAL)
	bench.step(60)
	assert_eq(_hits_with(ultimate), 1, "La Charge des Agojie touche")
	assert_eq(bench.p2.health, bench.p2.data.max_health - ultimate.damage, "Dégâts de l'ultime")
	assert_eq(bench.p2.get_state(), Fighter.State.KNOCKDOWN, "L'adversaire chute")


func test_heavy_cancels_into_magnan_rush() -> void:
	if not _build(FighterRegistry.K_BLAZE, FighterRegistry.AMAZONE, CLOSE):
		return
	var combos: Array[int] = []
	bench.simulation.combo_tracker.combo_finished.connect(func(_s: int, hits: int, _d: int) -> void: combos.append(hits))
	bench.p1_input.add_step(1, Vector2i.ZERO, InputFrame.KICK)
	bench.p1_input.add_step(9)
	bench.p1_input.add_step(1, Vector2i.ZERO, InputFrame.SPECIAL)
	bench.step(120)
	assert_eq(_hits_with(bench.p1.data.heavy_attack), 1, "Lourd")
	assert_eq(_hits_with(bench.p1.data.special_move), 3, "Annulé en Magnan Rush")
	assert_eq(combos, [4] as Array[int], "Un seul combo de 4 coups")


func test_combo_counter_counts_hits_and_damage() -> void:
	if not _build(FighterRegistry.K_BLAZE, FighterRegistry.AMAZONE, CLOSE):
		return
	var finished: Array[Array] = []
	bench.simulation.combo_tracker.combo_finished.connect(
		func(side: int, hits: int, damage: int) -> void: finished.append([side, hits, damage]))
	bench.p1_input.add_step(1, Vector2i.ZERO, InputFrame.PUNCH)
	bench.p1_input.add_step(5)
	bench.p1_input.add_step(1, Vector2i.ZERO, InputFrame.KICK)
	bench.step(90)
	var expected_damage: int = bench.p1.data.light_attack.damage + bench.p1.data.heavy_attack.damage
	assert_eq(finished.size(), 1, "Le combo se termine quand l'adversaire récupère")
	if not finished.is_empty():
		assert_eq(finished[0], [GameConstants.SIDE_P1, 2, expected_damage], "2 coups, dégâts cumulés")


func test_single_hit_is_not_a_combo() -> void:
	if not _build(FighterRegistry.K_BLAZE, FighterRegistry.AMAZONE, CLOSE):
		return
	var finished: Array[int] = []
	bench.simulation.combo_tracker.combo_finished.connect(func(_s: int, hits: int, _d: int) -> void: finished.append(hits))
	bench.p1_input.add_step(1, Vector2i.ZERO, InputFrame.PUNCH)
	bench.step(60)
	assert_true(finished.is_empty(), "Un coup isolé n'est pas annoncé comme combo")


func test_assisted_mode_chains_by_mashing_punch() -> void:
	if not _build(FighterRegistry.K_BLAZE, FighterRegistry.AMAZONE, CLOSE):
		return
	bench.p1_input.assisted = true
	for i: int in 4:
		bench.p1_input.add_step(1, Vector2i.ZERO, InputFrame.PUNCH)
		bench.p1_input.add_step(4)
	bench.step(120)
	var data: FighterData = bench.p1.data
	assert_eq(_hits_with(data.light_attack), 1, "Poing 1 : léger")
	assert_eq(_hits_with(data.heavy_attack), 1, "Poing 2 : lourd automatique")
	assert_eq(_hits_with(data.special_move), 3, "Poing 3 : Magnan Rush automatique")


func test_assisted_whiffed_punch_stays_a_punch() -> void:
	if not _build(FighterRegistry.K_BLAZE, FighterRegistry.AMAZONE, 900.0):
		return
	bench.p1_input.assisted = true
	var started: Array[MoveData] = []
	bench.p1.move_started.connect(func(move: MoveData) -> void: started.append(move))
	bench.p1_input.add_step(1, Vector2i.ZERO, InputFrame.PUNCH)
	bench.p1_input.add_step(8)
	bench.p1_input.add_step(1, Vector2i.ZERO, InputFrame.PUNCH)
	bench.step(60)
	var light: MoveData = bench.p1.data.light_attack
	assert_eq(started, [light, light] as Array[MoveData], "Dans le vide, deux Poings restent deux attaques légères")


func test_assisted_special_shortcut_uses_ultimate() -> void:
	if not _build(FighterRegistry.K_BLAZE, FighterRegistry.AMAZONE, 900.0):
		return
	var assist := AssistedInput.new()
	var frame := InputFrame.new()
	frame.set_from(Vector2i.ZERO, InputFrame.SPECIAL, 0)
	assist.apply(frame, bench.p1)
	assert_eq(frame.direction.y, 0, "Jauge vide : pas de raccourci")
	bench.p1.add_gauge(GameConstants.SUPER_GAUGE_MAX)
	assist.apply(frame, bench.p1)
	assert_eq(frame.direction.y, 1, "Jauge pleine : Spécial seul déclenche l'ultime")
