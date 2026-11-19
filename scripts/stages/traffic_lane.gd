@tool
class_name TrafficLane
extends Node2D
## Voie de circulation : un petit parc de voitures (surtout des taxis orange) qui défilent
## en boucle. Animation purement visuelle, sans lien avec la simulation du combat.
## Les voitures sont créées une fois (pas d'allocation pendant le combat).

@export var span: Vector2 = Vector2(-2100.0, 2100.0)
## 1 = vers la droite, -1 = vers la gauche.
@export var direction: int = 1
@export var car_count: int = 4
@export var speed_range: Vector2 = Vector2(260.0, 420.0)
@export_range(0.0, 1.0) var taxi_ratio: float = 0.65
@export var car_scale: float = 0.6
@export var rng_seed: int = 3

const TAXI_COLOR: Color = Color("#f07c1c")
const OTHER_CAR_COLORS: Array[Color] = [Color("#5b6c8a"), Color("#d9d2c0"), Color("#2e7d4f"), Color("#8a2b2b")]

var _cars: Array[Taxi] = []
var _speeds: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	for i: int in car_count:
		var car := Taxi.new()
		car.is_taxi = rng.randf() < taxi_ratio
		car.body_color = TAXI_COLOR if car.is_taxi else OTHER_CAR_COLORS[rng.randi_range(0, OTHER_CAR_COLORS.size() - 1)]
		car.scale = Vector2(direction * car_scale, car_scale)
		var slot: float = (float(i) + rng.randf() * 0.6) / maxf(car_count, 1)
		car.position = Vector2(lerpf(span.x, span.y, slot), 0.0)
		add_child(car)
		_cars.append(car)
		_speeds.append(rng.randf_range(speed_range.x, speed_range.y))


func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		advance(delta)


## Fait avancer le trafic de « delta » secondes (boucle d'un bout à l'autre de la voie).
func advance(delta: float) -> void:
	var length: float = span.y - span.x
	for i: int in _cars.size():
		var car: Taxi = _cars[i]
		car.position.x += direction * _speeds[i] * delta
		if direction > 0 and car.position.x > span.y:
			car.position.x -= length
		elif direction < 0 and car.position.x < span.x:
			car.position.x += length


func get_cars() -> Array[Taxi]:
	return _cars
