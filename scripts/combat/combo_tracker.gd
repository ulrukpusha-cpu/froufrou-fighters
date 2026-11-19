class_name ComboTracker
extends RefCounted
## Compte les enchaînements : un impact compte dans le combo en cours s'il touche un
## adversaire qui n'avait pas encore récupéré (hitstun, ou chute en l'air). Le combo se
## termine dès que l'adversaire peut de nouveau agir ou se défendre.

## Émis à chaque impact d'un combo (hits >= 1).
signal combo_updated(attacker_side: int, hits: int, damage: int)
## Émis quand un combo d'au moins GameConstants.COMBO_MIN_HITS impacts se termine.
signal combo_finished(attacker_side: int, hits: int, damage: int)

## Indexés par camp de l'attaquant.
var hits: Array[int] = [0, 0]
var damage: Array[int] = [0, 0]


func reset() -> void:
	for side: int in hits.size():
		hits[side] = 0
		damage[side] = 0


## defender_was_stunned : état du défenseur AVANT l'impact.
func register_hit(attacker_side: int, defender_was_stunned: bool, dealt: int, blocked: bool) -> void:
	if blocked:
		_finish(attacker_side)
		return
	if not defender_was_stunned or hits[attacker_side] == 0:
		_finish(attacker_side)
		hits[attacker_side] = 1
		damage[attacker_side] = dealt
	else:
		hits[attacker_side] += 1
		damage[attacker_side] += dealt
	combo_updated.emit(attacker_side, hits[attacker_side], damage[attacker_side])


## À appeler à chaque frame : clôt le combo d'un camp dont la cible a récupéré.
func update(fighters: Array[Fighter]) -> void:
	for side: int in fighters.size():
		var defender: Fighter = fighters[1 - side]
		if hits[side] > 0 and not defender.is_in_combo_state() and not defender.is_in_hitstop():
			_finish(side)


func _finish(side: int) -> void:
	if hits[side] >= GameConstants.COMBO_MIN_HITS:
		combo_finished.emit(side, hits[side], damage[side])
	hits[side] = 0
	damage[side] = 0
