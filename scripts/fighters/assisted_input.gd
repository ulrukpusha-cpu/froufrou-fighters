class_name AssistedInput
extends RefCounted
## Mode de commandes ASSISTÉ : transforme les commandes du joueur avant qu'elles
## n'atteignent le moteur (qui reste identique pour tous les modes).
##
## - Combos simplifiés : marteler Poing enchaîne automatiquement
##   attaque légère → attaque lourde → attaque spéciale, dès que le coup précédent a touché.
##   Pendant une attaque, un appui sur Poing est mis en attente : il devient le coup suivant
##   dès que l'attaque touche ; sinon il est rendu comme simple Poing juste avant la fin de
##   l'attaque (dans la tolérance du moteur), pour enchaîner une nouvelle attaque légère.
## - Raccourci : Spécial déclenche l'ultime dès que la jauge le permet (sans Bas).
## Seules les annulations autorisées par les données (MoveData.cancel_into) sont utilisées.
## Une instance par contrôleur : elle mémorise l'appui en attente.

var _pending_punch: bool = false


func reset() -> void:
	_pending_punch = false


## Modifie « frame » sur place selon l'état courant du combattant.
func apply(frame: InputFrame, fighter: Fighter) -> void:
	if fighter == null or fighter.data == null:
		return
	_apply_combo_assist(frame, fighter)
	if frame.is_pressed(InputFrame.SPECIAL):
		var ultimate: MoveData = fighter.data.ultimate_move
		if ultimate != null and fighter.gauge >= ultimate.gauge_cost:
			frame.direction.y = 1


func _apply_combo_assist(frame: InputFrame, fighter: Fighter) -> void:
	var punch_pressed: bool = frame.is_pressed(InputFrame.PUNCH)
	if fighter.get_state() == Fighter.State.ATTACK:
		if punch_pressed:
			frame.pressed &= ~InputFrame.PUNCH
			_pending_punch = true
		if _pending_punch:
			var link: int = _next_link_button(fighter)
			if link != InputFrame.PUNCH:
				frame.pressed |= link
				_pending_punch = false
			# L'attaque se termine à frames_left + 1, l'action suivante part une frame plus
			# tard : l'appui doit alors avoir moins de INPUT_BUFFER_FRAMES frames d'âge.
			elif _frames_left(fighter) < GameConstants.INPUT_BUFFER_FRAMES - 1:
				frame.pressed |= InputFrame.PUNCH
				_pending_punch = false
		return
	if _pending_punch and not punch_pressed:
		frame.pressed |= InputFrame.PUNCH
	_pending_punch = false


static func _frames_left(fighter: Fighter) -> int:
	var runner: MoveRunner = fighter.move_runner
	return runner.move.get_total_frames() - runner.frame if runner.move != null else 0


## Bouton qui poursuit l'enchaînement en cours, ou PUNCH s'il n'y en a pas.
static func _next_link_button(fighter: Fighter) -> int:
	if not fighter.move_runner.has_connected:
		return InputFrame.PUNCH
	var data: FighterData = fighter.data
	var current: MoveData = fighter.move_runner.move
	if current == data.light_attack and _can_link(current, data.heavy_attack):
		return InputFrame.KICK
	if current == data.heavy_attack:
		if _can_link(current, data.special_move):
			return InputFrame.SPECIAL
		var ultimate: MoveData = data.ultimate_move
		if _can_link(current, ultimate) and fighter.gauge >= ultimate.gauge_cost:
			return InputFrame.SPECIAL
	return InputFrame.PUNCH


static func _can_link(current: MoveData, next: MoveData) -> bool:
	return next != null and current.cancel_into.has(next.id)
