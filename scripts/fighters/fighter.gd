class_name Fighter
extends CharacterBody2D
## Combattant générique, avancé frame par frame par CombatSimulation.
##
## - Les commandes viennent d'un FighterController (joueur, IA, script) : jamais d'un périphérique.
## - Les attaques sont des MoveData : aucune valeur propre à un personnage n'est codée ici.
## - La cinématique est calculée à la main à pas fixe (1/60 s) : déterministe et exacte à la
##   frame près, comme dans les jeux de combat de référence. Le CharacterBody2D porte la
##   boîte de poussée (couche fighter_body) ; move_and_slide() n'est pas utilisé car il
##   dépend du pas physique réel.

signal health_changed(current: int, maximum: int)
signal gauge_changed(current: int, maximum: int)
signal state_changed(previous: State, current: State)
signal move_started(move: MoveData)
signal hit_received(attacker: Fighter, move: MoveData, blocked: bool)
signal knocked_out(fighter: Fighter)
## Une posture de contre (MoveData.counter_window) vient d'annuler une attaque.
signal counter_triggered(attacker: Fighter, stance: MoveData)

enum State {
	IDLE, WALK, JUMP, CROUCH, ATTACK, BLOCK, HITSTUN, BLOCKSTUN,
	KNOCKDOWN, GETUP, DODGE, VICTORY, DEFEAT,
}

## Animation de chaque état (ATTACK utilise l'animation du MoveData en cours).
const STATE_ANIMATIONS: Dictionary = {
	State.IDLE: &"idle", State.WALK: &"walk", State.JUMP: &"jump", State.CROUCH: &"crouch",
	State.BLOCK: &"block", State.BLOCKSTUN: &"block", State.HITSTUN: &"hit",
	State.KNOCKDOWN: &"knockdown", State.GETUP: &"getup", State.DODGE: &"dodge",
	State.VICTORY: &"victory", State.DEFEAT: &"defeat",
}
const CROUCH_BLOCK_ANIMATION: StringName = &"crouch_block"
const INVULNERABLE_STATES: Array[State] = [State.KNOCKDOWN, State.GETUP, State.VICTORY, State.DEFEAT]
const UNTHROWABLE_STATES: Array[State] = [
	State.JUMP, State.HITSTUN, State.BLOCKSTUN, State.KNOCKDOWN, State.GETUP, State.DODGE,
]

@export var data: FighterData

var side: int = GameConstants.SIDE_P1
var controller: FighterController = null
var opponent: Fighter = null
var health: int = 0
var gauge: int = 0
## 1 = regarde à droite, -1 = regarde à gauche.
var facing: int = 1
## Faux pendant l'intro et la fin de manche : les commandes sont ignorées.
var input_enabled: bool = false
var state_machine: FighterStateMachine = FighterStateMachine.new()
var move_runner: MoveRunner = MoveRunner.new()

var _input: InputFrame = InputFrame.new()
var _buffer: InputBuffer = InputBuffer.new()
var _grounded: bool = true
var _crouching: bool = false
var _air_attack_used: bool = false
var _hitstop_frames: int = 0
var _stun_frames: int = 0
var _invulnerable_frames: int = 0
var _pushback_frames: int = 0
var _pushback_speed: float = 0.0
var _floor_y: float = 0.0
var _left_limit: float = -INF
var _right_limit: float = INF
var _active_hitboxes: Array[Hitbox] = []

@onready var _pushbox: CollisionShape2D = $Pushbox
@onready var _pivot: Node2D = $Pivot
@onready var _visual: FighterVisual = $Pivot/Visual
@onready var _hurtbox: Hurtbox = $Pivot/Hurtbox
@onready var _hitbox_pool: Array[Hitbox] = _collect_hitboxes()


# --- Mise en place ----------------------------------------------------------------------

## Configure le combattant. Retourne faux (avec erreur) si les données sont inutilisables.
func setup(fighter_data: FighterData, fighter_side: int, fighter_controller: FighterController) -> bool:
	if fighter_data == null:
		push_error("[Fighter] Aucune donnée de combattant")
		return false
	var issues: PackedStringArray = fighter_data.validate()
	if not issues.is_empty():
		push_error("[Fighter] %s invalide : %s" % [fighter_data.id, " | ".join(issues)])
		return false
	data = fighter_data
	side = fighter_side
	name = "Fighter%d_%s" % [side + 1, data.id]
	controller = fighter_controller if fighter_controller != null else FighterController.new()
	if controller.get_parent() == null:
		add_child(controller)
	collision_layer = PhysicsLayers.FIGHTER_BODY
	collision_mask = PhysicsLayers.STAGE_BOUNDS
	var body_shape := RectangleShape2D.new()
	body_shape.size = data.body_size
	_pushbox.shape = body_shape
	_pushbox.position = Vector2(0.0, -data.body_size.y * 0.5)
	_visual.setup(data)
	if not state_machine.state_changed.is_connected(_on_state_changed):
		state_machine.state_changed.connect(_on_state_changed)
	return true


## Limites du plan de combat (le corps entier reste entre les murs).
func set_stage_bounds(left: float, right: float, floor_y: float) -> void:
	var half_body: float = data.body_size.x * 0.5 if data != null else 0.0
	_left_limit = left + half_body
	_right_limit = right - half_body
	_floor_y = floor_y


func reset_for_round(spawn_position: Vector2) -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	_grounded = true
	_crouching = false
	_air_attack_used = false
	_hitstop_frames = 0
	_stun_frames = 0
	_invulnerable_frames = 0
	_pushback_frames = 0
	move_runner.stop()
	_buffer.clear()
	_input.clear()
	if controller != null:
		controller.reset()
	_set_health(data.max_health)
	_set_gauge(gauge)
	state_machine.reset()
	face_opponent()
	_visual.set_frozen(false)
	_update_hurtbox()
	_update_hitboxes()


# --- Simulation -------------------------------------------------------------------------

## Avance le combattant d'une frame. Appelé uniquement par CombatSimulation.
func simulate_frame() -> void:
	_read_input()
	if _hitstop_frames > 0:
		_hitstop_frames -= 1
		_visual.set_frozen(_hitstop_frames > 0)
		return
	_visual.set_frozen(false)
	state_machine.tick()
	if _invulnerable_frames > 0:
		_invulnerable_frames -= 1
	match state_machine.current:
		State.IDLE, State.WALK, State.CROUCH, State.BLOCK:
			_tick_neutral()
		State.JUMP:
			_tick_jump()
		State.ATTACK:
			_tick_attack()
		State.HITSTUN, State.BLOCKSTUN:
			_tick_stun()
		State.KNOCKDOWN:
			_tick_knockdown()
		State.GETUP:
			_tick_getup()
		State.DODGE:
			_tick_dodge()
		State.VICTORY, State.DEFEAT:
			_tick_passive()
	_apply_kinematics()
	_update_hurtbox()
	_update_hitboxes()


func _read_input() -> void:
	if input_enabled and controller != null:
		controller.poll(self, opponent, _input)
	else:
		_input.clear()
	var pressed: int = _input.pressed
	if _input.is_pressed(InputFrame.SPECIAL) and _input.direction.y > 0:
		pressed |= InputFrame.SPECIAL_DOWN
	if _hitstop_frames > 0:
		_buffer.merge(pressed)
	else:
		_buffer.push(pressed)


func _tick_neutral() -> void:
	face_opponent()
	if _try_start_attack():
		return
	if _buffer.has(InputFrame.DODGE):
		_buffer.consume(InputFrame.DODGE)
		_start_dodge()
		return
	var direction: Vector2i = _input.direction
	if direction.y < 0:
		_start_jump(direction.x)
		return
	_crouching = direction.y > 0
	velocity.x = 0.0
	if _input.is_held(InputFrame.GUARD):
		_change_state(State.BLOCK)
	elif _crouching:
		_change_state(State.CROUCH)
	elif direction.x != 0:
		var forward: bool = direction.x == facing
		velocity.x = direction.x * (data.walk_speed if forward else data.back_walk_speed)
		_change_state(State.WALK)
	else:
		_change_state(State.IDLE)
	_refresh_animation()


func _tick_jump() -> void:
	_try_start_attack()


func _tick_attack() -> void:
	move_runner.advance()
	if move_runner.is_finished():
		move_runner.stop()
		_return_to_neutral()
		return
	if _grounded and _try_kara_throw():
		return
	if move_runner.can_cancel():
		var next: MoveData = _select_move(false)
		if move_runner.can_cancel_into(next):
			_select_move(true)
			_start_move(next)
			return
	if _grounded:
		var phase: MoveData.Phase = move_runner.get_phase()
		var moving: bool = phase == MoveData.Phase.STARTUP or phase == MoveData.Phase.ACTIVE
		velocity.x = facing * move_runner.move.self_velocity.x if moving else 0.0


func _tick_stun() -> void:
	# Immobile une fois le recul terminé (_apply_kinematics applique le recul restant).
	velocity.x = 0.0
	if state_machine.current == State.BLOCKSTUN:
		_crouching = _input.direction.y > 0
		_refresh_animation()
	_stun_frames -= 1
	if _stun_frames > 0:
		return
	if state_machine.current == State.BLOCKSTUN and _input.is_held(InputFrame.GUARD):
		_change_state(State.BLOCK)
	else:
		_return_to_neutral()


func _tick_knockdown() -> void:
	if not _grounded:
		return
	_stun_frames -= 1
	if _stun_frames > 0:
		return
	if health <= 0:
		_change_state(State.DEFEAT)
	else:
		_change_state(State.GETUP)


func _tick_getup() -> void:
	if state_machine.frames_in_state >= GameConstants.GETUP_FRAMES:
		_return_to_neutral()


func _tick_dodge() -> void:
	if state_machine.frames_in_state >= data.dodge_frames:
		_return_to_neutral()
	else:
		velocity.x = -facing * data.dodge_speed


func _tick_passive() -> void:
	if _grounded:
		velocity.x = 0.0


func _apply_kinematics() -> void:
	if _pushback_frames > 0:
		_pushback_frames -= 1
		velocity.x = _pushback_speed
	var was_grounded: bool = _grounded
	if not _grounded:
		velocity.y += data.gravity * GameConstants.FRAME_DURATION
	global_position += velocity * GameConstants.FRAME_DURATION
	if global_position.y >= _floor_y:
		global_position.y = _floor_y
		velocity.y = 0.0
		_grounded = true
	else:
		_grounded = false
	global_position.x = clampf(global_position.x, _left_limit, _right_limit)
	if _grounded and not was_grounded:
		_on_landed()


func _on_landed() -> void:
	match state_machine.current:
		State.JUMP:
			velocity.x = 0.0
			_return_to_neutral()
		State.ATTACK:
			move_runner.stop()
			velocity.x = 0.0
			_return_to_neutral()
		State.KNOCKDOWN, State.VICTORY, State.DEFEAT:
			velocity.x = 0.0


# --- Actions ----------------------------------------------------------------------------

func _try_start_attack() -> bool:
	var move: MoveData = _select_move(true)
	return move != null and _start_move(move)


## Choisit l'attaque correspondant aux boutons en mémoire et à la posture.
## consume = vrai : les boutons utilisés sont retirés de la mémoire.
func _select_move(consume: bool) -> MoveData:
	if not _grounded:
		if _air_attack_used:
			return null
		return _pick(InputFrame.KICK, data.air_heavy_attack, consume) if _buffer.has(InputFrame.KICK) \
			else _pick(InputFrame.PUNCH, data.air_light_attack, consume)
	if _buffer.has_all(InputFrame.THROW_BUTTONS, GameConstants.THROW_INPUT_WINDOW_FRAMES):
		return _pick(InputFrame.THROW_BUTTONS, data.throw_move, consume)
	if _buffer.has(InputFrame.SPECIAL):
		return _pick(InputFrame.SPECIAL | InputFrame.SPECIAL_DOWN, _special_for_stance(), consume)
	var crouching: bool = _input.direction.y > 0
	if _buffer.has(InputFrame.KICK):
		return _pick(InputFrame.KICK, data.crouch_heavy_attack if crouching else data.heavy_attack, consume)
	return _pick(InputFrame.PUNCH, data.crouch_light_attack if crouching else data.light_attack, consume)


## Spécial seul = attaque spéciale ; Bas + Spécial = ultime si la jauge le permet.
## L'intention est lue dans la mémoire de commandes (SPECIAL_DOWN), pas dans la direction
## tenue au moment où l'attaque part.
func _special_for_stance() -> MoveData:
	var ultimate: MoveData = data.ultimate_move
	if _buffer.has(InputFrame.SPECIAL_DOWN) and ultimate != null and gauge >= ultimate.gauge_cost:
		return ultimate
	return data.special_move


func _pick(buttons: int, move: MoveData, consume: bool) -> MoveData:
	if move == null or not _buffer.has(buttons):
		return null
	if consume:
		_buffer.consume(buttons)
	return move


## Poing puis Pied à quelques frames d'écart : l'attaque légère devient une projection.
func _try_kara_throw() -> bool:
	var current: MoveData = move_runner.move
	if current == data.throw_move or current.crouching:
		return false
	if move_runner.frame > GameConstants.THROW_INPUT_WINDOW_FRAMES:
		return false
	if not _buffer.has_all(InputFrame.THROW_BUTTONS, GameConstants.THROW_INPUT_WINDOW_FRAMES):
		return false
	_buffer.consume(InputFrame.THROW_BUTTONS)
	return _start_move(data.throw_move)


func _start_move(move: MoveData) -> bool:
	if move == null or move.gauge_cost > gauge:
		return false
	_set_gauge(gauge - move.gauge_cost)
	_crouching = move.crouching
	if move.invulnerable_frames > 0:
		_invulnerable_frames = maxi(_invulnerable_frames, move.invulnerable_frames)
	if _grounded:
		velocity.x = 0.0
	else:
		_air_attack_used = true
	move_runner.start(move)
	_change_state(State.ATTACK, true)
	move_started.emit(move)
	return true


func _start_jump(direction_x: int) -> void:
	_crouching = false
	_grounded = false
	_air_attack_used = false
	velocity = Vector2(direction_x * data.jump_forward_speed, -data.jump_velocity)
	_change_state(State.JUMP)


func _start_dodge() -> void:
	_crouching = false
	_invulnerable_frames = data.dodge_invulnerable_frames
	_change_state(State.DODGE)
	velocity.x = -facing * data.dodge_speed


func _return_to_neutral() -> void:
	velocity.x = 0.0
	_crouching = _input.direction.y > 0
	_change_state(State.CROUCH if _crouching else State.IDLE)


# --- Impacts ----------------------------------------------------------------------------

## Reçoit une attaque. Retourne vrai si elle a été parée.
func take_hit(attacker: Fighter, move: MoveData) -> bool:
	var blocked: bool = _can_block(move)
	var away: float = _direction_away_from(attacker)
	var final_hit: bool = attacker.move_runner.get_hit_count(get_instance_id()) + 1 >= move.max_hits
	move_runner.stop()
	_hitstop_frames = move.hit_stop_frames
	if blocked:
		if move.chip_damage > 0:
			_set_health(maxi(health - move.chip_damage, 1))
		_add_gauge(roundi(move.gauge_gain_on_block * GameConstants.DEFENDER_GAUGE_RATIO))
		_stun_frames = move.blockstun_frames
		_change_state(State.BLOCKSTUN, true)
		_push_away(away, move.pushback, attacker)
	else:
		_set_health(health - move.damage)
		_add_gauge(roundi(move.gauge_gain_on_hit * GameConstants.DEFENDER_GAUGE_RATIO))
		_visual.flash()
		if health <= 0:
			_enter_knockdown(away, GameConstants.KO_LAUNCH)
			knocked_out.emit(self)
		elif (move.knockdown and final_hit) or move.is_throw:
			_enter_knockdown(away, move.launch_velocity)
		elif not _grounded:
			_enter_knockdown(away, GameConstants.AIR_HIT_LAUNCH)
		else:
			_stun_frames = move.hitstun_frames
			_change_state(State.HITSTUN, true)
			_push_away(away, move.pushback, attacker)
	_update_hitboxes()
	hit_received.emit(attacker, move, blocked)
	return blocked


## Vrai si ce combattant est dans la fenêtre active d'une posture de contre qui
## peut annuler « move ».
func can_counter(move: MoveData) -> bool:
	if state_machine.current != State.ATTACK or not move_runner.is_active():
		return false
	return move_runner.move.counter_window and move.is_counterable()


## Déclenche la posture de contre : l'attaque reçue est annulée, l'attaquant est sonné et
## la riposte démarre immédiatement.
func perform_counter(attacker: Fighter) -> void:
	var stance: MoveData = move_runner.move
	attacker.receive_counter(stance.counter_stun_frames)
	_start_move(stance.counter_follow_up)
	_hitstop_frames = GameConstants.COUNTER_HIT_STOP_FRAMES
	_update_hitboxes()
	counter_triggered.emit(attacker, stance)


## Subit un contre : l'attaque en cours est perdue, le combattant reste sonné.
func receive_counter(stun_frames: int) -> void:
	move_runner.stop()
	_pushback_frames = 0
	velocity.x = 0.0
	_stun_frames = stun_frames
	_hitstop_frames = GameConstants.COUNTER_HIT_STOP_FRAMES
	_visual.flash()
	_change_state(State.HITSTUN, true)
	_update_hitboxes()


## Vrai tant qu'un enchaînement de l'adversaire peut encore le toucher (compteur de combos).
func is_in_combo_state() -> bool:
	match state_machine.current:
		State.HITSTUN:
			return true
		State.KNOCKDOWN:
			return not _grounded
	return false


## Appelé sur l'attaquant quand son attaque a touché (ou a été parée).
func on_hit_confirmed(defender: Fighter, move: MoveData, blocked: bool) -> void:
	move_runner.register_hit(defender.get_instance_id(), blocked)
	_hitstop_frames = move.hit_stop_frames
	_add_gauge(move.gauge_gain_on_block if blocked else move.gauge_gain_on_hit)


## Recul horizontal réparti sur GameConstants.PUSHBACK_FRAMES frames.
func apply_pushback(direction: float, distance: float) -> void:
	if distance <= 0.0:
		return
	_pushback_frames = GameConstants.PUSHBACK_FRAMES
	_pushback_speed = direction * distance / (GameConstants.PUSHBACK_FRAMES * GameConstants.FRAME_DURATION)


## Dos au mur, c'est l'attaquant qui recule à la place du défenseur.
func _push_away(direction: float, distance: float, attacker: Fighter) -> void:
	if is_against_wall(direction):
		attacker.apply_pushback(-direction, distance)
	else:
		apply_pushback(direction, distance)


func _enter_knockdown(direction: float, launch: Vector2) -> void:
	_pushback_frames = 0
	_crouching = false
	velocity = Vector2(direction * launch.x, launch.y)
	_grounded = launch.y >= 0.0 and _grounded
	_stun_frames = GameConstants.KNOCKDOWN_FRAMES
	_change_state(State.KNOCKDOWN, true)


func _can_block(move: MoveData) -> bool:
	if move.is_throw or not _grounded or not is_guarding():
		return false
	match move.hit_level:
		MoveData.HitLevel.LOW:
			return _crouching
		MoveData.HitLevel.OVERHEAD:
			return not _crouching
	return true


func _direction_away_from(attacker: Fighter) -> float:
	var dx: float = global_position.x - attacker.global_position.x
	if absf(dx) < 1.0:
		return float(attacker.facing)
	return signf(dx)


## Fin de manche : pose de victoire (forcée, quel que soit l'état courant).
func enter_victory() -> void:
	move_runner.stop()
	_pushback_frames = 0
	_change_state(State.VICTORY)
	_update_hitboxes()


## Défaite au temps : le combattant met un genou à terre.
func enter_defeat() -> void:
	move_runner.stop()
	_pushback_frames = 0
	_change_state(State.DEFEAT)
	_update_hitboxes()


# --- Requêtes ---------------------------------------------------------------------------

func get_state() -> State:
	return state_machine.current


func is_grounded() -> bool:
	return _grounded


func is_crouching() -> bool:
	return _crouching


## Garde : bouton Garde, ou maintien de la direction arrière quand le combattant peut agir.
func is_guarding() -> bool:
	match state_machine.current:
		State.BLOCK, State.BLOCKSTUN:
			return true
		State.IDLE, State.WALK, State.CROUCH:
			return _input.direction.x == -facing or _input.is_held(InputFrame.GUARD)
	return false


func is_invulnerable() -> bool:
	return _invulnerable_frames > 0 or state_machine.current in INVULNERABLE_STATES


func is_hittable() -> bool:
	return not is_invulnerable() and _hurtbox.is_enabled()


func is_throwable() -> bool:
	return is_hittable() and _grounded and state_machine.current not in UNTHROWABLE_STATES


func is_in_hitstop() -> bool:
	return _hitstop_frames > 0


func is_against_wall(direction: float) -> bool:
	if direction > 0.0:
		return global_position.x >= _right_limit - GameConstants.WALL_PROXIMITY
	return global_position.x <= _left_limit + GameConstants.WALL_PROXIMITY


func get_hurtbox_rect() -> Rect2:
	return _hurtbox.get_world_rect()


## Hitboxes actives à cette frame (tableau réutilisé : ne pas conserver de référence).
func get_active_hitboxes() -> Array[Hitbox]:
	return _active_hitboxes


func get_body_width() -> float:
	return data.body_size.x


func get_body_height() -> float:
	return data.body_size.y


func get_current_animation() -> StringName:
	return _visual.get_current_animation()


## Décale horizontalement en respectant les murs. Retourne le décalage réellement appliqué.
func shift_x(amount: float) -> float:
	var before: float = global_position.x
	global_position.x = clampf(before + amount, _left_limit, _right_limit)
	return global_position.x - before


func face_opponent() -> void:
	if opponent == null:
		return
	var dx: float = opponent.global_position.x - global_position.x
	if absf(dx) < 1.0:
		return
	var new_facing: int = 1 if dx > 0.0 else -1
	if new_facing != facing:
		facing = new_facing
		_pivot.scale.x = facing


# --- Interne ----------------------------------------------------------------------------

func _change_state(next: State, restart: bool = false) -> void:
	state_machine.change(next, restart)


func _on_state_changed(previous: State, current: State) -> void:
	_refresh_animation()
	state_changed.emit(previous, current)


func _refresh_animation() -> void:
	var current: State = state_machine.current
	if current == State.ATTACK and move_runner.move != null:
		_visual.play(move_runner.move.animation)
	elif (current == State.BLOCK or current == State.BLOCKSTUN) and _crouching:
		_visual.play(CROUCH_BLOCK_ANIMATION)
	else:
		var walking_back: bool = current == State.WALK and velocity.x * facing < 0.0
		_visual.play(STATE_ANIMATIONS.get(current, &"idle"), walking_back)


func _update_hurtbox() -> void:
	_hurtbox.set_rect(data.crouching_hurtbox if _crouching else data.standing_hurtbox)
	_hurtbox.set_enabled(not is_invulnerable())


func _update_hitboxes() -> void:
	_active_hitboxes.clear()
	var active: bool = move_runner.is_running() and move_runner.is_active()
	var index: int = move_runner.get_active_index()
	for i: int in _hitbox_pool.size():
		var hitbox: Hitbox = _hitbox_pool[i]
		var box: HitboxData = null
		if active and i < move_runner.move.hitboxes.size():
			box = move_runner.move.hitboxes[i]
		if box != null and box.is_active_at(index, move_runner.move.active_frames):
			hitbox.activate(box.rect)
			_active_hitboxes.append(hitbox)
		else:
			hitbox.deactivate()


func _set_health(value: int) -> void:
	health = clampi(value, 0, data.max_health)
	health_changed.emit(health, data.max_health)


func _set_gauge(value: int) -> void:
	gauge = clampi(value, 0, GameConstants.SUPER_GAUGE_MAX)
	gauge_changed.emit(gauge, GameConstants.SUPER_GAUGE_MAX)


## Ajoute (ou retire) de la jauge, bornée entre 0 et le maximum.
func add_gauge(amount: int) -> void:
	_add_gauge(amount)


func _add_gauge(amount: int) -> void:
	if amount != 0:
		_set_gauge(gauge + amount)


func _collect_hitboxes() -> Array[Hitbox]:
	var pool: Array[Hitbox] = []
	for child: Node in $Pivot/Hitboxes.get_children():
		var hitbox: Hitbox = child as Hitbox
		if hitbox != null:
			pool.append(hitbox)
	return pool
