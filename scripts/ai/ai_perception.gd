class_name AIPerception
extends RefCounted
## Mémoire des dernières observations de l'IA. delayed(N) renvoie ce que l'adversaire
## faisait il y a N frames : c'est le temps de réaction de l'IA.
## Tampon circulaire d'instances réutilisées (aucune allocation pendant le combat).

const CAPACITY: int = 64

var _snapshots: Array[AISnapshot] = []
var _head: int = -1
var _count: int = 0
var _frame_index: int = 0


func _init() -> void:
	for i: int in CAPACITY:
		_snapshots.append(AISnapshot.new())


func clear() -> void:
	_head = -1
	_count = 0
	_frame_index = 0
	for snapshot: AISnapshot in _snapshots:
		snapshot.valid = false


func record(self_fighter: Fighter, opponent: Fighter) -> void:
	_frame_index += 1
	_head = (_head + 1) % CAPACITY
	_count = mini(_count + 1, CAPACITY)
	_snapshots[_head].capture(self_fighter, opponent, _frame_index)


## Observation d'il y a « frames » frames (la plus ancienne disponible au début du combat).
## Retourne une observation invalide si rien n'a encore été enregistré.
func delayed(frames: int) -> AISnapshot:
	if _count == 0:
		return _snapshots[0]
	var age: int = clampi(frames, 0, _count - 1)
	return _snapshots[(_head - age + CAPACITY) % CAPACITY]


func get_frame_index() -> int:
	return _frame_index
