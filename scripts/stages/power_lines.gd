@tool
class_name PowerLines
extends Node2D
## Poteaux et câbles électriques au-dessus de la rue : le « Plateau Électrique ».
## Une gerbe d'étincelles jaillit d'un poteau sur les gros impacts (react).

@export var pole_x: PackedFloat32Array = PackedFloat32Array([-2000.0, -1250.0, -500.0, 250.0, 1000.0, 1750.0])
@export var ground_y: float = 0.0
@export var top_y: float = -640.0
@export var wire_count: int = 3
@export var wire_spacing: float = 22.0
@export var sag: float = 70.0
@export var wire_color: Color = Color("#0c0612")
@export var spark_color: Color = Color("#fff3b0")
@export var rng_seed: int = 21

const POLE_WIDTH: float = 10.0
const CROSSARM_WIDTH: float = 90.0
const WIRE_SEGMENTS: int = 16
const WIRE_WIDTH: float = 2.5
## Seules les secousses assez fortes provoquent des étincelles.
const SPARK_THRESHOLD: float = 0.5
const SPARK_DURATION: float = 0.3
const SPARK_RAYS: int = 9
const SPARK_LENGTH: Vector2 = Vector2(18.0, 60.0)

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _spark_time: float = 0.0
var _spark_pole: int = 0


func _ready() -> void:
	_rng.seed = rng_seed
	if not Engine.is_editor_hint():
		add_to_group(Stage.REACTIVE_GROUP)
	queue_redraw()


func react(strength: float) -> void:
	if strength < SPARK_THRESHOLD or pole_x.is_empty():
		return
	_spark_pole = _rng.randi_range(0, pole_x.size() - 1)
	_spark_time = SPARK_DURATION
	queue_redraw()


func is_sparking() -> bool:
	return _spark_time > 0.0


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _spark_time <= 0.0:
		return
	_spark_time -= delta
	queue_redraw()


func _draw() -> void:
	for x: float in pole_x:
		draw_rect(Rect2(x - POLE_WIDTH * 0.5, top_y, POLE_WIDTH, ground_y - top_y), wire_color)
		draw_line(Vector2(x - CROSSARM_WIDTH * 0.5, top_y + 10.0), Vector2(x + CROSSARM_WIDTH * 0.5, top_y + 10.0), wire_color, 6.0)
	for index: int in range(pole_x.size() - 1):
		for wire: int in wire_count:
			_draw_wire(pole_x[index], pole_x[index + 1], top_y + 10.0 + wire * wire_spacing)
	if _spark_time > 0.0:
		_draw_spark(Vector2(pole_x[_spark_pole], top_y + 10.0))


## Câble affaissé (parabole) entre deux poteaux.
func _draw_wire(from_x: float, to_x: float, y: float) -> void:
	var points := PackedVector2Array()
	for step: int in WIRE_SEGMENTS + 1:
		var t: float = float(step) / WIRE_SEGMENTS
		points.append(Vector2(lerpf(from_x, to_x, t), y + sag * 4.0 * t * (1.0 - t)))
	draw_polyline(points, wire_color, WIRE_WIDTH, true)


func _draw_spark(origin: Vector2) -> void:
	var intensity: float = _spark_time / SPARK_DURATION
	draw_circle(origin, 40.0 * intensity, Color(spark_color, 0.35 * intensity))
	for ray: int in SPARK_RAYS:
		var angle: float = _rng.randf_range(0.0, TAU)
		var length: float = _rng.randf_range(SPARK_LENGTH.x, SPARK_LENGTH.y) * intensity
		draw_line(origin, origin + Vector2.from_angle(angle) * length, spark_color, 3.0)
