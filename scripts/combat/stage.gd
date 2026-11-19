class_name Stage
extends Node2D
## Arène de combat : plan de combat stable (sol, murs invisibles, positions de départ)
## et limites de caméra. Le décor (couches de parallaxe) est porté par la scène de l'arène.
##
## Coordonnées : l'origine de l'arène est au centre du sol ; y négatif = vers le haut.

@export var display_name: String = ""
## Demi-largeur du plan de combat : les combattants ne dépassent jamais ±half_width.
@export var half_width: float = 1400.0
## Demi-largeur visible maximale (le décor doit couvrir au moins cette zone).
@export var camera_half_width: float = 1600.0
## Hauteur visible au-dessus du sol et profondeur visible sous le sol, pour la caméra.
@export var camera_top: float = -1400.0
@export var camera_bottom: float = 400.0
## Distance de chaque combattant au centre au début d'une manche.
@export var spawn_distance: float = 320.0

## Les éléments de décor de ce groupe exposent react(strength: float) (foule, néons, câbles).
const REACTIVE_GROUP: StringName = &"stage_reactive"

var _reactive: Array[Node] = []


func _ready() -> void:
	for node: Node in get_tree().get_nodes_in_group(REACTIVE_GROUP):
		if is_ancestor_of(node) and node.has_method(&"react"):
			_reactive.append(node)


## Fait réagir le décor à un impact (0 = rien, 1 = KO / ultime).
func react_to_impact(strength: float) -> void:
	var clamped: float = clampf(strength, 0.0, 1.0)
	for node: Node in _reactive:
		if is_instance_valid(node):
			node.call(&"react", clamped)


func get_reactive_count() -> int:
	return _reactive.size()


func get_floor_y() -> float:
	return global_position.y


func get_left_limit() -> float:
	return global_position.x - half_width


func get_right_limit() -> float:
	return global_position.x + half_width


## Position de départ d'un camp (GameConstants.SIDE_P1 à gauche, SIDE_P2 à droite).
func get_spawn_position(side: int) -> Vector2:
	var direction: float = -1.0 if side == GameConstants.SIDE_P1 else 1.0
	return Vector2(global_position.x + direction * spawn_distance, get_floor_y())


## Rectangle (coordonnées monde) que la caméra ne doit jamais dépasser.
func get_camera_bounds() -> Rect2:
	var origin: Vector2 = global_position
	return Rect2(
		origin.x - camera_half_width,
		origin.y + camera_top,
		camera_half_width * 2.0,
		camera_bottom - camera_top
	)
