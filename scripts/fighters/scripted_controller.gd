class_name ScriptedController
extends FighterController
## Rejoue une suite de commandes prédéfinie (tests automatisés, démonstrations).
## Exemple : add_step(10, Vector2i.RIGHT).add_step(1, Vector2i.ZERO, InputFrame.PUNCH)
## Un bouton maintenu sur deux étapes consécutives ne compte qu'un seul appui.

## Applique le mode assisté aux commandes rejouées (comme le joueur en mode ASSISTÉ).
var assisted: bool = false

var _assist: AssistedInput = AssistedInput.new()
var _steps: Array[Dictionary] = []
var _step_index: int = 0
var _frames_left: int = 0
var _previous_held: int = 0


## Ajoute une étape de « frames » frames. Retourne le contrôleur pour chaîner les appels.
func add_step(frames: int, direction: Vector2i = Vector2i.ZERO, held: int = 0) -> ScriptedController:
	_steps.append({"frames": maxi(frames, 1), "direction": direction, "held": held})
	if _steps.size() == 1:
		_frames_left = maxi(frames, 1)
	return self


func clear_steps() -> void:
	_steps.clear()
	reset()


func is_finished() -> bool:
	return _step_index >= _steps.size()


func poll(fighter: Fighter, _opponent: Fighter, out_frame: InputFrame) -> void:
	if is_finished():
		out_frame.set_from(Vector2i.ZERO, 0, _previous_held)
		_previous_held = 0
	else:
		var step: Dictionary = _steps[_step_index]
		var held: int = step["held"]
		out_frame.set_from(step["direction"], held, _previous_held)
		_previous_held = held
		_frames_left -= 1
		if _frames_left <= 0:
			_step_index += 1
			if not is_finished():
				_frames_left = _steps[_step_index]["frames"]
	if assisted:
		_assist.apply(out_frame, fighter)


func reset() -> void:
	_step_index = 0
	_previous_held = 0
	_assist.reset()
	_frames_left = _steps[0]["frames"] if not _steps.is_empty() else 0
