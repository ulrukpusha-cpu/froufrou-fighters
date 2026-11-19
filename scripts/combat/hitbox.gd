class_name Hitbox
extends Area2D
## Zone offensive. Activée uniquement pendant les frames que le MoveData lui attribue.
##
## Les impacts sont résolus par intersection de rectangles dans CombatSimulation (exact à la
## frame près, indépendant du pas physique). Couche et masque restent configurés pour le
## débogage (Débogage > Formes de collision visibles) et d'éventuelles requêtes physiques.
## Chaque instance possède sa propre forme : rien n'est partagé entre les deux combattants.

@onready var _shape_node: CollisionShape2D = $Shape

var _shape: RectangleShape2D = RectangleShape2D.new()
var _active: bool = true


func _ready() -> void:
	collision_layer = PhysicsLayers.HITBOX
	collision_mask = PhysicsLayers.HURTBOX
	monitoring = false
	monitorable = false
	_shape_node.shape = _shape
	deactivate()


## rect : relatif aux pieds du combattant tourné vers la droite (miroité par le parent).
func activate(rect: Rect2) -> void:
	if _shape.size != rect.size:
		_shape.size = rect.size
	_shape_node.position = rect.get_center()
	if not _active:
		_active = true
		_shape_node.disabled = false
		visible = true


func deactivate() -> void:
	if _active:
		_active = false
		_shape_node.disabled = true
		visible = false


func is_active() -> bool:
	return _active


func get_world_rect() -> Rect2:
	return _shape_node.global_transform * Rect2(-_shape.size * 0.5, _shape.size)
