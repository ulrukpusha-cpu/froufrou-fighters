class_name InputBuffer
extends RefCounted
## Mémoire des appuis récents d'un combattant.
##
## Un bouton pressé jusqu'à « size » frames trop tôt reste utilisable (tolérance), et deux
## boutons pressés presque ensemble sont reconnus (projection). Un appui utilisé est
## « consommé » pour ne pas déclencher deux actions. Tampon circulaire, sans allocation.

var _size: int = 1
var _pressed: PackedInt32Array = PackedInt32Array()
var _consumed: PackedInt32Array = PackedInt32Array()
var _head: int = 0


func _init(size: int = GameConstants.INPUT_BUFFER_FRAMES) -> void:
	_size = maxi(size, 1)
	_pressed.resize(_size)
	_consumed.resize(_size)
	clear()


func clear() -> void:
	_pressed.fill(0)
	_consumed.fill(0)
	_head = 0


## Enregistre les appuis d'une nouvelle frame (la plus ancienne est oubliée).
func push(pressed_buttons: int) -> void:
	_head = (_head + 1) % _size
	_pressed[_head] = pressed_buttons
	_consumed[_head] = 0


## Ajoute des appuis à la frame courante sans faire vieillir le tampon (pendant le gel
## d'impact, les commandes du joueur sont conservées pour l'enchaînement suivant).
func merge(pressed_buttons: int) -> void:
	_pressed[_head] |= pressed_buttons


## Vrai si l'un des boutons a été pressé (et non consommé) dans les « window » dernières frames.
func has(buttons: int, window: int = -1) -> bool:
	for age: int in _clamp_window(window):
		var index: int = _index(age)
		if (_pressed[index] & ~_consumed[index] & buttons) != 0:
			return true
	return false


## Vrai si CHAQUE bouton du masque a été pressé dans la fenêtre (consommé ou non) et
## qu'au moins l'un d'eux est encore disponible.
func has_all(buttons: int, window: int) -> bool:
	var seen: int = 0
	var fresh: int = 0
	for age: int in _clamp_window(window):
		var index: int = _index(age)
		seen |= _pressed[index] & buttons
		fresh |= _pressed[index] & ~_consumed[index] & buttons
	return seen == buttons and fresh != 0


## Marque les boutons comme utilisés dans toute la mémoire.
func consume(buttons: int) -> void:
	for index: int in _size:
		_consumed[index] |= _pressed[index] & buttons


func _clamp_window(window: int) -> int:
	return _size if window <= 0 else mini(window, _size)


func _index(age: int) -> int:
	return (_head - age + _size) % _size
