extends Node
## Mesures du banc de performance (voir benchmark_combat.gd) :
##   - temps de chargement de la scène de combat (arène, combattants, HUD, menus) ;
##   - coût CPU d'une frame de simulation (IA difficile contre IA difficile), pics compris ;
##   - objets créés pendant le combat, par catégorie (doit rester à 0 : pas de ramasse-miettes
##     ni de fuite en combat).
## Le rendu n'est pas mesuré ici : voir le Movie Maker ou le profileur sur appareil.

const FIGHT_SCENE: String = "res://scenes/combat/fight_scene.tscn"
const SIMULATED_FRAMES: int = 7200
const WARMUP_FRAMES: int = 300
const FRAME_BUDGET_MS: float = 1000.0 / 60.0
const MICROSECONDS_PER_MS: float = 1000.0
const PERCENTILE: float = 0.99
## Une frame au-delà de ce coût est listée comme pic.
const SPIKE_MS: float = 4.0
const MAX_REPORTED_SPIKES: int = 8
const BENCHMARK_SEED_P1: int = 3
const BENCHMARK_SEED_P2: int = 5
const BENCHMARK_SAVE: String = "user://benchmark_save.json"
## Temps réel laissé aux animations d'interface pour se terminer avant la mesure finale.
const SETTLE_SECONDS: float = 2.0


func run() -> void:
	SaveManager.use_save_path(BENCHMARK_SAVE, true)
	var load_start: int = Time.get_ticks_usec()
	var packed: PackedScene = load(FIGHT_SCENE) as PackedScene
	var scene: Node = packed.instantiate()
	get_tree().root.add_child(scene)
	var load_ms: float = (Time.get_ticks_usec() - load_start) / MICROSECONDS_PER_MS
	var manager: FightManager = scene.call("get_manager") as FightManager
	manager.auto_run = false
	manager.go_to_results = false
	var hard: AIProfile = AIProfile.load_profile(AIProfile.Difficulty.HARD)
	_set_ai(scene.get("player") as Fighter, AIController.new(hard, BENCHMARK_SEED_P1))
	_set_ai(scene.get("opponent") as Fighter, AIController.new(hard, BENCHMARK_SEED_P2))
	var timings := PackedFloat32Array()
	var spikes: Array[String] = []
	var baseline: Vector3i = Vector3i.ZERO
	var matches: int = 0
	for frame: int in SIMULATED_FRAMES:
		if manager.phase == FightManager.Phase.MATCH_OVER:
			matches += 1
			manager.start_match()
		var phase_before: String = FightManager.Phase.keys()[manager.phase]
		var start: int = Time.get_ticks_usec()
		manager.step()
		var spent: float = (Time.get_ticks_usec() - start) / MICROSECONDS_PER_MS
		timings.append(spent)
		if spent > SPIKE_MS and spikes.size() < MAX_REPORTED_SPIKES:
			spikes.append("frame %d : %.1f ms (phase %s, manche %d)" % [frame, spent, phase_before, manager.round_number])
		if frame == WARMUP_FRAMES:
			baseline = _object_counts()
	var delta: Vector3i = _object_counts() - baseline
	_report(load_ms, timings, spikes, delta, matches)
	# Le banc enchaîne toute la simulation dans UNE frame moteur : les animations d'interface
	# (Tween du HUD, avec leurs étapes) démarrées pendant le match n'ont pas encore pu se
	# terminer. On laisse s'écouler un peu de temps réel, puis on remesure.
	print("  dont Tweens d'interface en attente : %d" % get_tree().get_processed_tweens().size())
	await get_tree().create_timer(SETTLE_SECONDS).timeout
	await get_tree().process_frame
	var settled: Vector3i = _object_counts() - baseline
	print("Après %.0f s (animations terminées) : %d nœuds, %d ressources, %d autres" % [
		SETTLE_SECONDS, settled.x, settled.y, settled.z])
	print("  (≈ 40 objets créés une seule fois par les premières frames affichées : ce nombre ne")
	print("   grandit pas avec la durée du combat — 10 s ou 4 min donnent le même résultat)")
	scene.queue_free()
	DirAccess.remove_absolute(BENCHMARK_SAVE)
	get_tree().quit()


func _set_ai(fighter: Fighter, ai: AIController) -> void:
	fighter.add_child(ai)
	fighter.controller = ai


## (nœuds, ressources, autres objets) actuellement en mémoire.
func _object_counts() -> Vector3i:
	var nodes: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var resources: int = int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))
	var total: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	return Vector3i(nodes, resources, total - nodes - resources)


func _report(load_ms: float, timings: PackedFloat32Array, spikes: Array[String], delta: Vector3i, matches: int) -> void:
	var sorted: PackedFloat32Array = timings.duplicate()
	sorted.sort()
	var total: float = 0.0
	for value: float in timings:
		total += value
	var average: float = total / timings.size()
	var p99: float = sorted[mini(int(sorted.size() * PERCENTILE), sorted.size() - 1)]
	print("\n=== FROUFROU FIGHTERS — banc de performance ===")
	print("Chargement de la scène de combat : %.1f ms" % load_ms)
	print("Simulation : %d frames (%.0f s de jeu), %d match(s) terminé(s)" % [timings.size(), timings.size() / 60.0, matches])
	print("  moyenne %.3f ms · p99 %.3f ms · pire %.3f ms (budget d'une frame : %.1f ms)" % [
		average, p99, sorted[sorted.size() - 1], FRAME_BUDGET_MS])
	print("  part moyenne du budget : %.1f %%" % (average / FRAME_BUDGET_MS * 100.0))
	print("Pics > %.0f ms : %s" % [SPIKE_MS, "aucun" if spikes.is_empty() else ""])
	for spike: String in spikes:
		print("  - %s" % spike)
	print("Objets créés pendant le combat : %d nœuds, %d ressources, %d autres" % [delta.x, delta.y, delta.z])
	print("Mémoire statique : %.1f Mo" % (OS.get_static_memory_usage() / 1048576.0))
