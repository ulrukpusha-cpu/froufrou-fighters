class_name CombatSimulation
extends RefCounted
## Avance le combat d'une frame, dans un ordre fixe et identique pour les deux combattants :
##   1. chaque combattant lit ses commandes et se déplace ;
##   2. les boîtes de poussée sont séparées (et l'écart maximal respecté) ;
##   3. les impacts sont détectés pour les DEUX combattants AVANT d'être appliqués : deux
##      attaques qui se touchent à la même frame s'échangent (trade), sans favoriser le J1 ;
##   4. une frappe reçue pendant une posture de contre déclenche la riposte au lieu de toucher ;
##   5. le compteur de combos est mis à jour.

signal hit_confirmed(attacker: Fighter, defender: Fighter, move: MoveData, blocked: bool)
signal counter_confirmed(defender: Fighter, attacker: Fighter)

var fighters: Array[Fighter] = []
var stage: Stage = null
var combo_tracker: ComboTracker = ComboTracker.new()


func setup(first: Fighter, second: Fighter, fight_stage: Stage) -> void:
	fighters = [first, second]
	stage = fight_stage
	first.opponent = second
	second.opponent = first
	for fighter: Fighter in fighters:
		fighter.set_stage_bounds(stage.get_left_limit(), stage.get_right_limit(), stage.get_floor_y())


func step() -> void:
	for fighter: Fighter in fighters:
		fighter.simulate_frame()
	_separate_bodies()
	_resolve_hits()
	combo_tracker.update(fighters)


func _separate_bodies() -> void:
	var a: Fighter = fighters[0]
	var b: Fighter = fighters[1]
	var dx: float = b.global_position.x - a.global_position.x
	var vertical_gap: float = absf(a.global_position.y - b.global_position.y)
	var min_height: float = minf(a.get_body_height(), b.get_body_height())
	var min_distance: float = (a.get_body_width() + b.get_body_width()) * 0.5
	if vertical_gap < min_height and absf(dx) < min_distance:
		var direction: float = signf(dx) if absf(dx) >= 1.0 else float(a.facing)
		_spread(a, b, direction, min_distance - absf(dx))
	var separation: float = absf(b.global_position.x - a.global_position.x)
	if separation > GameConstants.MAX_FIGHTER_SEPARATION:
		var pull: float = separation - GameConstants.MAX_FIGHTER_SEPARATION
		var a_to_b: float = signf(b.global_position.x - a.global_position.x)
		_spread(a, b, -a_to_b, pull)


## Écarte (amount > 0 et direction = sens de a vers b) ou rapproche (direction inversée)
## a et b de « amount » au total. Si l'un est bloqué par un mur, l'autre compense.
func _spread(a: Fighter, b: Fighter, direction: float, amount: float) -> void:
	var half: float = amount * 0.5
	var moved_a: float = absf(a.shift_x(-direction * half))
	var moved_b: float = absf(b.shift_x(direction * (amount - moved_a)))
	var remaining: float = amount - moved_a - moved_b
	if remaining > 0.0:
		a.shift_x(-direction * remaining)


func _resolve_hits() -> void:
	var a: Fighter = fighters[0]
	var b: Fighter = fighters[1]
	var a_hits_b: bool = _hit_connects(a, b)
	var b_hits_a: bool = _hit_connects(b, a)
	var move_a: MoveData = a.move_runner.move
	var move_b: MoveData = b.move_runner.move
	if a_hits_b:
		_apply_hit(a, b, move_a)
	if b_hits_a:
		_apply_hit(b, a, move_b)


func _hit_connects(attacker: Fighter, defender: Fighter) -> bool:
	var runner: MoveRunner = attacker.move_runner
	if not runner.is_running() or not runner.is_active():
		return false
	if not defender.is_hittable():
		return false
	if runner.move.is_throw and not defender.is_throwable():
		return false
	if not runner.can_hit(defender.get_instance_id()):
		return false
	var hurtbox: Rect2 = defender.get_hurtbox_rect()
	for hitbox: Hitbox in attacker.get_active_hitboxes():
		if hitbox.get_world_rect().intersects(hurtbox):
			return true
	return false


func _apply_hit(attacker: Fighter, defender: Fighter, move: MoveData) -> void:
	if defender.can_counter(move):
		defender.perform_counter(attacker)
		counter_confirmed.emit(defender, attacker)
		return
	var was_stunned: bool = defender.is_in_combo_state()
	var health_before: int = defender.health
	var blocked: bool = defender.take_hit(attacker, move)
	attacker.on_hit_confirmed(defender, move, blocked)
	combo_tracker.register_hit(attacker.side, was_stunned, health_before - defender.health, blocked)
	hit_confirmed.emit(attacker, defender, move, blocked)
