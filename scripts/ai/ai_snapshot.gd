class_name AISnapshot
extends RefCounted
## Ce que l'IA voit de l'adversaire à une frame donnée : uniquement des informations
## VISIBLES à l'écran (position, posture, attaque en cours). Jamais ses commandes, sa
## mémoire de tampon ni son contrôleur : l'IA ne peut pas connaître les commandes futures.

var valid: bool = false
## Numéro de frame de perception (croissant).
var frame_index: int = 0
var distance: float = 0.0
## Sens (-1 / 1) dans lequel se trouve l'adversaire.
var direction_to_opponent: int = 1
var opponent_state: Fighter.State = Fighter.State.IDLE
var opponent_move: MoveData = null
var opponent_move_frame: int = 0
var opponent_move_phase: MoveData.Phase = MoveData.Phase.FINISHED
var opponent_grounded: bool = true
var opponent_crouching: bool = false
## Visible uniquement par la posture : en garde (BLOCK) ou en train de parer (BLOCKSTUN).
var opponent_guarding: bool = false
var opponent_health: int = 0
## Demi-largeur de la boîte vulnérable debout de l'adversaire (donnée statique).
var opponent_half_width: float = 0.0


func capture(self_fighter: Fighter, opponent: Fighter, index: int) -> void:
	valid = true
	frame_index = index
	var dx: float = opponent.global_position.x - self_fighter.global_position.x
	distance = absf(dx)
	direction_to_opponent = 1 if dx >= 0.0 else -1
	opponent_state = opponent.get_state()
	opponent_move = opponent.move_runner.move
	opponent_move_frame = opponent.move_runner.frame
	opponent_move_phase = opponent.move_runner.get_phase()
	opponent_grounded = opponent.is_grounded()
	opponent_crouching = opponent.is_crouching()
	opponent_guarding = opponent_state == Fighter.State.BLOCK or opponent_state == Fighter.State.BLOCKSTUN
	opponent_health = opponent.health
	opponent_half_width = -opponent.data.standing_hurtbox.position.x


## Identifiant de l'attaque en cours (frame de perception à laquelle elle a commencé).
func get_move_key() -> int:
	return frame_index - opponent_move_frame if opponent_move != null else -1


func is_opponent_attacking() -> bool:
	return opponent_state == Fighter.State.ATTACK and opponent_move != null
