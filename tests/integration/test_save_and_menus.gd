extends TestCase
## Phase 10 : sauvegarde versionnée (réglages, touches, progression, statistiques),
## écran d'options, personnalisation des touches et menu pause.

const OPTIONS_PANEL: String = "res://scenes/menus/options_panel.tscn"
const FIGHT_SCENE: String = "res://scenes/combat/fight_scene.tscn"

var _test_path: String = ""
var _node: Node = null


func before_each() -> void:
	_test_path = SaveManager.save_path
	SaveManager.use_save_path(_test_path, true)


func after_each() -> void:
	if _node != null and is_instance_valid(_node):
		_node.free()
	_node = null
	tree.paused = false
	for action: StringName in InputActions.ALL_ACTIONS:
		Input.action_release(action)
	SaveManager.use_save_path(_test_path, true)
	if FileAccess.file_exists(_test_path):
		DirAccess.remove_absolute(_test_path)


func _write_raw(text: String) -> void:
	var file: FileAccess = FileAccess.open(_test_path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_settings_survive_a_restart() -> void:
	SaveManager.set_volume(GameConstants.BUS_MUSIC, 0.3)
	SaveManager.set_difficulty(AIProfile.Difficulty.HARD)
	SaveManager.set_control_mode(PlayerController.Mode.ASSISTED)
	SaveManager.set_touch_controls(TouchControls.Visibility.ALWAYS)
	SaveManager.set_binding_key(InputActions.PUNCH, KEY_U)
	assert_true(SaveManager.save(), "Écriture de la sauvegarde")
	# « Redémarrage » : on efface l'état en mémoire puis on relit le fichier.
	GameSession.difficulty = AIProfile.Difficulty.EASY
	GameSession.control_mode = PlayerController.Mode.CLASSIC
	InputActions.restore_defaults()
	assert_true(SaveManager.load_save(), "Relecture de la sauvegarde")
	SaveManager.apply_all()
	assert_true(is_equal_approx(SaveManager.get_volume(GameConstants.BUS_MUSIC), 0.3), "Volume musique conservé")
	assert_eq(GameSession.difficulty, AIProfile.Difficulty.HARD, "Difficulté conservée")
	assert_eq(GameSession.control_mode, PlayerController.Mode.ASSISTED, "Mode de commandes conservé")
	assert_eq(GameSession.touch_controls, TouchControls.Visibility.ALWAYS, "Affichage tactile conservé")
	assert_eq(InputActions.get_keys(InputActions.PUNCH), [KEY_U] as Array[int], "Touche personnalisée conservée")
	var bus: int = AudioServer.get_bus_index(GameConstants.BUS_MUSIC)
	assert_true(absf(AudioServer.get_bus_volume_db(bus) - linear_to_db(0.3)) < 0.01, "Volume appliqué au bus Music")


func test_old_save_is_completed_and_unknown_keys_kept() -> void:
	_write_raw(JSON.stringify({"settings": {"difficulty": 2}, "futur": {"x": 1}}))
	assert_true(SaveManager.load_save(), "Ancienne sauvegarde (sans version) lisible")
	var data: Dictionary = SaveManager.data
	assert_eq(int(data["version"]), SaveManager.SAVE_VERSION, "Migrée à la version courante")
	assert_eq(int(data["settings"]["difficulty"]), 2, "Valeur existante conservée")
	assert_true((data["settings"] as Dictionary).has("volumes"), "Clés manquantes complétées")
	assert_eq(int(data["stats"]["matches_played"]), 0, "Statistiques créées")
	assert_true(data.has("futur"), "Clé inconnue (version future) conservée")


func test_wrong_types_are_replaced_by_defaults() -> void:
	_write_raw(JSON.stringify({"version": 1, "settings": {"difficulty": "dur", "volumes": "fort"}}))
	SaveManager.load_save()
	assert_eq(SaveManager.data["settings"]["difficulty"], AIProfile.Difficulty.NORMAL, "Type invalide remplacé")
	assert_true(SaveManager.data["settings"]["volumes"] is Dictionary, "Volumes restaurés")


func test_corrupt_save_is_set_aside() -> void:
	_write_raw("{ ceci n'est pas du JSON")
	print("          (l'avertissement « Sauvegarde illisible, mise de côté » qui suit est attendu)")
	assert_false(SaveManager.load_save(), "Fichier illisible signalé")
	assert_true(FileAccess.file_exists(_test_path + SaveManager.CORRUPT_SUFFIX), "Fichier corrompu mis de côté")
	assert_eq(int(SaveManager.data["stats"]["matches_played"]), 0, "Repart des valeurs par défaut")
	DirAccess.remove_absolute(_test_path + SaveManager.CORRUPT_SUFFIX)


func test_match_results_update_stats_and_progress() -> void:
	var win := MatchResult.new()
	win.winner_side = GameConstants.SIDE_P1
	win.fighter_ids = [FighterRegistry.K_BLAZE, FighterRegistry.AMAZONE] as Array[StringName]
	win.rounds_won = [2, 1] as Array[int]
	SaveManager.record_match(win, AIProfile.Difficulty.HARD, 5)
	var loss := MatchResult.new()
	loss.winner_side = GameConstants.SIDE_P2
	loss.fighter_ids = win.fighter_ids
	loss.rounds_won = [0, 2] as Array[int]
	SaveManager.record_match(loss, AIProfile.Difficulty.NORMAL, 3)
	var stats: Dictionary = SaveManager.get_stats()
	assert_eq([int(stats["matches_played"]), int(stats["matches_won"]), int(stats["matches_lost"])], [2, 1, 1], "Combats / victoires / défaites")
	assert_eq([int(stats["rounds_won"]), int(stats["rounds_lost"])], [2, 3], "Manches")
	assert_eq(int(stats["best_combo"]), 5, "Meilleur combo")
	assert_eq(SaveManager.get_wins_by_difficulty(AIProfile.Difficulty.HARD), 1, "Victoire en DIFFICILE")
	var blaze: Dictionary = (stats["fighters"] as Dictionary)["k_blaze"]
	assert_eq([int(blaze["played"]), int(blaze["won"])], [2, 1], "Statistiques par combattant")
	assert_true(SaveManager.is_fighter_unlocked(FighterRegistry.AMAZONE), "Combattants de base débloqués")


func test_remap_moves_key_without_duplicates() -> void:
	SaveManager.set_binding_key(InputActions.PUNCH, KEY_K)
	var press := InputEventKey.new()
	press.physical_keycode = KEY_K
	press.pressed = true
	assert_true(InputMap.event_is_action(press, InputActions.PUNCH), "K déclenche désormais Poing")
	assert_false(InputMap.event_is_action(press, InputActions.KICK), "K ne déclenche plus Pied (pas de doublon)")
	SaveManager.set_binding_button(InputActions.KICK, JOY_BUTTON_X)
	assert_eq(InputActions.get_buttons(InputActions.KICK), [JOY_BUTTON_X] as Array[int], "X manette sur Pied")
	assert_false(JOY_BUTTON_X in InputActions.get_buttons(InputActions.PUNCH), "X retiré de Poing")
	SaveManager.reset_bindings()
	assert_eq(InputActions.get_keys(InputActions.KICK), [KEY_K] as Array[int], "Réinitialisation : K revient à Pied")


func test_remap_panel_captures_next_key() -> void:
	var panel: OptionsPanel = (load(OPTIONS_PANEL) as PackedScene).instantiate() as OptionsPanel
	_node = panel
	tree.root.add_child(panel)
	panel.open()
	var remap_panel: ControlsRemapPanel = panel.get_node("%ControlsTab") as ControlsRemapPanel
	(panel.get_node("%Tabs") as TabContainer).current_tab = 2
	remap_panel.start_capture(InputActions.GUARD, ControlsRemapPanel.CaptureKind.KEYBOARD)
	assert_true(remap_panel.is_capturing(), "En attente d'une touche")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_G
	key.pressed = true
	tree.root.push_input(key, true)
	assert_false(remap_panel.is_capturing(), "Capture terminée")
	assert_eq(InputActions.get_keys(InputActions.GUARD), [KEY_G] as Array[int], "Garde sur G")
	assert_eq(remap_panel.get_key_button(InputActions.GUARD).text, "G", "Libellé mis à jour")
	assert_eq(InputActions.key_label(KEY_LEFT), "←", "Touches spéciales nommées en français")
	assert_eq(InputActions.key_label(KEY_ESCAPE), "Échap", "Échap")
	remap_panel.start_capture(InputActions.GUARD, ControlsRemapPanel.CaptureKind.KEYBOARD)
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	tree.root.push_input(escape, true)
	assert_false(remap_panel.is_capturing(), "Échap annule")
	assert_eq(InputActions.get_keys(InputActions.GUARD), [KEY_G] as Array[int], "Annuler ne change rien")


func test_options_panel_changes_settings() -> void:
	var panel: OptionsPanel = (load(OPTIONS_PANEL) as PackedScene).instantiate() as OptionsPanel
	_node = panel
	tree.root.add_child(panel)
	panel.open()
	var before: AIProfile.Difficulty = GameSession.difficulty
	panel.get_difficulty_button().pressed.emit()
	assert_true(GameSession.difficulty != before, "Le bouton change la difficulté")
	assert_eq(int(SaveManager.data["settings"]["difficulty"]), GameSession.difficulty, "Et la sauvegarde")
	panel.get_slider(GameConstants.BUS_SFX).value = 40.0
	assert_true(is_equal_approx(SaveManager.get_volume(GameConstants.BUS_SFX), 0.4), "Le curseur règle le volume des effets")
	assert_true(panel.get_stats_text().contains("Combats"), "L'onglet statistiques est rempli")
	var closed: Array[bool] = []
	panel.closed.connect(func() -> void: closed.append(true))
	panel.close()
	assert_eq(closed.size(), 1, "Retour émet closed")


func test_pause_freezes_and_resumes_the_fight() -> void:
	var scene: Node = (load(FIGHT_SCENE) as PackedScene).instantiate()
	_node = scene
	tree.root.add_child(scene)
	var pause: PauseMenu = scene.call("get_pause_menu") as PauseMenu
	# Se caler en début de frame (comme une vraie entrée, traitée avant les _process) : un
	# test précédent peut nous rendre la main après les _process (fin d'un Tween).
	await wait_frames(1)
	Input.action_press(InputActions.PAUSE)
	await wait_frames(1)
	Input.action_release(InputActions.PAUSE)
	assert_true(pause.is_open() and tree.paused, "L'action pause ouvre le menu et fige le combat")
	var manager: FightManager = scene.call("get_manager") as FightManager
	var frozen_phase_frames: int = manager.round_number
	await wait_frames(3)
	assert_eq(manager.round_number, frozen_phase_frames, "Rien n'avance pendant la pause")
	pause.resume()
	assert_false(pause.is_open() or tree.paused, "Reprendre relance le combat")
	pause.enabled = false
	pause.open()
	pause.resume()
	Input.action_press(InputActions.PAUSE)
	await wait_frames(1)
	Input.action_release(InputActions.PAUSE)
	assert_false(pause.is_open(), "Pause impossible quand elle est désactivée (fin de match)")


func test_main_menu_offers_options() -> void:
	var menu: Node = (load(GameConstants.SCENE_MAIN_MENU) as PackedScene).instantiate()
	_node = menu
	tree.root.add_child(menu)
	assert_not_null(menu.get_node_or_null("%OptionsButton"), "Bouton OPTIONS au menu principal")
	assert_true(ResourceLoader.exists(GameConstants.SCENE_OPTIONS), "Écran d'options présent")
