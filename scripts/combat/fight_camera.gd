class_name FightCamera
extends Camera2D
## Caméra latérale du combat.
## - Suit le milieu des deux combattants, à hauteur fixe au-dessus du sol.
## - Zoom léger et progressif selon leur distance (jamais de saut d'échelle).
## - Reste dans les limites du décor de l'arène.
## - Tremble brièvement sur les impacts puissants non parés.
## La caméra est purement visuelle : elle n'influence jamais la simulation.

## Hauteur du centre de l'image au-dessus du sol (pixels monde).
@export var height_above_floor: float = 380.0
@export var zoom_near: float = 1.05
@export var zoom_far: float = 0.88
@export var near_distance: float = 300.0
@export var far_distance: float = 1300.0
## Vitesses de rattrapage (par seconde) : position, puis zoom (plus lent).
@export var follow_rate: float = 8.0
@export var zoom_rate: float = 2.0
## Seuil de dégâts déclenchant une secousse (les chutes en déclenchent toujours une).
@export var heavy_hit_damage: int = 90
@export var shake_strength: float = 14.0
@export var shake_duration: float = 0.2

var _targets: Array[Node2D] = []
var _stage: Stage = null
var _shake_time_left: float = 0.0
var _shake_amplitude: float = 0.0
# Graine fixe : la secousse est reproductible d'une partie à l'autre.
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func setup(targets: Array[Node2D], stage: Stage, simulation: CombatSimulation) -> void:
	_targets = targets
	_stage = stage
	_rng.seed = 1
	var bounds: Rect2 = stage.get_camera_bounds()
	limit_left = floori(bounds.position.x)
	limit_right = ceili(bounds.end.x)
	limit_top = floori(bounds.position.y)
	limit_bottom = ceili(bounds.end.y)
	simulation.hit_confirmed.connect(_on_hit_confirmed)
	snap()


## Place immédiatement la caméra sur sa cible (début de manche).
func snap() -> void:
	if _targets.is_empty():
		return
	global_position = _target_position()
	zoom = Vector2.ONE * _target_zoom()
	reset_smoothing()


func shake(amplitude: float = shake_strength) -> void:
	_shake_amplitude = maxf(_shake_amplitude if _shake_time_left > 0.0 else 0.0, amplitude)
	_shake_time_left = shake_duration


func _process(delta: float) -> void:
	if _targets.is_empty():
		return
	var follow: float = 1.0 - exp(-follow_rate * delta)
	var zoom_blend: float = 1.0 - exp(-zoom_rate * delta)
	global_position = global_position.lerp(_target_position(), follow)
	zoom = zoom.lerp(Vector2.ONE * _target_zoom(), zoom_blend)
	if _shake_time_left > 0.0:
		_shake_time_left -= delta
		var strength: float = _shake_amplitude * clampf(_shake_time_left / shake_duration, 0.0, 1.0)
		offset = Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * strength
	else:
		offset = Vector2.ZERO


func _target_position() -> Vector2:
	var center_x: float = 0.0
	for target: Node2D in _targets:
		center_x += target.global_position.x
	center_x /= _targets.size()
	return Vector2(center_x, _stage.get_floor_y() - height_above_floor)


func _target_zoom() -> float:
	if _targets.size() < 2:
		return zoom_near
	var distance: float = absf(_targets[0].global_position.x - _targets[1].global_position.x)
	var t: float = clampf(inverse_lerp(near_distance, far_distance, distance), 0.0, 1.0)
	return lerpf(zoom_near, zoom_far, t)


func _on_hit_confirmed(_attacker: Fighter, _defender: Fighter, move: MoveData, blocked: bool) -> void:
	if not blocked and (move.damage >= heavy_hit_damage or move.knockdown):
		shake()
