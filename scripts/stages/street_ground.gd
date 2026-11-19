@tool
class_name StreetGround
extends Node2D
## Sol du plan de combat : trottoir, bordure, chaussée, marquages et reflets des néons dans
## les flaques. L'origine (y = 0) est la ligne où se tiennent les combattants.

@export var span: Vector2 = Vector2(-2400.0, 2400.0)
@export var sidewalk_depth: float = 40.0
@export var road_depth: float = 460.0
@export var sidewalk_color: Color = Color("#3a2c40")
@export var curb_color: Color = Color("#e2a829")
@export var road_color: Color = Color("#1b1520")
@export var marking_color: Color = Color(0.96, 0.93, 0.86, 0.45)
@export var marking_y: float = 170.0
@export var puddle_colors: Array[Color] = [
	Color(1.0, 0.42, 0.1, 0.18), Color(0.22, 0.85, 0.54, 0.16), Color(0.85, 0.42, 1.0, 0.16),
]
@export var puddle_count: int = 8
@export var rng_seed: int = 12

const CURB_HEIGHT: float = 8.0
const TILE_STEP: float = 120.0
const TILE_LINE_ALPHA: float = 0.25
const DASH_SIZE: Vector2 = Vector2(90.0, 10.0)
const DASH_STEP: float = 220.0
const PUDDLE_RADIUS: Vector2 = Vector2(50.0, 130.0)
const PUDDLE_Y: Vector2 = Vector2(40.0, 130.0)
## Les flaques sont des ellipses très aplaties (vue rasante).
const PUDDLE_FLATTEN: float = 0.22


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var width: float = span.y - span.x
	draw_rect(Rect2(span.x, -sidewalk_depth, width, sidewalk_depth), sidewalk_color)
	var x: float = span.x
	while x < span.y:
		draw_line(Vector2(x, -sidewalk_depth), Vector2(x - 20.0, 0.0), Color(road_color, TILE_LINE_ALPHA), 2.0)
		x += TILE_STEP
	draw_rect(Rect2(span.x, 0.0, width, road_depth), road_color)
	draw_rect(Rect2(span.x, 0.0, width, CURB_HEIGHT), curb_color)
	x = span.x
	while x < span.y:
		draw_rect(Rect2(Vector2(x, marking_y), DASH_SIZE), marking_color)
		x += DASH_STEP
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	for i: int in puddle_count:
		var center := Vector2(rng.randf_range(span.x, span.y), rng.randf_range(PUDDLE_Y.x, PUDDLE_Y.y))
		draw_set_transform(center, 0.0, Vector2(1.0, PUDDLE_FLATTEN))
		draw_circle(Vector2.ZERO, rng.randf_range(PUDDLE_RADIUS.x, PUDDLE_RADIUS.y), puddle_colors[i % puddle_colors.size()])
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
