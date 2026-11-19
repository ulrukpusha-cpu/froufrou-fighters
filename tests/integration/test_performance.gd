extends TestCase
## Phase 11 : la simulation du combat ne crée aucun objet par frame (pas de ramasse-miettes
## ni de fuite pendant un combat) et reste très loin du budget d'une frame à 60 FPS.

const WARMUP_FRAMES: int = 120
const MEASURED_FRAMES: int = 1800
const FRAME_BUDGET_MS: float = 1000.0 / 60.0
## Seuil volontairement large (machines de test lentes) : la mesure réelle est ~0,1 ms.
const MAX_AVERAGE_SHARE: float = 0.15

var bench: CombatBench


func before_each() -> void:
	bench = CombatBench.new()


func after_each() -> void:
	bench.free_bench()


func _objects() -> int:
	return int(Performance.get_monitor(Performance.OBJECT_COUNT))


func test_simulation_allocates_no_objects() -> void:
	assert_true(bench.build(tree.root, FighterRegistry.K_BLAZE, FighterRegistry.AMAZONE, 400.0), "Banc construit")
	var hard: AIProfile = AIProfile.load_profile(AIProfile.Difficulty.HARD)
	bench.set_controller(GameConstants.SIDE_P1, AIController.new(hard, 3))
	bench.set_controller(GameConstants.SIDE_P2, AIController.new(hard, 5))
	bench.step(WARMUP_FRAMES)
	var before: int = _objects()
	var start: int = Time.get_ticks_usec()
	for i: int in MEASURED_FRAMES:
		bench.simulation.step()
		# Les KO remettent les combattants en jeu pour garder un combat actif tout du long.
		for fighter: Fighter in [bench.p1, bench.p2]:
			if fighter.get_state() == Fighter.State.DEFEAT:
				fighter.reset_for_round(Vector2(fighter.global_position.x, 0.0))
				fighter.input_enabled = true
	var average_ms: float = (Time.get_ticks_usec() - start) / 1000.0 / MEASURED_FRAMES
	print("          simulation : %.3f ms / frame, %d impacts" % [average_ms, bench.hits.size()])
	assert_true(bench.hits.size() > 20, "Les deux IA se sont vraiment battues (%d impacts)" % bench.hits.size())
	assert_eq(_objects() - before, 0, "Aucun objet créé pendant %d frames de combat" % MEASURED_FRAMES)
	assert_true(average_ms < FRAME_BUDGET_MS * MAX_AVERAGE_SHARE,
		"Simulation sous %.0f %% du budget (%.3f ms)" % [MAX_AVERAGE_SHARE * 100.0, average_ms])
