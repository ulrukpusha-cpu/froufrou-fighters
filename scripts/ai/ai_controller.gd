class_name AIController
extends FighterController
## Intelligence artificielle d'un combattant.
##
## Chaque frame :
##   1. elle enregistre ce qu'elle voit de l'adversaire (AIPerception, informations visibles) ;
##   2. elle décide à partir de ce qu'elle voyait il y a profile.reaction_frames frames ;
##   3. elle produit des commandes comme un joueur (InputFrame) : le moteur ne fait aucune
##      différence entre l'IA et un humain, et l'IA ne lit jamais les commandes de l'adversaire.
##
## Priorités : poursuivre un combo > tenir sa garde > réagir à une attaque perçue (contre,
## esquive, garde) > punir une récupération > jeu neutre (distance, attaque, garde préventive).
## Le comportement de chaque difficulté vient entièrement de son AIProfile.

## Frames de garde ajoutées après la fin estimée de l'attaque adverse.
const GUARD_EXTRA_FRAMES: int = 6
const PREEMPTIVE_GUARD_FRAMES: int = 18
## La garde préventive est tirée avec block_chance × ce facteur.
const PREEMPTIVE_GUARD_FACTOR: float = 0.5
const WALK_INTENT_FRAMES: int = 12
const RETREAT_INTENT_FRAMES: int = 10
const REACH_MARGIN: float = 15.0
const JUMP_APPROACH_DISTANCE: float = 520.0
## Une attaque à partir de ces dégâts peut être esquivée (comme les ultimes).
const DODGE_DAMAGE_THRESHOLD: int = 90
## En neutre, l'ultime est tentée avec ultimate_chance × ce facteur (elle sert surtout
## à punir ou à conclure un combo).
const NEUTRAL_ULTIMATE_FACTOR: float = 0.15
## Répartition des attaques en neutre : léger, lourd, le reste = balayage.
const LIGHT_WEIGHT: float = 0.5
const HEAVY_WEIGHT: float = 0.3
const SPACING_RETREAT_CHANCE: float = 0.5

var profile: AIProfile
var perception: AIPerception = AIPerception.new()

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _direction: Vector2i = Vector2i.ZERO
var _held: int = 0
var _previous_held: int = 0
var _guard_frames: int = 0
var _guard_crouching: bool = false
var _intent_frames: int = 0
var _intent_direction_x: int = 0
var _decision_cooldown: int = 0
var _reacted_key: int = -2
var _punish_key: int = -2
var _combo_move: MoveData = null
var _combo_move_frame: int = 0
var _combo_rolled: bool = false
var _air_attack_pending: bool = false


## rng_seed : graine du générateur (même graine + mêmes situations = mêmes décisions).
func _init(ai_profile: AIProfile = null, rng_seed: int = 1) -> void:
	profile = ai_profile if ai_profile != null else AIProfile.new()
	_rng.seed = rng_seed


func reset() -> void:
	perception.clear()
	_direction = Vector2i.ZERO
	_held = 0
	_previous_held = 0
	_guard_frames = 0
	_intent_frames = 0
	_decision_cooldown = 0
	_reacted_key = -2
	_punish_key = -2
	_combo_move = null
	_combo_rolled = false
	_air_attack_pending = false


func poll(fighter: Fighter, opponent: Fighter, out_frame: InputFrame) -> void:
	if fighter == null or opponent == null:
		out_frame.clear()
		return
	perception.record(fighter, opponent)
	_held = 0
	_direction = Vector2i.ZERO
	think(fighter, perception.delayed(profile.reaction_frames))
	out_frame.set_from(_direction, _held, _previous_held)
	_previous_held = _held


## Dernières commandes produites (x, y = direction, z = boutons maintenus) : débogage, tests.
func get_last_output() -> Vector3i:
	return Vector3i(_direction.x, _direction.y, _held)


## Décide des commandes de cette frame à partir d'une observation.
func think(fighter: Fighter, seen: AISnapshot) -> void:
	if not seen.valid:
		return
	match fighter.get_state():
		Fighter.State.ATTACK:
			_think_combo(fighter)
			return
		Fighter.State.JUMP:
			_think_air(fighter, seen)
			return
	if not fighter.state_machine.is_actionable():
		if fighter.get_state() == Fighter.State.BLOCKSTUN and _guard_frames > 0:
			_guard_frames -= 1
			_hold_guard()
		else:
			_guard_frames = 0
		_intent_frames = 0
		return
	if _guard_frames > 0:
		_guard_frames -= 1
		_hold_guard()
		return
	if _react_to_attack(fighter, seen):
		return
	if _try_punish(fighter, seen):
		return
	_think_neutral(fighter, seen)


# --- Combos -----------------------------------------------------------------------------

## Une décision par attaque : si elle touche, l'IA tente de l'annuler dans la suivante.
func _think_combo(fighter: Fighter) -> void:
	var runner: MoveRunner = fighter.move_runner
	if runner.move != _combo_move or runner.frame < _combo_move_frame:
		_combo_move = runner.move
		_combo_rolled = false
	_combo_move_frame = runner.frame
	if _combo_rolled or not runner.has_connected:
		return
	_combo_rolled = true
	if not _roll(profile.combo_chance):
		return
	var data: FighterData = fighter.data
	var current: MoveData = runner.move
	if _ultimate_ready(fighter) and current.cancel_into.has(data.ultimate_move.id) and _roll(profile.ultimate_chance):
		_press(InputFrame.SPECIAL, Vector2i.DOWN)
	elif current == data.light_attack and current.cancel_into.has(data.heavy_attack.id):
		_press(InputFrame.KICK)
	elif _is_offensive_special(data) and current.cancel_into.has(data.special_move.id):
		_press(InputFrame.SPECIAL)


func _think_air(fighter: Fighter, seen: AISnapshot) -> void:
	if not _air_attack_pending or fighter.velocity.y <= 0.0:
		return
	if seen.distance <= _move_reach(fighter.data.air_heavy_attack) + seen.opponent_half_width + REACH_MARGIN:
		_press(InputFrame.KICK)
		_air_attack_pending = false


# --- Défense ----------------------------------------------------------------------------

## Réagit (une seule fois par attaque perçue) : contre, esquive ou garde.
func _react_to_attack(fighter: Fighter, seen: AISnapshot) -> bool:
	if not seen.is_opponent_attacking():
		return false
	var phase: MoveData.Phase = seen.opponent_move_phase
	if phase != MoveData.Phase.STARTUP and phase != MoveData.Phase.ACTIVE:
		return false
	var key: int = seen.get_move_key()
	var move: MoveData = seen.opponent_move
	if key == _reacted_key or seen.distance > _threat_range(move, fighter):
		return false
	_reacted_key = key
	# Frame actuelle estimée de l'attaque adverse = frame perçue + temps de réaction.
	var elapsed: int = seen.opponent_move_frame + profile.reaction_frames
	var frames_to_active: int = move.get_first_active_frame() - elapsed
	var special: MoveData = fighter.data.special_move
	if special != null and special.counter_window and move.is_counterable() \
			and frames_to_active >= special.startup_frames and _roll(profile.counter_chance):
		_press(InputFrame.SPECIAL)
		return true
	if move.is_throw:
		return false
	var dangerous: bool = move.category == MoveData.Category.ULTIMATE or move.damage >= DODGE_DAMAGE_THRESHOLD
	if dangerous and _roll(profile.dodge_chance):
		_press(InputFrame.DODGE)
		return true
	if _roll(profile.block_chance):
		_start_guard(_choose_guard_crouching(move.hit_level), move.get_total_frames() - elapsed + GUARD_EXTRA_FRAMES)
		return true
	return false


## Garde basse pour MID et LOW, haute pour les attaques sautées ; erreur possible selon le profil.
func _choose_guard_crouching(level: MoveData.HitLevel) -> bool:
	var crouch: bool = level != MoveData.HitLevel.OVERHEAD
	return crouch if _roll(profile.guard_accuracy) else not crouch


func _start_guard(crouching: bool, frames: int) -> void:
	_guard_crouching = crouching
	_guard_frames = maxi(frames, GUARD_EXTRA_FRAMES)
	_hold_guard()


func _hold_guard() -> void:
	_held |= InputFrame.GUARD
	_direction.y = 1 if _guard_crouching else 0


# --- Punition ---------------------------------------------------------------------------

## Attaque l'adversaire pendant sa récupération si un coup assez rapide peut l'atteindre.
func _try_punish(fighter: Fighter, seen: AISnapshot) -> bool:
	if not seen.is_opponent_attacking() or seen.opponent_move_phase != MoveData.Phase.RECOVERY:
		return false
	var key: int = seen.get_move_key()
	if key == _punish_key:
		return false
	_punish_key = key
	var frames_left: int = seen.opponent_move.get_total_frames() - (seen.opponent_move_frame + profile.reaction_frames)
	if frames_left <= 0 or not _roll(profile.punish_chance):
		return false
	var data: FighterData = fighter.data
	if _ultimate_ready(fighter) and _can_punish_with(data.ultimate_move, seen, frames_left) \
			and _roll(profile.ultimate_chance):
		_press(InputFrame.SPECIAL, Vector2i.DOWN)
		return true
	if _can_punish_with(data.heavy_attack, seen, frames_left):
		_press(InputFrame.KICK)
		return true
	if _can_punish_with(data.light_attack, seen, frames_left):
		_press(InputFrame.PUNCH)
		return true
	return false


func _can_punish_with(move: MoveData, seen: AISnapshot, frames_left: int) -> bool:
	if move == null or move.get_first_active_frame() > frames_left:
		return false
	return seen.distance <= _move_reach(move) + seen.opponent_half_width


# --- Neutre -----------------------------------------------------------------------------

func _think_neutral(fighter: Fighter, seen: AISnapshot) -> void:
	if _intent_frames > 0:
		_intent_frames -= 1
		_direction.x = _intent_direction_x
		return
	if _decision_cooldown > 0:
		_decision_cooldown -= 1
		return
	_decision_cooldown = profile.decision_interval_frames
	var data: FighterData = fighter.data
	var toward: int = seen.direction_to_opponent
	var light_range: float = _move_reach(data.light_attack) + seen.opponent_half_width
	var attack_range: float = maxf(light_range, _move_reach(data.heavy_attack) + seen.opponent_half_width)
	if seen.opponent_state == Fighter.State.KNOCKDOWN or seen.opponent_state == Fighter.State.GETUP:
		if seen.distance > light_range:
			_walk(toward, WALK_INTENT_FRAMES)
		return
	if seen.distance > attack_range:
		if seen.distance <= JUMP_APPROACH_DISTANCE and _roll(profile.jump_chance):
			_direction = Vector2i(toward, -1)
			_air_attack_pending = true
		else:
			_walk(toward, WALK_INTENT_FRAMES)
		return
	var throw_range: float = _move_reach(data.throw_move) + seen.opponent_half_width
	if seen.opponent_guarding and seen.distance <= throw_range and _roll(profile.throw_chance):
		_press(InputFrame.THROW_BUTTONS)
	elif _roll(profile.aggression):
		_neutral_attack(fighter, seen, light_range)
	elif _roll(profile.block_chance * PREEMPTIVE_GUARD_FACTOR):
		_start_guard(seen.opponent_grounded, PREEMPTIVE_GUARD_FRAMES)
	elif profile.manages_spacing and _roll(SPACING_RETREAT_CHANCE):
		_walk(-toward, RETREAT_INTENT_FRAMES)


func _neutral_attack(fighter: Fighter, seen: AISnapshot, light_range: float) -> void:
	var data: FighterData = fighter.data
	if _is_offensive_special(data) and _roll(profile.special_chance) \
			and seen.distance <= _move_reach(data.special_move) + seen.opponent_half_width:
		_press(InputFrame.SPECIAL)
		return
	if _ultimate_ready(fighter) and _roll(profile.ultimate_chance * NEUTRAL_ULTIMATE_FACTOR) \
			and seen.distance <= _move_reach(data.ultimate_move) + seen.opponent_half_width:
		_press(InputFrame.SPECIAL, Vector2i.DOWN)
		return
	var pick: float = _rng.randf()
	if pick < LIGHT_WEIGHT and seen.distance <= light_range:
		_press(InputFrame.PUNCH)
	elif pick < LIGHT_WEIGHT + HEAVY_WEIGHT:
		_press(InputFrame.KICK)
	else:
		_press(InputFrame.KICK, Vector2i.DOWN)


func _walk(direction_x: int, frames: int) -> void:
	_intent_direction_x = direction_x
	_intent_frames = frames
	_direction.x = direction_x


# --- Outils -----------------------------------------------------------------------------

func _press(buttons: int, direction: Vector2i = Vector2i.ZERO) -> void:
	_held |= buttons
	if direction != Vector2i.ZERO:
		_direction = direction


func _roll(probability: float) -> bool:
	return probability > 0.0 and _rng.randf() < probability


func _ultimate_ready(fighter: Fighter) -> bool:
	var ultimate: MoveData = fighter.data.ultimate_move
	return ultimate != null and fighter.gauge >= ultimate.gauge_cost


## Un spécial qui frappe (une posture de contre ne s'utilise qu'en réaction).
static func _is_offensive_special(data: FighterData) -> bool:
	return data.special_move != null and not data.special_move.counter_window


## Distance que les hitboxes d'une attaque couvrent devant le combattant, déplacement compris.
static func _move_reach(move: MoveData) -> float:
	if move == null:
		return 0.0
	var reach: float = 0.0
	for box: HitboxData in move.hitboxes:
		reach = maxf(reach, box.rect.end.x)
	var travel_frames: int = move.startup_frames + move.active_frames
	return reach + absf(move.self_velocity.x) * travel_frames * GameConstants.FRAME_DURATION


## Distance à partir de laquelle une attaque adverse peut atteindre ce combattant.
static func _threat_range(move: MoveData, fighter: Fighter) -> float:
	return _move_reach(move) - fighter.data.standing_hurtbox.position.x + REACH_MARGIN
