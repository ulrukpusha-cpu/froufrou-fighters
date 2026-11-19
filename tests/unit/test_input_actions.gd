extends TestCase
## Phase 1 : une seule couche d'actions logiques, liée au clavier ET à la manette.


func after_each() -> void:
	# Certains tests modifient l'InputMap en mémoire : on revient aux valeurs par défaut.
	InputActions.restore_defaults()


func test_every_action_exists_in_input_map() -> void:
	for action: StringName in InputActions.ALL_ACTIONS:
		assert_true(InputMap.has_action(action), "Action manquante : %s" % action)


func test_every_action_has_keyboard_and_gamepad() -> void:
	for action: StringName in InputActions.ALL_ACTIONS:
		var has_key: bool = false
		var has_pad: bool = false
		for event: InputEvent in InputMap.action_get_events(action):
			has_key = has_key or event is InputEventKey
			has_pad = has_pad or event is InputEventJoypadButton or event is InputEventJoypadMotion
		assert_true(has_key, "%s : aucune touche clavier" % action)
		assert_true(has_pad, "%s : aucun bouton de manette" % action)


func test_keys_use_physical_codes_for_azerty() -> void:
	for event: InputEvent in InputMap.action_get_events(InputActions.MOVE_UP):
		var key_event: InputEventKey = event as InputEventKey
		if key_event != null:
			assert_eq(key_event.keycode, KEY_NONE, "move_up doit utiliser un code physique")
			assert_true(key_event.physical_keycode != KEY_NONE, "move_up sans code physique")


func test_project_map_matches_code_defaults() -> void:
	for action: StringName in InputActions.ALL_ACTIONS:
		var expected: Array[InputEvent] = InputActions.build_default_events(action)
		var actual: Array[InputEvent] = InputMap.action_get_events(action)
		assert_eq(actual.size(), expected.size(), "Nombre de liaisons pour %s" % action)
		for event: InputEvent in expected:
			assert_true(InputMap.action_has_event(action, event), "%s : liaison absente %s" % [action, event.as_text()])


func test_physical_key_triggers_action() -> void:
	var press := InputEventKey.new()
	press.physical_keycode = KEY_J
	press.pressed = true
	assert_true(InputMap.event_is_action(press, InputActions.PUNCH), "J physique doit déclencher punch")


func test_gamepad_button_triggers_action() -> void:
	var press := InputEventJoypadButton.new()
	press.device = 0
	press.button_index = JOY_BUTTON_X
	press.pressed = true
	assert_true(InputMap.event_is_action(press, InputActions.PUNCH), "X manette doit déclencher punch")


func test_restore_defaults_after_remap() -> void:
	InputMap.action_erase_events(InputActions.KICK)
	assert_true(InputMap.action_get_events(InputActions.KICK).is_empty(), "Liaisons effacées")
	InputActions.restore_defaults()
	assert_eq(
		InputMap.action_get_events(InputActions.KICK).size(),
		InputActions.build_default_events(InputActions.KICK).size(),
		"Liaisons restaurées"
	)


func test_direction_deadzone_is_higher() -> void:
	assert_true(
		InputMap.action_get_deadzone(InputActions.MOVE_LEFT) > InputMap.action_get_deadzone(InputActions.PUNCH),
		"Les directions doivent avoir une zone morte plus large"
	)
