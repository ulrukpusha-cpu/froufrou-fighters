class_name FightManager
extends Node
## Déroulement d'un match : intro des manches, timer, détection des KO, attribution des
## manches, fin du match, résultat, puis passage à l'écran des résultats.
##
## C'est l'unique horloge du combat : chaque _physics_process avance la simulation d'une
## frame puis la logique de match. Les tests désactivent auto_run et appellent step().

signal round_started(round_number: int)
signal fight_started
signal timer_changed(seconds_left: int)
signal round_ended(winner_side: int, reason: RoundEndReason)
signal match_ended(result: MatchResult)

enum Phase { IDLE, ROUND_INTRO, FIGHTING, ROUND_OVER, MATCH_OVER }
enum RoundEndReason { KO, DOUBLE_KO, TIME_OUT }

@export var round_time_seconds: int = GameConstants.ROUND_TIME_SECONDS
@export var round_intro_frames: int = 100
@export var round_over_frames: int = 170
@export var victory_pose_delay_frames: int = 60
@export var results_delay_frames: int = 120
## Faux dans les tests : la simulation n'avance que via step().
@export var auto_run: bool = true
## Faux dans les tests : pas de changement de scène à la fin du match.
@export var go_to_results: bool = true

var simulation: CombatSimulation = CombatSimulation.new()
var fighters: Array[Fighter] = []
var stage: Stage = null
var rounds_won: Array[int] = [0, 0]
var round_number: int = 0
var phase: Phase = Phase.IDLE

var _phase_frames: int = 0
var _time_left_frames: int = 0
var _round_winner: int = GameConstants.NO_SIDE
var _knocked_out: Array[Fighter] = []
var _result: MatchResult = null


func setup(first: Fighter, second: Fighter, fight_stage: Stage) -> void:
	fighters = [first, second]
	stage = fight_stage
	simulation.setup(first, second, fight_stage)
	for fighter: Fighter in fighters:
		if not fighter.knocked_out.is_connected(_on_fighter_knocked_out):
			fighter.knocked_out.connect(_on_fighter_knocked_out)


func start_match() -> void:
	rounds_won = [0, 0]
	round_number = 0
	_result = null
	_start_round()


func _physics_process(_delta: float) -> void:
	if auto_run:
		step()


## Avance le match d'une frame de simulation.
func step() -> void:
	if phase == Phase.IDLE:
		return
	simulation.step()
	_phase_frames += 1
	match phase:
		Phase.ROUND_INTRO:
			if _phase_frames >= round_intro_frames:
				_begin_fight()
		Phase.FIGHTING:
			_tick_fighting()
		Phase.ROUND_OVER:
			_tick_round_over()
		Phase.MATCH_OVER:
			if go_to_results and _phase_frames == results_delay_frames:
				SceneRouter.go_to(GameConstants.SCENE_RESULTS)


func get_seconds_left() -> int:
	return ceili(float(_time_left_frames) / GameConstants.SIMULATION_FPS)


func get_result() -> MatchResult:
	return _result


func _start_round() -> void:
	round_number += 1
	_knocked_out.clear()
	simulation.combo_tracker.reset()
	_round_winner = GameConstants.NO_SIDE
	for fighter: Fighter in fighters:
		fighter.input_enabled = false
		fighter.reset_for_round(stage.get_spawn_position(fighter.side))
	for fighter: Fighter in fighters:
		fighter.face_opponent()
	_time_left_frames = round_time_seconds * GameConstants.SIMULATION_FPS
	_set_phase(Phase.ROUND_INTRO)
	round_started.emit(round_number)
	timer_changed.emit(get_seconds_left())


func _begin_fight() -> void:
	for fighter: Fighter in fighters:
		fighter.input_enabled = true
	_set_phase(Phase.FIGHTING)
	fight_started.emit()


func _tick_fighting() -> void:
	if not _knocked_out.is_empty():
		if _knocked_out.size() >= 2:
			_finish_round(GameConstants.NO_SIDE, RoundEndReason.DOUBLE_KO)
		else:
			_finish_round(_opponent_side(_knocked_out[0].side), RoundEndReason.KO)
		return
	_time_left_frames -= 1
	if _time_left_frames % GameConstants.SIMULATION_FPS == 0:
		timer_changed.emit(get_seconds_left())
	if _time_left_frames <= 0:
		_finish_round(_leader_by_health(), RoundEndReason.TIME_OUT)


func _finish_round(winner_side: int, reason: RoundEndReason) -> void:
	for fighter: Fighter in fighters:
		fighter.input_enabled = false
	_round_winner = winner_side
	if winner_side != GameConstants.NO_SIDE:
		rounds_won[winner_side] += 1
		if reason == RoundEndReason.TIME_OUT:
			fighters[_opponent_side(winner_side)].enter_defeat()
	_set_phase(Phase.ROUND_OVER)
	round_ended.emit(winner_side, reason)


func _tick_round_over() -> void:
	if _phase_frames == victory_pose_delay_frames and _round_winner != GameConstants.NO_SIDE:
		fighters[_round_winner].enter_victory()
	if _phase_frames < round_over_frames:
		return
	if _is_match_decided():
		_finish_match()
	else:
		_start_round()


func _is_match_decided() -> bool:
	return rounds_won.max() >= GameConstants.ROUNDS_TO_WIN or round_number >= GameConstants.MAX_ROUNDS


func _finish_match() -> void:
	_result = MatchResult.new()
	_result.rounds_won = rounds_won.duplicate()
	_result.rounds_played = round_number
	_result.fighter_ids = [fighters[0].data.id, fighters[1].data.id] as Array[StringName]
	if rounds_won[GameConstants.SIDE_P1] > rounds_won[GameConstants.SIDE_P2]:
		_result.winner_side = GameConstants.SIDE_P1
	elif rounds_won[GameConstants.SIDE_P2] > rounds_won[GameConstants.SIDE_P1]:
		_result.winner_side = GameConstants.SIDE_P2
	GameSession.record_result(_result)
	_set_phase(Phase.MATCH_OVER)
	match_ended.emit(_result)


## Camp ayant le plus de santé (en proportion), ou NO_SIDE en cas d'égalité.
func _leader_by_health() -> int:
	var ratio_p1: float = float(fighters[0].health) / fighters[0].data.max_health
	var ratio_p2: float = float(fighters[1].health) / fighters[1].data.max_health
	if is_equal_approx(ratio_p1, ratio_p2):
		return GameConstants.NO_SIDE
	return GameConstants.SIDE_P1 if ratio_p1 > ratio_p2 else GameConstants.SIDE_P2


func _opponent_side(fighter_side: int) -> int:
	return GameConstants.SIDE_P2 if fighter_side == GameConstants.SIDE_P1 else GameConstants.SIDE_P1


func _set_phase(new_phase: Phase) -> void:
	phase = new_phase
	_phase_frames = 0


func _on_fighter_knocked_out(fighter: Fighter) -> void:
	if phase == Phase.FIGHTING and fighter not in _knocked_out:
		_knocked_out.append(fighter)
