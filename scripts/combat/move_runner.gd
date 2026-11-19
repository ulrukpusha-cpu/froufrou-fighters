class_name MoveRunner
extends RefCounted
## Exécute la chronologie d'une attaque frame par frame (voir MoveData pour la convention).
##
## Tient aussi le registre des impacts : une attaque ne touche une même cible que
## move.max_hits fois, espacées d'au moins move.rehit_interval_frames. C'est ce qui évite
## les dégâts multiples involontaires quand une hitbox reste plusieurs frames sur l'adversaire.

var move: MoveData = null
## Frame courante de l'attaque (1 = première frame).
var frame: int = 0
var has_connected: bool = false
var was_blocked: bool = false

var _hit_counts: Dictionary = {}
var _last_hit_frames: Dictionary = {}


func start(new_move: MoveData) -> void:
	move = new_move
	frame = 1
	has_connected = false
	was_blocked = false
	_hit_counts.clear()
	_last_hit_frames.clear()


func stop() -> void:
	move = null
	frame = 0


func advance() -> void:
	if move != null:
		frame += 1


func is_running() -> bool:
	return move != null


func get_phase() -> MoveData.Phase:
	return MoveData.Phase.FINISHED if move == null else move.get_phase(frame)


func is_active() -> bool:
	return get_phase() == MoveData.Phase.ACTIVE


func is_finished() -> bool:
	return get_phase() == MoveData.Phase.FINISHED


## Index dans la fenêtre active (0 = première frame active).
func get_active_index() -> int:
	return frame - move.get_first_active_frame() if move != null else -1


func can_hit(target_id: int) -> bool:
	if not is_active():
		return false
	var count: int = _hit_counts.get(target_id, 0)
	if count >= move.max_hits:
		return false
	if count > 0 and frame - int(_last_hit_frames[target_id]) < move.rehit_interval_frames:
		return false
	return true


## Nombre d'impacts déjà portés sur une cible par l'attaque en cours.
func get_hit_count(target_id: int) -> int:
	return _hit_counts.get(target_id, 0)


func register_hit(target_id: int, blocked: bool) -> void:
	_hit_counts[target_id] = int(_hit_counts.get(target_id, 0)) + 1
	_last_hit_frames[target_id] = frame
	has_connected = true
	was_blocked = blocked


## Vrai si les conditions d'annulation de l'attaque courante sont remplies.
func can_cancel() -> bool:
	if move == null or frame < move.get_first_active_frame():
		return false
	match move.cancel_condition:
		MoveData.CancelCondition.ON_HIT:
			return has_connected and not was_blocked
		MoveData.CancelCondition.ON_HIT_OR_BLOCK:
			return has_connected
		MoveData.CancelCondition.ALWAYS:
			return true
	return false


func can_cancel_into(next: MoveData) -> bool:
	return next != null and can_cancel() and move.cancel_into.has(next.id)
