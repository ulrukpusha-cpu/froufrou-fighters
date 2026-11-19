class_name InputActions
extends RefCounted
## Actions logiques du jeu et leurs liaisons par défaut.
##
## Le clavier, les manettes (USB / Bluetooth) et les commandes tactiles déclenchent
## TOUS exactement ces actions : le moteur de combat ne lit jamais un périphérique
## directement. Les liaisons par défaut sont écrites dans project.godot par
## tools/configure_project.gd ; restore_defaults() permet de revenir à ces valeurs après
## une personnalisation des commandes.

const MOVE_LEFT: StringName = &"move_left"
const MOVE_RIGHT: StringName = &"move_right"
## Haut = saut.
const MOVE_UP: StringName = &"move_up"
## Bas = accroupi.
const MOVE_DOWN: StringName = &"move_down"
## Poing = attaque légère.
const PUNCH: StringName = &"punch"
## Pied = attaque lourde.
const KICK: StringName = &"kick"
const SPECIAL: StringName = &"special"
const GUARD: StringName = &"guard"
const DODGE: StringName = &"dodge"
const PAUSE: StringName = &"pause"

## Actions de combat, dans l'ordre d'affichage des menus de commandes.
const GAMEPLAY_ACTIONS: Array[StringName] = [
	MOVE_LEFT, MOVE_RIGHT, MOVE_UP, MOVE_DOWN, PUNCH, KICK, SPECIAL, GUARD, DODGE,
]
## Toutes les actions déclarées dans l'InputMap par le jeu.
const ALL_ACTIONS: Array[StringName] = [
	MOVE_LEFT, MOVE_RIGHT, MOVE_UP, MOVE_DOWN, PUNCH, KICK, SPECIAL, GUARD, DODGE, PAUSE,
]
const DIRECTION_ACTIONS: Array[StringName] = [MOVE_LEFT, MOVE_RIGHT, MOVE_UP, MOVE_DOWN]

## Libellés affichés dans l'écran de personnalisation des commandes.
const ACTION_LABELS: Dictionary = {
	MOVE_LEFT: "Gauche", MOVE_RIGHT: "Droite", MOVE_UP: "Saut", MOVE_DOWN: "Accroupi",
	PUNCH: "Poing", KICK: "Pied", SPECIAL: "Spécial", GUARD: "Garde", DODGE: "Esquive",
	PAUSE: "Pause",
}

## Noms des boutons de manette (disposition Xbox).
const JOY_BUTTON_LABELS: Dictionary = {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_BACK: "Back", JOY_BUTTON_START: "Start",
	JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_DPAD_UP: "Croix ↑", JOY_BUTTON_DPAD_DOWN: "Croix ↓",
	JOY_BUTTON_DPAD_LEFT: "Croix ←", JOY_BUTTON_DPAD_RIGHT: "Croix →",
}

## Noms français des touches spéciales (les lettres gardent leur nom).
const KEY_LABELS: Dictionary = {
	KEY_LEFT: "←", KEY_RIGHT: "→", KEY_UP: "↑", KEY_DOWN: "↓",
	KEY_ESCAPE: "Échap", KEY_SPACE: "Espace", KEY_ENTER: "Entrée", KEY_TAB: "Tab",
	KEY_SHIFT: "Maj", KEY_CTRL: "Ctrl", KEY_ALT: "Alt", KEY_BACKSPACE: "Retour arrière",
}

## Zone morte des directions au stick : élevée pour éviter les diagonales involontaires.
const DIRECTION_DEADZONE: float = 0.5
const BUTTON_DEADZONE: float = 0.2

## Touches clavier par défaut, en codes PHYSIQUES : la position est la même en
## AZERTY et en QWERTY (WASD en QWERTY = ZQSD en AZERTY).
const DEFAULT_KEYS: Dictionary = {
	MOVE_LEFT: [KEY_A, KEY_LEFT],
	MOVE_RIGHT: [KEY_D, KEY_RIGHT],
	MOVE_UP: [KEY_W, KEY_UP],
	MOVE_DOWN: [KEY_S, KEY_DOWN],
	PUNCH: [KEY_J],
	KICK: [KEY_K],
	SPECIAL: [KEY_L],
	GUARD: [KEY_I],
	DODGE: [KEY_O],
	PAUSE: [KEY_ESCAPE, KEY_P],
}

## Boutons de manette par défaut (disposition Xbox ; équivalents PlayStation / Switch
## gérés par le SDL de Godot).
const DEFAULT_JOY_BUTTONS: Dictionary = {
	MOVE_LEFT: [JOY_BUTTON_DPAD_LEFT],
	MOVE_RIGHT: [JOY_BUTTON_DPAD_RIGHT],
	MOVE_UP: [JOY_BUTTON_DPAD_UP],
	MOVE_DOWN: [JOY_BUTTON_DPAD_DOWN],
	PUNCH: [JOY_BUTTON_X],
	KICK: [JOY_BUTTON_A],
	SPECIAL: [JOY_BUTTON_B],
	GUARD: [JOY_BUTTON_RIGHT_SHOULDER],
	DODGE: [JOY_BUTTON_Y, JOY_BUTTON_LEFT_SHOULDER],
	PAUSE: [JOY_BUTTON_START],
}

## Axes analogiques par défaut : liste de paires [axe, sens (-1.0 ou 1.0)].
const DEFAULT_JOY_AXES: Dictionary = {
	MOVE_LEFT: [[JOY_AXIS_LEFT_X, -1.0]],
	MOVE_RIGHT: [[JOY_AXIS_LEFT_X, 1.0]],
	MOVE_UP: [[JOY_AXIS_LEFT_Y, -1.0]],
	MOVE_DOWN: [[JOY_AXIS_LEFT_Y, 1.0]],
}


## Zone morte à utiliser pour une action.
static func get_deadzone(action: StringName) -> float:
	return DIRECTION_DEADZONE if action in DIRECTION_ACTIONS else BUTTON_DEADZONE


const HEADLESS_DISPLAY_SERVER: String = "headless"

## Valeur de device signifiant « tous les périphériques » (InputMap.ALL_DEVICES côté moteur).
const ANY_DEVICE: int = -1


## Construit les événements par défaut (clavier + manette) d'une action.
## Tous répondent à n'importe quel périphérique (ANY_DEVICE) : le joueur 1 peut passer
## du clavier à une manette Bluetooth sans reconfiguration.
static func build_default_events(action: StringName) -> Array[InputEvent]:
	var events: Array[InputEvent] = []
	for keycode: int in DEFAULT_KEYS.get(action, []):
		var key_event := InputEventKey.new()
		key_event.device = ANY_DEVICE
		key_event.physical_keycode = keycode as Key
		events.append(key_event)
	for button: int in DEFAULT_JOY_BUTTONS.get(action, []):
		var button_event := InputEventJoypadButton.new()
		button_event.device = ANY_DEVICE
		button_event.button_index = button as JoyButton
		events.append(button_event)
	for axis_pair: Array in DEFAULT_JOY_AXES.get(action, []):
		var motion_event := InputEventJoypadMotion.new()
		motion_event.device = ANY_DEVICE
		motion_event.axis = int(axis_pair[0]) as JoyAxis
		motion_event.axis_value = float(axis_pair[1])
		events.append(motion_event)
	return events


## Valeur à écrire dans project.godot (clé « input/<action> »).
static func build_project_setting(action: StringName) -> Dictionary:
	return {
		"deadzone": get_deadzone(action),
		"events": build_default_events(action),
	}


## Remplace les touches clavier (codes physiques) et boutons de manette d'une action.
## Les axes analogiques par défaut sont conservés (non personnalisables).
static func apply_bindings(action: StringName, keys: Array[int], buttons: Array[int]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, get_deadzone(action))
	InputMap.action_erase_events(action)
	for keycode: int in keys:
		var key_event := InputEventKey.new()
		key_event.device = ANY_DEVICE
		key_event.physical_keycode = keycode as Key
		InputMap.action_add_event(action, key_event)
	for button: int in buttons:
		var button_event := InputEventJoypadButton.new()
		button_event.device = ANY_DEVICE
		button_event.button_index = button as JoyButton
		InputMap.action_add_event(action, button_event)
	for event: InputEvent in build_default_events(action):
		if event is InputEventJoypadMotion:
			InputMap.action_add_event(action, event)


## Touches clavier (codes physiques) actuellement liées à une action.
static func get_keys(action: StringName) -> Array[int]:
	var keys: Array[int] = []
	if InputMap.has_action(action):
		for event: InputEvent in InputMap.action_get_events(action):
			var key_event: InputEventKey = event as InputEventKey
			if key_event != null:
				keys.append(int(key_event.physical_keycode))
	return keys


## Boutons de manette actuellement liés à une action.
static func get_buttons(action: StringName) -> Array[int]:
	var buttons: Array[int] = []
	if InputMap.has_action(action):
		for event: InputEvent in InputMap.action_get_events(action):
			var button_event: InputEventJoypadButton = event as InputEventJoypadButton
			if button_event != null:
				buttons.append(int(button_event.button_index))
	return buttons


## Nom d'une touche physique selon la disposition du clavier du joueur (AZERTY, QWERTY…).
## Sans disposition clavier connue (serveur d'affichage headless), le nom QWERTY est utilisé.
static func key_label(physical_keycode: int) -> String:
	var keycode: Key = physical_keycode as Key
	if DisplayServer.get_name() != HEADLESS_DISPLAY_SERVER:
		var translated: Key = DisplayServer.keyboard_get_keycode_from_physical(physical_keycode as Key)
		if translated != KEY_NONE:
			keycode = translated
	return KEY_LABELS.get(keycode, OS.get_keycode_string(keycode))


static func button_label(button: int) -> String:
	return JOY_BUTTON_LABELS.get(button, "Bouton %d" % button)


## Réinitialise l'InputMap en mémoire avec les liaisons par défaut
## (utilisé par l'écran de personnalisation des commandes).
static func restore_defaults() -> void:
	for action: StringName in ALL_ACTIONS:
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
		else:
			InputMap.add_action(action)
		InputMap.action_set_deadzone(action, get_deadzone(action))
		for event: InputEvent in build_default_events(action):
			InputMap.action_add_event(action, event)
