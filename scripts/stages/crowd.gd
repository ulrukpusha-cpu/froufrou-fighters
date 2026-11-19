@tool
class_name Crowd
extends Node2D
## Public en silhouettes au premier plan : il se balance doucement, puis se lève et lève
## les bras quand un gros coup porte (react). L'excitation retombe progressivement.

@export var span: Vector2 = Vector2(-2300.0, 2300.0)
## Ligne des épaules (le bas des silhouettes sort de l'écran).
@export var base_y: float = 150.0
@export var spacing: float = 64.0
@export var silhouette_color: Color = Color("#0b0510")
@export var rim_color: Color = Color("#cc5500")
@export var rng_seed: int = 5
## Vitesse à laquelle l'excitation retombe (par seconde).
@export var calm_rate: float = 1.6

const HEAD_RADIUS: Vector2 = Vector2(15.0, 21.0)
const SHOULDER_WIDTH: Vector2 = Vector2(46.0, 66.0)
const SHOULDER_HEIGHT: float = 70.0
const NECK_GAP: float = 6.0
const IDLE_BOB: float = 3.0
const EXCITED_BOB: float = 16.0
const BOB_SPEED: Vector2 = Vector2(1.6, 3.2)
const EXCITED_SPEED_BONUS: float = 3.0
const ARM_LENGTH: float = 64.0
const ARM_WIDTH: float = 11.0
## Au-delà de ce niveau d'excitation, une partie du public lève les bras.
const ARMS_UP_THRESHOLD: float = 0.35
const RIM_WIDTH: float = 3.0

var excitement: float = 0.0

var _x: PackedFloat32Array = PackedFloat32Array()
var _head: PackedFloat32Array = PackedFloat32Array()
var _shoulders: PackedFloat32Array = PackedFloat32Array()
var _phase: PackedFloat32Array = PackedFloat32Array()
var _speed: PackedFloat32Array = PackedFloat32Array()
var _time: float = 0.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var x: float = span.x
	while x < span.y:
		_x.append(x + rng.randf_range(-spacing * 0.25, spacing * 0.25))
		_head.append(rng.randf_range(HEAD_RADIUS.x, HEAD_RADIUS.y))
		_shoulders.append(rng.randf_range(SHOULDER_WIDTH.x, SHOULDER_WIDTH.y))
		_phase.append(rng.randf_range(0.0, TAU))
		_speed.append(rng.randf_range(BOB_SPEED.x, BOB_SPEED.y))
		x += spacing
	if not Engine.is_editor_hint():
		add_to_group(Stage.REACTIVE_GROUP)
	queue_redraw()


func react(strength: float) -> void:
	excitement = clampf(excitement + strength, 0.0, 1.0)


func get_person_count() -> int:
	return _x.size()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	advance(delta)


func advance(delta: float) -> void:
	_time += delta
	excitement = maxf(excitement - calm_rate * delta * excitement - 0.05 * delta, 0.0)
	queue_redraw()


func _draw() -> void:
	var amplitude: float = lerpf(IDLE_BOB, EXCITED_BOB, excitement)
	for i: int in _x.size():
		var speed: float = _speed[i] + EXCITED_SPEED_BONUS * excitement
		var bob: float = absf(sin(_time * speed + _phase[i])) * amplitude
		var shoulders := Vector2(_x[i], base_y - bob)
		var head := shoulders - Vector2(0.0, _head[i] + NECK_GAP)
		if excitement > ARMS_UP_THRESHOLD and fmod(_phase[i], 1.0) < excitement:
			for side: float in [-1.0, 1.0]:
				var shoulder := shoulders + Vector2(side * _shoulders[i] * 0.4, 4.0)
				var hand := shoulder + Vector2(side * 18.0, -ARM_LENGTH)
				draw_line(shoulder, hand, silhouette_color, ARM_WIDTH)
				draw_circle(hand, ARM_WIDTH * 0.6, silhouette_color)
		var body := Rect2(shoulders.x - _shoulders[i] * 0.5, shoulders.y, _shoulders[i], SHOULDER_HEIGHT)
		draw_rect(body, silhouette_color)
		draw_circle(Vector2(body.get_center().x, body.position.y), _shoulders[i] * 0.5, silhouette_color)
		draw_circle(head, _head[i], silhouette_color)
		draw_arc(head, _head[i], PI * 1.1, PI * 1.9, 10, Color(rim_color, 0.7), RIM_WIDTH)
