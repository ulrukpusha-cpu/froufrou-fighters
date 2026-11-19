extends Node2D
## Assemble un combat : arène, deux combattants, contrôleurs, caméra, HUD et FightManager.
##
## Le joueur 1 est piloté par PlayerController ; l'adversaire par AIController, avec le
## profil de la difficulté choisie (GameSession.difficulty).
## Toute ressource manquante est signalée et ramène au menu principal.

## Dégâts d'un coup qui fait réagir le décor au maximum (foule debout, néons qui grésillent).
const STAGE_REACTION_FULL_DAMAGE: float = 150.0

## Si faux (tests), le match n'est pas lancé automatiquement au _ready().
@export var auto_start: bool = true

var player: Fighter = null
var opponent: Fighter = null
var stage: Stage = null

@onready var _world: Node2D = $World
@onready var _camera: FightCamera = $FightCamera
@onready var _manager: FightManager = $FightManager
@onready var _hud: FightHud = $FightHud
@onready var _touch: TouchControls = $TouchControls
@onready var _pause: PauseMenu = $PauseMenu

## Meilleur combo du joueur 1 pendant ce match (statistiques).
var _best_combo: int = 0


func _ready() -> void:
	# Sécurité : une scène de combat ne démarre jamais figée (ex. retour depuis une pause).
	get_tree().paused = false
	if not _build():
		push_error("[FightScene] Combat impossible à construire, retour au menu.")
		SceneRouter.go_to(GameConstants.SCENE_MAIN_MENU)
		return
	if auto_start:
		_manager.start_match()


func get_manager() -> FightManager:
	return _manager


func _build() -> bool:
	stage = StageRegistry.instantiate_stage(GameSession.stage_id)
	if stage == null:
		return false
	_world.add_child(stage)
	var player_controller := PlayerController.new(GameSession.control_mode)
	player = _spawn_fighter(GameSession.player_fighter_id, GameConstants.SIDE_P1, player_controller)
	var ai := AIController.new(AIProfile.load_profile(GameSession.difficulty), randi())
	opponent = _spawn_fighter(GameSession.opponent_fighter_id, GameConstants.SIDE_P2, ai)
	if player == null or opponent == null:
		return false
	_manager.setup(player, opponent, stage)
	var targets: Array[Node2D] = [player, opponent]
	_camera.setup(targets, stage, _manager.simulation)
	_hud.bind(_manager)
	_manager.round_started.connect(_on_round_started)
	# Un doigt resté posé ne doit pas « coller » à la manche suivante.
	_manager.round_ended.connect(func(_winner: int, _reason: FightManager.RoundEndReason) -> void: _touch.release_all())
	_manager.simulation.combo_tracker.combo_finished.connect(_on_combo_finished)
	_manager.simulation.hit_confirmed.connect(_on_hit_confirmed)
	_manager.round_ended.connect(_on_round_ended_for_stage)
	_manager.match_ended.connect(_on_match_ended)
	_connect_pause()
	return true


func get_pause_menu() -> PauseMenu:
	return _pause


func _connect_pause() -> void:
	_pause.enabled = true
	_pause.opened.connect(_touch.release_all)
	_pause.restart_requested.connect(func() -> void: SceneRouter.go_to(GameConstants.SCENE_FIGHT))
	_pause.quit_requested.connect(func() -> void: SceneRouter.go_to(GameConstants.SCENE_MAIN_MENU))


## Le public et les néons réagissent aux coups qui portent (pas aux coups parés).
func _on_hit_confirmed(_attacker: Fighter, _defender: Fighter, move: MoveData, blocked: bool) -> void:
	if blocked:
		return
	var strength: float = float(move.damage) / STAGE_REACTION_FULL_DAMAGE
	if move.category == MoveData.Category.ULTIMATE:
		strength = 1.0
	stage.react_to_impact(strength)


func _on_round_ended_for_stage(_winner: int, reason: FightManager.RoundEndReason) -> void:
	if reason != FightManager.RoundEndReason.TIME_OUT:
		stage.react_to_impact(1.0)


func _on_combo_finished(side: int, hits: int, _damage: int) -> void:
	if side == GameConstants.SIDE_P1:
		_best_combo = maxi(_best_combo, hits)


## Fin du match : plus de pause possible, statistiques et progression sauvegardées.
func _on_match_ended(result: MatchResult) -> void:
	_pause.enabled = false
	_touch.release_all()
	SaveManager.record_match(result, GameSession.difficulty, _best_combo)


func get_touch_controls() -> TouchControls:
	return _touch


func _spawn_fighter(fighter_id: StringName, side: int, controller: FighterController) -> Fighter:
	var data: FighterData = FighterRegistry.load_fighter(fighter_id)
	if data == null:
		return null
	var fighter: Fighter = _instantiate(GameConstants.SCENE_FIGHTER) as Fighter
	if fighter == null:
		return null
	_world.add_child(fighter)
	if not fighter.setup(data, side, controller):
		return null
	return fighter


func _instantiate(path: String) -> Node:
	if not ResourceLoader.exists(path):
		push_error("[FightScene] Scène introuvable : %s" % path)
		return null
	var packed: PackedScene = load(path) as PackedScene
	if packed == null or not packed.can_instantiate():
		push_error("[FightScene] Scène invalide : %s" % path)
		return null
	return packed.instantiate()


func _on_round_started(_round_number: int) -> void:
	_camera.snap()
