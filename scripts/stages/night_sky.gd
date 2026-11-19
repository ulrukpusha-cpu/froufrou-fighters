@tool
class_name NightSky
extends Node2D
## Ciel du soir sur le Plateau : dégradé violet profond → orange brûlé à l'horizon,
## étoiles et lune avec halo. Dessiné une seule fois (aucun coût par frame).

@export var span: Vector2 = Vector2(-2400.0, 2400.0)
@export var top_y: float = -1700.0
@export var horizon_y: float = 0.0
@export var zenith_color: Color = Color("#0e0420")
@export var mid_color: Color = Color("#3a1257")
@export var horizon_color: Color = Color("#d0581a")
## Part du ciel (depuis le haut) occupée par le dégradé zénith → violet.
@export_range(0.1, 0.9) var mid_ratio: float = 0.62
@export var moon_position: Vector2 = Vector2(560.0, -1080.0)
@export var moon_radius: float = 46.0
@export var moon_color: Color = Color("#f5eedc")
@export var star_count: int = 70
@export var rng_seed: int = 9

const MOON_GLOW_LAYERS: int = 4
const MOON_GLOW_ALPHA: float = 0.06
const STAR_RADIUS: Vector2 = Vector2(1.2, 2.8)
const STAR_ALPHA: Vector2 = Vector2(0.35, 0.9)


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var mid_y: float = lerpf(top_y, horizon_y, mid_ratio)
	_band(top_y, mid_y, zenith_color, mid_color)
	_band(mid_y, horizon_y, mid_color, horizon_color)
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	for i: int in star_count:
		var star := Vector2(rng.randf_range(span.x, span.y), rng.randf_range(top_y, mid_y))
		draw_circle(star, rng.randf_range(STAR_RADIUS.x, STAR_RADIUS.y),
			Color(moon_color, rng.randf_range(STAR_ALPHA.x, STAR_ALPHA.y)))
	for layer: int in MOON_GLOW_LAYERS:
		draw_circle(moon_position, moon_radius * (1.0 + 0.4 * (layer + 1)), Color(moon_color, MOON_GLOW_ALPHA))
	draw_circle(moon_position, moon_radius, moon_color)


func _band(y_from: float, y_to: float, color_from: Color, color_to: Color) -> void:
	var points := PackedVector2Array([
		Vector2(span.x, y_from), Vector2(span.y, y_from), Vector2(span.y, y_to), Vector2(span.x, y_to),
	])
	draw_polygon(points, PackedColorArray([color_from, color_from, color_to, color_to]))
