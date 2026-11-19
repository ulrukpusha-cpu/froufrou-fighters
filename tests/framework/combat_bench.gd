class_name CombatBench
extends RefCounted
## Banc d'essai de combat headless : une arène, deux combattants pilotés par des
## ScriptedController, et une CombatSimulation avancée frame par frame par le test.

const STAGE_SCENE: String = "res://scenes/stages/abidjan_stage.tscn"
const FIGHTER_SCENE: String = "res://scenes/characters/fighter.tscn"

var root: Node2D
var stage: Stage
var p1: Fighter
var p2: Fighter
var p1_input: ScriptedController = ScriptedController.new()
var p2_input: ScriptedController = ScriptedController.new()
var simulation: CombatSimulation = CombatSimulation.new()
## Impacts confirmés : [attaquant, défenseur, attaque, paré].
var hits: Array[Array] = []


## Construit le banc sous « parent ». distance = écart initial entre les combattants.
func build(parent: Node, p1_id: StringName, p2_id: StringName, distance: float) -> bool:
	root = Node2D.new()
	root.name = "CombatBench"
	parent.add_child(root)
	stage = (load(STAGE_SCENE) as PackedScene).instantiate() as Stage
	root.add_child(stage)
	p1 = _spawn(p1_id, GameConstants.SIDE_P1, p1_input)
	p2 = _spawn(p2_id, GameConstants.SIDE_P2, p2_input)
	if p1 == null or p2 == null:
		return false
	simulation.setup(p1, p2, stage)
	simulation.hit_confirmed.connect(_on_hit)
	p1.reset_for_round(Vector2(-distance * 0.5, stage.get_floor_y()))
	p2.reset_for_round(Vector2(distance * 0.5, stage.get_floor_y()))
	p1.face_opponent()
	p2.face_opponent()
	p1.input_enabled = true
	p2.input_enabled = true
	return true


## Remplace le contrôleur d'un camp (ex. une IA à la place du script).
func set_controller(side: int, controller: FighterController) -> void:
	var fighter: Fighter = p1 if side == GameConstants.SIDE_P1 else p2
	fighter.add_child(controller)
	fighter.controller = controller


func step(frames: int = 1) -> void:
	for i: int in frames:
		simulation.step()


## Avance jusqu'à ce que condition.call() soit vrai (au plus max_frames). Retourne le résultat.
func step_until(condition: Callable, max_frames: int) -> bool:
	for i: int in max_frames:
		if condition.call():
			return true
		simulation.step()
	return condition.call()


func free_bench() -> void:
	if root != null:
		root.queue_free()
	# Contrôleurs jamais rattachés à un combattant (banc non construit) : libérés à la main,
	# sinon ces nœuds hors de l'arbre fuiraient.
	for controller: FighterController in [p1_input, p2_input]:
		if is_instance_valid(controller) and not controller.is_inside_tree():
			controller.free()


func _spawn(fighter_id: StringName, side: int, controller: FighterController) -> Fighter:
	var data: FighterData = FighterRegistry.load_fighter(fighter_id)
	var fighter: Fighter = (load(FIGHTER_SCENE) as PackedScene).instantiate() as Fighter
	root.add_child(fighter)
	if not fighter.setup(data, side, controller):
		return null
	return fighter


func _on_hit(attacker: Fighter, defender: Fighter, move: MoveData, blocked: bool) -> void:
	hits.append([attacker, defender, move, blocked])
