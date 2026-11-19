class_name PlayerController
extends FighterController
## Contrôleur du joueur : lit les actions logiques de InputActions.
## Clavier, manette Bluetooth et boutons tactiles (Input.action_press) passent tous par là.
## En mode ASSISTÉ, AssistedInput simplifie les combos et les techniques spéciales.

enum Mode { CLASSIC, ASSISTED }

## Libellés affichés dans les menus.
const MODE_LABELS: Dictionary = { Mode.CLASSIC: "CLASSIQUE", Mode.ASSISTED: "ASSISTÉ" }

const BUTTON_ACTIONS: Dictionary = {
	InputFrame.PUNCH: InputActions.PUNCH,
	InputFrame.KICK: InputActions.KICK,
	InputFrame.SPECIAL: InputActions.SPECIAL,
	InputFrame.GUARD: InputActions.GUARD,
	InputFrame.DODGE: InputActions.DODGE,
}

var mode: Mode = Mode.CLASSIC
var _previous_held: int = 0
var _assist: AssistedInput = AssistedInput.new()


func _init(control_mode: Mode = Mode.CLASSIC) -> void:
	mode = control_mode


func poll(fighter: Fighter, _opponent: Fighter, out_frame: InputFrame) -> void:
	var held: int = 0
	for button: int in BUTTON_ACTIONS:
		if Input.is_action_pressed(BUTTON_ACTIONS[button]):
			held |= button
	var direction := Vector2i(
		_axis(InputActions.MOVE_LEFT, InputActions.MOVE_RIGHT),
		_axis(InputActions.MOVE_UP, InputActions.MOVE_DOWN)
	)
	out_frame.set_from(direction, held, _previous_held)
	_previous_held = held
	if mode == Mode.ASSISTED:
		_assist.apply(out_frame, fighter)


func reset() -> void:
	_previous_held = 0
	_assist.reset()


static func _axis(negative_action: StringName, positive_action: StringName) -> int:
	var value: int = 0
	if Input.is_action_pressed(negative_action):
		value -= 1
	if Input.is_action_pressed(positive_action):
		value += 1
	return value
