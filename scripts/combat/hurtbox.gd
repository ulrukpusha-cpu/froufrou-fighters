class_name Hurtbox
extends Area2D
## Zone vulnérable d'un combattant (debout ou accroupi), désactivée pendant
## l'invulnérabilité (esquive, chute, relevé). Voir Hitbox pour la méthode de détection.

@onready var _shape_node: CollisionShape2D = $Shape

var _shape: RectangleShape2D = RectangleShape2D.new()
var _rect: Rect2 = Rect2()
var _enabled: bool = true


func _ready() -> void:
	collision_layer = PhysicsLayers.HURTBOX
	collision_mask = 0
	monitoring = false
	monitorable = false
	_shape_node.shape = _shape


func set_rect(rect: Rect2) -> void:
	if rect == _rect:
		return
	_rect = rect
	_shape.size = rect.size
	_shape_node.position = rect.get_center()


func set_enabled(enabled: bool) -> void:
	if enabled != _enabled:
		_enabled = enabled
		_shape_node.disabled = not enabled


func is_enabled() -> bool:
	return _enabled


func get_world_rect() -> Rect2:
	return _shape_node.global_transform * Rect2(-_shape.size * 0.5, _shape.size)
