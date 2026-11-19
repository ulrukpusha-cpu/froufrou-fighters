extends TestCase
## Phases 2 et 5 : déroulement d'un match complet dans la vraie scène de combat,
## HUD, écrans de menu et navigation.

const FIGHT_SCENE: String = "res://scenes/combat/fight_scene.tscn"

var scene: Node = null


func after_each() -> void:
	if scene != null and is_instance_valid(scene):
		scene.queue_free()
	scene = null


func _start_fight() -> FightManager:
	GameSession.set_selection(FighterRegistry.K_BLAZE, FighterRegistry.AMAZONE)
	scene = (load(FIGHT_SCENE) as PackedScene).instantiate()
	scene.set("auto_start", false)
	tree.root.add_child(scene)
	var manager: FightManager = scene.call("get_manager") as FightManager
	# Ces tests portent sur le déroulement du match : l'adversaire est un mannequin.
	var opponent: Fighter = scene.get("opponent") as Fighter
	var dummy := FighterController.new()
	opponent.add_child(dummy)
	opponent.controller = dummy
	manager.auto_run = false
	manager.go_to_results = false
	manager.round_intro_frames = 2
	manager.round_over_frames = 4
	manager.victory_pose_delay_frames = 1
	manager.start_match()
	return manager


func _knock_out(manager: FightManager, side: int) -> void:
	var victim: Fighter = manager.fighters[side]
	var attacker: Fighter = manager.fighters[1 - side]
	var lethal: MoveData = attacker.data.heavy_attack.duplicate() as MoveData
	lethal.damage = GameConstants.MAX_HEALTH
	victim.take_hit(attacker, lethal)


func _step_until_phase(manager: FightManager, target: FightManager.Phase, max_frames: int) -> bool:
	for i: int in max_frames:
		if manager.phase == target:
			return true
		manager.step()
	return manager.phase == target


func test_round_intro_then_fight() -> void:
	var manager: FightManager = _start_fight()
	assert_eq(manager.phase, FightManager.Phase.ROUND_INTRO, "Intro de manche")
	assert_false(manager.fighters[0].input_enabled, "Commandes bloquées pendant l'intro")
	assert_true(_step_until_phase(manager, FightManager.Phase.FIGHTING, 10), "Le combat commence")
	assert_true(manager.fighters[0].input_enabled, "Commandes actives")
	assert_eq(manager.get_seconds_left(), GameConstants.ROUND_TIME_SECONDS, "Timer à 99")
	assert_true(manager.fighters[0].data.id == FighterRegistry.K_BLAZE, "Le joueur incarne le combattant choisi")


func test_two_knockouts_win_the_match() -> void:
	var manager: FightManager = _start_fight()
	var played_before: int = int(SaveManager.get_stats()["matches_played"])
	var results: Array[MatchResult] = []
	manager.match_ended.connect(func(match_result: MatchResult) -> void: results.append(match_result))
	for round_index: int in GameConstants.ROUNDS_TO_WIN:
		assert_true(_step_until_phase(manager, FightManager.Phase.FIGHTING, 20), "Manche %d lancée" % (round_index + 1))
		_knock_out(manager, GameConstants.SIDE_P2)
		manager.step()
		assert_eq(manager.phase, FightManager.Phase.ROUND_OVER, "Le KO termine la manche")
		assert_eq(manager.rounds_won[GameConstants.SIDE_P1], round_index + 1, "Manche attribuée au J1")
	assert_true(_step_until_phase(manager, FightManager.Phase.MATCH_OVER, 20), "Le match se termine")
	assert_eq(results.size(), 1, "match_ended émis une fois")
	assert_eq(manager.round_number, 2, "Deux manches jouées")
	var result: MatchResult = manager.get_result()
	assert_true(result != null and result.player_won(), "Le joueur 1 gagne")
	assert_eq(GameSession.last_result, result, "Résultat transmis à GameSession")
	assert_eq(manager.fighters[0].get_state(), Fighter.State.VICTORY, "Pose de victoire")
	assert_eq(int(SaveManager.get_stats()["matches_played"]), played_before + 1, "Match enregistré dans les statistiques")


func test_time_out_awards_round_to_health_leader() -> void:
	var manager: FightManager = _start_fight()
	manager.round_time_seconds = 1
	manager.start_match()
	assert_true(_step_until_phase(manager, FightManager.Phase.FIGHTING, 10), "Combat lancé")
	manager.fighters[1].take_hit(manager.fighters[0], manager.fighters[0].data.light_attack)
	assert_true(_step_until_phase(manager, FightManager.Phase.ROUND_OVER, 90), "Fin au temps")
	assert_eq(manager.rounds_won, [1, 0] as Array[int], "Le plus en santé gagne la manche")
	assert_eq(manager.fighters[1].get_state(), Fighter.State.DEFEAT, "Le perdant pose un genou à terre")


func test_hud_follows_the_match() -> void:
	var manager: FightManager = _start_fight()
	var hud: FightHud = scene.get_node("FightHud") as FightHud
	assert_eq(hud.get_announcement(), "MANCHE 1", "Annonce de manche")
	var bar: ProgressBar = hud.get_node("%P2Health") as ProgressBar
	_step_until_phase(manager, FightManager.Phase.FIGHTING, 10)
	var light: MoveData = manager.fighters[0].data.light_attack
	manager.fighters[1].take_hit(manager.fighters[0], light)
	assert_eq(int(bar.value), GameConstants.MAX_HEALTH - light.damage, "La barre de vie suit les dégâts")
	assert_eq((hud.get_node("%P1Name") as Label).text, "K.BLAZE", "Nom du joueur 1")
	assert_not_null(hud.get_portrait(GameConstants.SIDE_P1), "Portrait du joueur 1")
	assert_not_null(hud.get_portrait(GameConstants.SIDE_P2), "Portrait du joueur 2")


func test_character_select_lists_roster() -> void:
	scene = (load(GameConstants.SCENE_CHARACTER_SELECT) as PackedScene).instantiate()
	tree.root.add_child(scene)
	assert_eq(scene.call("get_card_count"), FighterRegistry.ROSTER.size(), "Une carte par combattant")


func test_results_screen_shows_outcome() -> void:
	var result := MatchResult.new()
	result.winner_side = GameConstants.SIDE_P2
	result.fighter_ids = [FighterRegistry.K_BLAZE, FighterRegistry.AMAZONE] as Array[StringName]
	result.rounds_won = [1, 2] as Array[int]
	GameSession.record_result(result)
	scene = (load(GameConstants.SCENE_RESULTS) as PackedScene).instantiate()
	tree.root.add_child(scene)
	assert_eq((scene.get_node("%OutcomeLabel") as Label).text, "DÉFAITE", "Défaite du joueur")
	assert_eq((scene.get_node("%ScoreLabel") as Label).text, "1 – 2", "Score des manches")


func test_router_refuses_missing_scene() -> void:
	var failures: Array[String] = []
	SceneRouter.scene_change_failed.connect(func(path: String, _reason: String) -> void: failures.append(path))
	print("          (l'erreur « Impossible d'ouvrir » qui suit est attendue)")
	var ok: bool = await SceneRouter.go_to("res://scenes/menus/does_not_exist.tscn")
	assert_false(ok, "go_to doit échouer")
	assert_eq(failures.size(), 1, "scene_change_failed émis")


func test_router_changes_scene() -> void:
	var ok: bool = await SceneRouter.go_to(GameConstants.SCENE_MAIN_MENU)
	assert_true(ok, "Navigation vers le menu principal")
	assert_true(tree.current_scene != null and tree.current_scene.name == &"MainMenu", "Scène courante = menu")
	assert_false(SceneRouter.is_busy(), "Transition terminée")
	if tree.current_scene != null:
		tree.current_scene.queue_free()
