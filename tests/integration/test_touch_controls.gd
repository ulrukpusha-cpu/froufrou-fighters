extends TestCase
## Phase 9 : joystick virtuel, boutons tactiles, multi-touch, zones, visibilité, et
## équivalence avec les autres périphériques (mêmes actions logiques).

const TOUCH_SCENE: String = "res://scenes/combat/touch_controls.tscn"

var controls: TouchControls = null


func before_each() -> void:
	GameSession.touch_controls = TouchControls.Visibility.ALWAYS
	controls = (load(TOUCH_SCENE) as PackedScene).instantiate() as TouchControls
	tree.root.add_child(controls)
	# Les conteneurs calculent leur mise en page en différé : une frame avant de toucher.
	await wait_frames(1)


func after_each() -> void:
	if is_instance_valid(controls):
		controls.free()
	for action: StringName in InputActions.ALL_ACTIONS:
		Input.action_release(action)
	GameSession.touch_controls = TouchControls.Visibility.AUTO
	GameSession.control_mode = PlayerController.Mode.CLASSIC


## Envoie un toucher par le vrai pipeline d'entrée (coordonnées d'interface).
func _touch(index: int, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	tree.root.push_input(event, true)


func _drag(index: int, position: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	tree.root.push_input(event, true)


func _pressed(action: StringName) -> bool:
	return Input.is_action_pressed(action)


func test_visibility_modes() -> void:
	assert_true(TouchControls.should_show(TouchControls.Visibility.ALWAYS), "ALWAYS : affichées")
	assert_false(TouchControls.should_show(TouchControls.Visibility.NEVER), "NEVER : masquées")
	assert_false(TouchControls.should_show(TouchControls.Visibility.AUTO), "AUTO sur ordinateur sans --touch : masquées")
	assert_true(controls.is_shown(), "Forcées pour ce test")


func test_joystick_threshold_mapping() -> void:
	var stick: TouchJoystick = controls.get_joystick()
	assert_eq(stick.compute_direction(Vector2(0.2, 0.0)), Vector2i.ZERO, "Petit mouvement : zone morte")
	assert_eq(stick.compute_direction(Vector2(0.8, 0.0)), Vector2i.RIGHT, "Droite")
	assert_eq(stick.compute_direction(Vector2(-0.6, 0.6)), Vector2i(-1, 1), "Diagonale bas-gauche")
	assert_eq(stick.compute_direction(Vector2(0.0, -0.5)), Vector2i.ZERO, "Haut timide : pas de saut involontaire")
	assert_eq(stick.compute_direction(Vector2(0.0, -0.8)), Vector2i.UP, "Haut franc : saut")


func test_joystick_drag_presses_direction_actions() -> void:
	var stick: TouchJoystick = controls.get_joystick()
	var start: Vector2 = stick.get_global_rect().get_center()
	_touch(0, start, true)
	assert_true(stick.is_active(), "Le pouce est pris par le joystick")
	_drag(0, start + Vector2(100.0, 0.0))
	assert_true(_pressed(InputActions.MOVE_RIGHT), "Glisser à droite presse move_right")
	assert_false(_pressed(InputActions.MOVE_LEFT), "move_left reste relâché")
	_drag(0, start + Vector2(0.0, -110.0))
	assert_true(_pressed(InputActions.MOVE_UP), "Glisser franchement vers le haut presse move_up")
	assert_false(_pressed(InputActions.MOVE_RIGHT), "move_right est relâché en revenant au centre horizontal")
	_touch(0, start + Vector2(0.0, -110.0), false)
	assert_false(stick.is_active(), "Pouce levé")
	for action: StringName in InputActions.DIRECTION_ACTIONS:
		assert_false(_pressed(action), "%s relâché au lever du pouce" % action)


func test_button_press_release_and_misses() -> void:
	var punch: TouchActionButton = controls.get_button(InputActions.PUNCH)
	_touch(0, Vector2(-500.0, -500.0), true)
	assert_false(_pressed(InputActions.PUNCH), "Un toucher hors de tout bouton ne presse rien")
	_touch(0, Vector2(-500.0, -500.0), false)
	_touch(1, punch.get_global_center(), true)
	assert_true(_pressed(InputActions.PUNCH) and punch.is_down(), "Toucher Poing presse l'action punch")
	_touch(1, punch.get_global_center(), false)
	assert_false(_pressed(InputActions.PUNCH), "Lever le doigt relâche punch")


func test_multitouch_move_and_throw() -> void:
	var stick: TouchJoystick = controls.get_joystick()
	var punch: TouchActionButton = controls.get_button(InputActions.PUNCH)
	var kick: TouchActionButton = controls.get_button(InputActions.KICK)
	var start: Vector2 = stick.get_global_rect().get_center()
	_touch(0, start, true)
	_drag(0, start + Vector2(100.0, 0.0))
	_touch(1, punch.get_global_center(), true)
	_touch(2, kick.get_global_center(), true)
	assert_true(_pressed(InputActions.MOVE_RIGHT), "Doigt 1 : avance")
	assert_true(_pressed(InputActions.PUNCH) and _pressed(InputActions.KICK), "Doigts 2 et 3 : Poing + Pied")
	# Le joueur voit exactement ce qu'un clavier ou une manette produirait.
	var player := PlayerController.new()
	var frame := InputFrame.new()
	player.poll(null, null, frame)
	assert_eq(frame.direction, Vector2i.RIGHT, "PlayerController lit la direction tactile")
	assert_true(frame.is_pressed(InputFrame.THROW_BUTTONS), "Poing + Pied tactiles = projection")
	player.free()
	_touch(1, punch.get_global_center(), false)
	assert_false(_pressed(InputActions.PUNCH), "Lever un doigt ne relâche que son bouton")
	assert_true(_pressed(InputActions.KICK) and _pressed(InputActions.MOVE_RIGHT), "Les autres doigts restent actifs")


func test_release_all_and_exit_tree_release_actions() -> void:
	var guard: TouchActionButton = controls.get_button(InputActions.GUARD)
	var stick: TouchJoystick = controls.get_joystick()
	var start: Vector2 = stick.get_global_rect().get_center()
	_touch(0, start, true)
	_drag(0, start + Vector2(-100.0, 0.0))
	_touch(1, guard.get_global_center(), true)
	controls.release_all()
	assert_false(_pressed(InputActions.GUARD) or _pressed(InputActions.MOVE_LEFT), "release_all relâche tout")
	_touch(2, guard.get_global_center(), true)
	assert_true(_pressed(InputActions.GUARD), "Garde de nouveau tenue")
	controls.free()
	assert_false(_pressed(InputActions.GUARD), "Quitter l'écran relâche les commandes encore tenues")


func test_hidden_controls_ignore_touches() -> void:
	controls.apply_visibility(TouchControls.Visibility.NEVER)
	var punch: TouchActionButton = controls.get_button(InputActions.PUNCH)
	_touch(0, punch.get_global_center(), true)
	assert_false(_pressed(InputActions.PUNCH), "Masquées, les commandes ne réagissent pas")


func test_buttons_cover_all_combat_actions() -> void:
	for action: StringName in [InputActions.PUNCH, InputActions.KICK, InputActions.SPECIAL, InputActions.GUARD, InputActions.DODGE]:
		assert_not_null(controls.get_button(action), "Bouton tactile pour %s" % action)


func test_assist_badge_follows_mode() -> void:
	controls.set_control_mode(PlayerController.Mode.ASSISTED)
	assert_true((controls.get_node("%AssistBadge") as Label).visible, "Badge visible en mode assisté")
	controls.set_control_mode(PlayerController.Mode.CLASSIC)
	assert_false((controls.get_node("%AssistBadge") as Label).visible, "Badge masqué en mode classique")
