extends TestCase
## Phases 4-5 : déplacements, hitboxes, dégâts, garde, projections, combos, KO,
## sur deux vrais combattants simulés frame par frame.

const CLOSE: float = 180.0
const FAR: float = 700.0

var bench: CombatBench


func before_each() -> void:
	bench = CombatBench.new()


func after_each() -> void:
	bench.free_bench()


func _build(distance: float) -> bool:
	var ok: bool = bench.build(tree.root, FighterRegistry.K_BLAZE, FighterRegistry.AMAZONE, distance)
	assert_true(ok, "Le banc de combat doit se construire")
	return ok


func _has_hit() -> bool:
	return not bench.hits.is_empty()


func test_walk_forward_and_face_opponent() -> void:
	if not _build(FAR):
		return
	var start_x: float = bench.p1.global_position.x
	bench.p1_input.add_step(30, Vector2i.RIGHT)
	bench.step(30)
	var expected: float = bench.p1.data.walk_speed * 30.0 * GameConstants.FRAME_DURATION
	assert_true(absf(bench.p1.global_position.x - start_x - expected) < 1.0, "Marche avant à walk_speed")
	assert_eq(bench.p1.get_state(), Fighter.State.WALK, "État WALK")
	bench.p1.global_position.x = bench.p2.global_position.x + 300.0
	bench.step(2)
	assert_eq(bench.p1.facing, -1, "Se retourne vers l'adversaire")


func test_jump_and_land() -> void:
	if not _build(FAR):
		return
	bench.p1_input.add_step(1, Vector2i.UP)
	bench.step(2)
	assert_eq(bench.p1.get_state(), Fighter.State.JUMP, "État JUMP")
	assert_false(bench.p1.is_grounded(), "En l'air")
	var landed: bool = bench.step_until(func() -> bool: return bench.p1.get_state() == Fighter.State.IDLE, 120)
	assert_true(landed, "Atterrit et revient à IDLE")
	assert_eq(bench.p1.global_position.y, bench.stage.get_floor_y(), "Pieds au sol")


func test_hitbox_active_only_during_active_frames() -> void:
	if not _build(FAR):
		return
	var move: MoveData = bench.p1.data.light_attack
	bench.p1_input.add_step(1, Vector2i.ZERO, InputFrame.PUNCH)
	var active_frames: Array[int] = []
	for i: int in move.get_total_frames() + 3:
		bench.step()
		if not bench.p1.get_active_hitboxes().is_empty():
			active_frames.append(bench.p1.move_runner.frame)
	var expected: Array[int] = []
	for frame: int in range(move.get_first_active_frame(), move.get_first_active_frame() + move.active_frames):
		expected.append(frame)
	assert_eq(active_frames, expected, "Hitbox active exactement pendant les frames actives")
	assert_eq(bench.p1.get_state(), Fighter.State.IDLE, "Retour à IDLE après la recovery")


func test_light_attack_hits_exactly_once() -> void:
	if not _build(CLOSE):
		return
	var move: MoveData = bench.p1.data.light_attack
	bench.p1_input.add_step(1, Vector2i.ZERO, InputFrame.PUNCH)
	assert_true(bench.step_until(_has_hit, 20), "L'attaque légère doit toucher")
	assert_eq(bench.p2.get_state(), Fighter.State.HITSTUN, "Défenseur en HITSTUN")
	bench.step(40)
	assert_eq(bench.hits.size(), 1, "Un seul impact malgré plusieurs frames actives")
	assert_eq(bench.p2.health, bench.p2.data.max_health - move.damage, "Dégâts appliqués une fois")
	assert_true(bench.p1.gauge > 0, "L'attaquant gagne de la jauge")
	assert_eq(bench.p2.get_state(), Fighter.State.IDLE, "Le défenseur récupère")


func test_pushback_distance_is_bounded() -> void:
	if not _build(CLOSE):
		return
	var move: MoveData = bench.p1.data.light_attack
	var start_x: float = bench.p2.global_position.x
	bench.p1_input.add_step(1, Vector2i.ZERO, InputFrame.PUNCH)
	bench.step(40)
	var moved: float = bench.p2.global_position.x - start_x
	# Régression : le défenseur glissait pendant tout son hitstun au lieu de reculer de « pushback ».
	assert_true(absf(moved - move.pushback) < 1.0, "Recul = pushback (%.1f px au lieu de %.1f)" % [moved, move.pushback])


func test_guard_blocks_mid_attack() -> void:
	if not _build(CLOSE):
		return
	bench.p2_input.add_step(60, Vector2i.ZERO, InputFrame.GUARD)
	bench.p1_input.add_step(1, Vector2i.ZERO, InputFrame.PUNCH)
	assert_true(bench.step_until(_has_hit, 20), "Contact attendu")
	assert_true(bench.hits[0][3], "Attaque parée")
	assert_eq(bench.p2.get_state(), Fighter.State.BLOCKSTUN, "Défenseur en BLOCKSTUN")
	assert_eq(bench.p2.health, bench.p2.data.max_health, "Aucun dégât sur garde")


func test_holding_back_also_blocks() -> void:
	if not _build(CLOSE):
		return
	bench.p2_input.add_step(60, Vector2i.RIGHT)
	bench.p1_input.add_step(1, Vector2i.ZERO, InputFrame.PUNCH)
	assert_true(bench.step_until(_has_hit, 20), "Contact attendu")
	assert_true(bench.hits[0][3], "Maintenir l'arrière pare")


func test_low_attack_needs_crouch_guard() -> void:
	if not _build(CLOSE):
		return
	bench.p2_input.add_step(60, Vector2i.ZERO, InputFrame.GUARD)
	bench.p1_input.add_step(1, Vector2i.DOWN, InputFrame.PUNCH)
	assert_true(bench.step_until(_has_hit, 20), "Contact attendu")
	assert_eq(bench.hits[0][2], bench.p1.data.crouch_light_attack, "Attaque basse")
	assert_false(bench.hits[0][3], "Une attaque basse passe la garde debout")
	bench.free_bench()
	bench = CombatBench.new()
	if not _build(CLOSE):
		return
	bench.p2_input.add_step(60, Vector2i.DOWN, InputFrame.GUARD)
	bench.p1_input.add_step(1, Vector2i.DOWN, InputFrame.PUNCH)
	assert_true(bench.step_until(_has_hit, 20), "Contact attendu")
	assert_true(bench.hits[0][3], "La garde accroupie pare l'attaque basse")


func test_overhead_beats_crouch_guard() -> void:
	if not _build(CLOSE):
		return
	bench.p2_input.add_step(60, Vector2i.DOWN, InputFrame.GUARD)
	bench.step(5)
	assert_true(bench.p2.is_crouching() and bench.p2.is_guarding(), "Garde accroupie en place")
	var blocked: bool = bench.p2.take_hit(bench.p1, bench.p1.data.air_heavy_attack)
	assert_false(blocked, "Une attaque sautée passe la garde accroupie")


func test_throw_beats_guard() -> void:
	if not _build(CLOSE):
		return
	var throw_move: MoveData = bench.p1.data.throw_move
	bench.p2_input.add_step(60, Vector2i.ZERO, InputFrame.GUARD)
	bench.p1_input.add_step(1, Vector2i.ZERO, InputFrame.THROW_BUTTONS)
	assert_true(bench.step_until(_has_hit, 20), "La projection doit saisir")
	assert_eq(bench.hits[0][2], throw_move, "C'est la projection qui touche")
	assert_false(bench.hits[0][3], "Une projection est imparable")
	assert_eq(bench.p2.get_state(), Fighter.State.KNOCKDOWN, "Le défenseur chute")
	assert_eq(bench.p2.health, bench.p2.data.max_health - throw_move.damage, "Dégâts de projection")


func test_kara_throw_from_staggered_buttons() -> void:
	if not _build(CLOSE):
		return
	bench.p1_input.add_step(1, Vector2i.ZERO, InputFrame.PUNCH)
	bench.p1_input.add_step(1, Vector2i.ZERO, InputFrame.THROW_BUTTONS)
	assert_true(bench.step_until(_has_hit, 20), "Contact attendu")
	assert_eq(bench.hits[0][2], bench.p1.data.throw_move, "Poing puis Pied à 1 frame = projection")


func test_light_cancels_into_heavy_combo() -> void:
	if not _build(CLOSE):
		return
	var light: MoveData = bench.p1.data.light_attack
	var heavy: MoveData = bench.p1.data.heavy_attack
	bench.p1_input.add_step(1, Vector2i.ZERO, InputFrame.PUNCH)
	bench.p1_input.add_step(5)
	bench.p1_input.add_step(1, Vector2i.ZERO, InputFrame.KICK)
	bench.step(60)
	assert_eq(bench.hits.size(), 2, "Deux impacts : léger puis lourd")
	if bench.hits.size() == 2:
		assert_eq(bench.hits[0][2], light, "Premier coup : léger")
		assert_eq(bench.hits[1][2], heavy, "Second coup : lourd (annulation)")
	assert_eq(bench.p2.health, bench.p2.data.max_health - light.damage - heavy.damage, "Dégâts cumulés")


func test_dodge_grants_invulnerability() -> void:
	if not _build(CLOSE):
		return
	bench.p2_input.add_step(1, Vector2i.ZERO, InputFrame.DODGE)
	bench.step(2)
	assert_eq(bench.p2.get_state(), Fighter.State.DODGE, "État DODGE")
	assert_true(bench.p2.is_invulnerable(), "Invulnérable pendant l'esquive")
	bench.step(bench.p2.data.dodge_frames + 2)
	assert_false(bench.p2.is_invulnerable(), "Vulnérable après l'esquive")


func test_pushboxes_prevent_overlap() -> void:
	if not _build(CLOSE):
		return
	bench.p1_input.add_step(90, Vector2i.RIGHT)
	bench.step(90)
	var gap: float = absf(bench.p2.global_position.x - bench.p1.global_position.x)
	var min_gap: float = (bench.p1.get_body_width() + bench.p2.get_body_width()) * 0.5
	assert_true(gap >= min_gap - 0.5, "Les combattants ne se traversent pas (écart %.1f)" % gap)
	assert_true(bench.p1.facing == 1 and bench.p2.facing == -1, "Toujours face à face")


func test_knockout_leads_to_defeat() -> void:
	if not _build(CLOSE):
		return
	var knocked: Array[Fighter] = []
	bench.p2.knocked_out.connect(func(fighter: Fighter) -> void: knocked.append(fighter))
	var lethal: MoveData = bench.p1.data.heavy_attack.duplicate() as MoveData
	lethal.damage = GameConstants.MAX_HEALTH
	bench.p2.take_hit(bench.p1, lethal)
	assert_eq(bench.p2.health, 0, "Santé à zéro")
	assert_eq(knocked.size(), 1, "Signal knocked_out émis")
	var defeated: bool = bench.step_until(func() -> bool: return bench.p2.get_state() == Fighter.State.DEFEAT, 240)
	assert_true(defeated, "Chute puis DEFEAT")
	assert_true(bench.p2.is_grounded(), "Au sol")
