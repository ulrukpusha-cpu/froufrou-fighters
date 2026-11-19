extends TestCase
## Phases 4-5 : mémoire des commandes, chronologie des attaques, machine à états.


func _make_move(startup: int, active: int, recovery: int) -> MoveData:
	var move := MoveData.new()
	move.id = &"test"
	move.startup_frames = startup
	move.active_frames = active
	move.recovery_frames = recovery
	var box := HitboxData.new()
	move.hitboxes = [box] as Array[HitboxData]
	return move


func test_buffer_keeps_press_for_window() -> void:
	var buffer := InputBuffer.new(4)
	buffer.push(InputFrame.PUNCH)
	for i: int in 3:
		buffer.push(0)
	assert_true(buffer.has(InputFrame.PUNCH), "Appui encore dans la fenêtre")
	buffer.push(0)
	assert_false(buffer.has(InputFrame.PUNCH), "Appui oublié après la fenêtre")


func test_buffer_consume_prevents_double_use() -> void:
	var buffer := InputBuffer.new(6)
	buffer.push(InputFrame.KICK)
	buffer.consume(InputFrame.KICK)
	assert_false(buffer.has(InputFrame.KICK), "Un appui consommé ne sert qu'une fois")


func test_buffer_detects_simultaneous_buttons() -> void:
	var buffer := InputBuffer.new(6)
	buffer.push(InputFrame.PUNCH)
	buffer.push(InputFrame.KICK)
	assert_true(buffer.has_all(InputFrame.THROW_BUTTONS, 3), "Poing puis Pied à 1 frame = projection")
	buffer.push(0)
	buffer.push(0)
	assert_false(buffer.has_all(InputFrame.THROW_BUTTONS, 2), "Hors fenêtre")


func test_buffer_merge_does_not_age() -> void:
	var buffer := InputBuffer.new(2)
	buffer.push(0)
	for i: int in 10:
		buffer.merge(InputFrame.SPECIAL if i == 0 else 0)
	assert_true(buffer.has(InputFrame.SPECIAL), "Pendant le gel d'impact, la mémoire ne vieillit pas")


func test_move_phases_follow_frame_data() -> void:
	var move: MoveData = _make_move(4, 3, 7)
	assert_eq(move.get_total_frames(), 14, "Durée totale")
	assert_eq(move.get_phase(4), MoveData.Phase.STARTUP, "Frame 4 = startup")
	assert_eq(move.get_phase(5), MoveData.Phase.ACTIVE, "Frame 5 = première active")
	assert_eq(move.get_phase(7), MoveData.Phase.ACTIVE, "Frame 7 = dernière active")
	assert_eq(move.get_phase(8), MoveData.Phase.RECOVERY, "Frame 8 = recovery")
	assert_eq(move.get_phase(15), MoveData.Phase.FINISHED, "Frame 15 = terminée")


func test_runner_single_hit_per_target() -> void:
	var runner := MoveRunner.new()
	runner.start(_make_move(1, 5, 1))
	runner.advance()
	assert_true(runner.can_hit(42), "Première frame active : peut toucher")
	runner.register_hit(42, false)
	runner.advance()
	assert_false(runner.can_hit(42), "Pas de second impact sur la même cible")
	assert_true(runner.can_hit(7), "Une autre cible reste touchable")


func test_runner_multi_hit_respects_interval() -> void:
	var move: MoveData = _make_move(1, 10, 1)
	move.max_hits = 2
	move.rehit_interval_frames = 3
	var runner := MoveRunner.new()
	runner.start(move)
	runner.advance()
	runner.register_hit(1, false)
	runner.advance()
	assert_false(runner.can_hit(1), "Intervalle non écoulé")
	runner.advance()
	runner.advance()
	assert_true(runner.can_hit(1), "Second impact autorisé après l'intervalle")
	runner.register_hit(1, false)
	for i: int in 4:
		runner.advance()
	assert_false(runner.can_hit(1), "max_hits atteint")


func test_runner_cancel_conditions() -> void:
	var move: MoveData = _make_move(2, 2, 5)
	move.cancel_condition = MoveData.CancelCondition.ON_HIT
	move.cancel_into = [&"next"] as Array[StringName]
	var next: MoveData = _make_move(1, 1, 1)
	next.id = &"next"
	var runner := MoveRunner.new()
	runner.start(move)
	runner.advance()
	runner.advance()
	assert_false(runner.can_cancel_into(next), "Pas d'annulation dans le vide")
	runner.register_hit(1, true)
	assert_false(runner.can_cancel_into(next), "ON_HIT : pas d'annulation sur garde")
	runner.register_hit(2, false)
	assert_true(runner.can_cancel_into(next), "ON_HIT : annulation après un impact")
	next.id = &"other"
	assert_false(runner.can_cancel_into(next), "Seulement vers les attaques listées")


func test_hitbox_data_window() -> void:
	var box := HitboxData.new()
	box.delay_frames = 1
	box.duration_frames = 2
	assert_false(box.is_active_at(0, 5), "Avant le délai")
	assert_true(box.is_active_at(1, 5), "Pendant")
	assert_true(box.is_active_at(2, 5), "Pendant")
	assert_false(box.is_active_at(3, 5), "Après la durée")


func test_state_machine_terminal_states() -> void:
	var machine := FighterStateMachine.new()
	machine.change(Fighter.State.WALK)
	machine.tick()
	machine.tick()
	assert_eq(machine.frames_in_state, 2, "Compteur de frames")
	machine.change(Fighter.State.WALK)
	assert_eq(machine.frames_in_state, 2, "Même état sans restart : compteur conservé")
	machine.change(Fighter.State.WALK, true)
	assert_eq(machine.frames_in_state, 0, "Restart : compteur remis à zéro")
	machine.change(Fighter.State.VICTORY)
	assert_false(machine.change(Fighter.State.IDLE), "VICTORY est terminal")
	machine.reset()
	assert_eq(machine.current, Fighter.State.IDLE, "reset() sort de l'état terminal")


func test_fighters_data_is_valid() -> void:
	for fighter_id: StringName in FighterRegistry.ROSTER:
		var data: FighterData = FighterRegistry.load_fighter(fighter_id)
		assert_not_null(data, "Données chargées : %s" % fighter_id)
		if data == null:
			continue
		assert_eq(data.max_health, GameConstants.MAX_HEALTH, "Santé de %s" % fighter_id)
		assert_true(data.get_all_moves().size() >= 9, "Au moins 9 attaques pour %s" % fighter_id)
		assert_true(data.special_move != null and data.special_move.is_special(), "Spécial de %s" % fighter_id)
		assert_eq(data.ultimate_move.gauge_cost, GameConstants.SUPER_GAUGE_MAX, "L'ultime coûte 3 niveaux")
		for animation: StringName in Fighter.STATE_ANIMATIONS.values():
			assert_true(data.sprite_frames.has_animation(animation), "%s : animation %s" % [fighter_id, animation])


func test_fighters_have_distinct_identity() -> void:
	var blaze: FighterData = FighterRegistry.load_fighter(FighterRegistry.K_BLAZE)
	var amazone: FighterData = FighterRegistry.load_fighter(FighterRegistry.AMAZONE)
	assert_true(blaze.walk_speed > amazone.walk_speed, "K.BLAZE est le plus rapide")
	assert_true(amazone.heavy_attack.damage > blaze.heavy_attack.damage, "AMAZONE frappe plus fort")
	assert_eq(blaze.specialty_name, "Magnan Rush", "Spécialité de K.BLAZE")
	assert_eq(amazone.specialty_name, "Royal Counter", "Spécialité d'AMAZONE")
