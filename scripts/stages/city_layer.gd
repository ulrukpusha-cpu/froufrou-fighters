@tool
class_name CityLayer
extends Node2D
## Rangée d'immeubles générée : silhouettes, fenêtres allumées et feux d'antenne rouges
## qui clignotent sur les plus hautes tours. Graine fixe : le même skyline à chaque partie.
## La géométrie est dessinée une seule fois ; seuls les feux d'antenne s'animent.

@export var span: Vector2 = Vector2(-1800.0, 1800.0)
@export var base_y: float = 0.0
@export var width_range: Vector2 = Vector2(120.0, 240.0)
@export var height_range: Vector2 = Vector2(300.0, 800.0)
@export var gap_range: Vector2 = Vector2(0.0, 40.0)
@export var building_color: Color = Color("#1d0a2e")
@export var window_color: Color = Color("#f5d27a")
@export_range(0.0, 1.0) var window_density: float = 0.4
@export var window_size: Vector2 = Vector2(10.0, 14.0)
@export var window_spacing: Vector2 = Vector2(24.0, 32.0)
## Tours au-delà de cette hauteur : antenne et feu rouge clignotant.
@export var beacon_min_height: float = 700.0
@export var beacon_color: Color = Color("#ff3b30")
@export var rng_seed: int = 1

const WINDOW_MARGIN: Vector2 = Vector2(14.0, 20.0)
const ANTENNA_HEIGHT: float = 60.0
const ANTENNA_WIDTH: float = 3.0
const BEACON_RADIUS: float = 5.0
const BEACON_PERIOD: float = 1.4
## Légère variation de teinte entre immeubles (relief).
const SHADE_VARIATION: float = 0.08

var _buildings: Array[Rect2] = []
var _beacons: PackedVector2Array = PackedVector2Array()
var _beacon_layer: BeaconLayer = null


func _ready() -> void:
	_generate()
	if not Engine.is_editor_hint():
		_beacon_layer = BeaconLayer.new()
		_beacon_layer.points = _beacons
		_beacon_layer.color = beacon_color
		add_child(_beacon_layer)


func get_building_count() -> int:
	return _buildings.size()


func _generate() -> void:
	_buildings.clear()
	_beacons.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var x: float = span.x
	while x < span.y:
		var width: float = rng.randf_range(width_range.x, width_range.y)
		var height: float = rng.randf_range(height_range.x, height_range.y)
		_buildings.append(Rect2(x, base_y - height, width, height))
		if height >= beacon_min_height:
			_beacons.append(Vector2(x + width * 0.5, base_y - height - ANTENNA_HEIGHT))
		x += width + rng.randf_range(gap_range.x, gap_range.y)
	queue_redraw()


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed + 1
	for rect: Rect2 in _buildings:
		var shade: float = rng.randf_range(-SHADE_VARIATION, SHADE_VARIATION)
		draw_rect(rect, building_color.lightened(shade) if shade > 0.0 else building_color.darkened(-shade))
		_draw_windows(rect, rng)
		if rect.size.y >= beacon_min_height:
			var top := Vector2(rect.get_center().x, rect.position.y)
			draw_line(top, top - Vector2(0.0, ANTENNA_HEIGHT), building_color, ANTENNA_WIDTH)


func _draw_windows(rect: Rect2, rng: RandomNumberGenerator) -> void:
	var y: float = rect.position.y + WINDOW_MARGIN.y
	while y + window_size.y < rect.end.y - WINDOW_MARGIN.y:
		var x: float = rect.position.x + WINDOW_MARGIN.x
		while x + window_size.x < rect.end.x - WINDOW_MARGIN.x:
			if rng.randf() < window_density:
				draw_rect(Rect2(Vector2(x, y), window_size), window_color)
			x += window_spacing.x
		y += window_spacing.y


## Feux d'antenne : un nœud à part, pour clignoter sans redessiner les immeubles.
class BeaconLayer:
	extends Node2D

	var points: PackedVector2Array = PackedVector2Array()
	var color: Color = Color.RED
	var _time: float = 0.0

	func _process(delta: float) -> void:
		_time += delta
		modulate.a = 1.0 if fmod(_time, BEACON_PERIOD) < BEACON_PERIOD * 0.5 else 0.15

	func _draw() -> void:
		for point: Vector2 in points:
			draw_circle(point, BEACON_RADIUS * 2.2, Color(color, 0.25))
			draw_circle(point, BEACON_RADIUS, color)
