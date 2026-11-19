@tool
class_name StreetLamp
extends Node2D
## Lampadaire : mât, crosse, lanterne, halo chaud et cône de lumière vers le sol.
## Origine = pied du mât. Dessiné une seule fois.

@export var height: float = 520.0
@export var arm_length: float = 90.0
## 1 = crosse vers la droite, -1 = vers la gauche.
@export var facing: int = 1
@export var pole_color: Color = Color("#140a1c")
@export var light_color: Color = Color("#ffd27a")
@export var glow_radius: float = 120.0
## Largeur de la tache de lumière au sol.
@export var cone_width: float = 320.0

const POLE_WIDTH: float = 12.0
const ARM_WIDTH: float = 8.0
const HEAD_SIZE: Vector2 = Vector2(46.0, 16.0)
const GLOW_LAYERS: int = 4
const GLOW_ALPHA: float = 0.07
const CONE_ALPHA: float = 0.1
const BULB_RADIUS: float = 9.0


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-POLE_WIDTH * 0.5, -height, POLE_WIDTH, height), pole_color)
	var lamp := Vector2(arm_length * facing, -height - 12.0)
	draw_line(Vector2(0.0, -height), lamp, pole_color, ARM_WIDTH)
	draw_rect(Rect2(lamp - Vector2(HEAD_SIZE.x * 0.5, 0.0), HEAD_SIZE), pole_color)
	var bulb: Vector2 = lamp + Vector2(0.0, HEAD_SIZE.y + 2.0)
	var cone := PackedVector2Array([
		bulb + Vector2(-14.0, 0.0), bulb + Vector2(14.0, 0.0),
		Vector2(lamp.x + cone_width * 0.5, 0.0), Vector2(lamp.x - cone_width * 0.5, 0.0),
	])
	var lit := Color(light_color, CONE_ALPHA)
	draw_polygon(cone, PackedColorArray([lit, lit, Color(light_color, 0.0), Color(light_color, 0.0)]))
	for layer: int in GLOW_LAYERS:
		draw_circle(bulb, glow_radius * (1.0 - layer * 0.22), Color(light_color, GLOW_ALPHA))
	draw_circle(bulb, BULB_RADIUS, light_color.lightened(0.4))
