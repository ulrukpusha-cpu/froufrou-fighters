@tool
class_name Taxi
extends Node2D
## Voiture vue de profil, dessinée par code : taxi orange d'Abidjan (lumineux sur le toit)
## ou voiture banale. Origine = sol, sous le milieu de la voiture ; tournée vers la droite
## (scale.x négatif pour rouler vers la gauche).

@export var body_color: Color = Color("#f07c1c")
@export var is_taxi: bool = true

const BODY: PackedVector2Array = [
	Vector2(-96, -24), Vector2(96, -24), Vector2(98, -58), Vector2(72, -64),
	Vector2(42, -98), Vector2(-50, -98), Vector2(-80, -64), Vector2(-98, -58),
]
const REAR_WINDOW: PackedVector2Array = [Vector2(-44, -92), Vector2(-4, -92), Vector2(-4, -68), Vector2(-68, -68)]
const FRONT_WINDOW: PackedVector2Array = [Vector2(4, -92), Vector2(38, -92), Vector2(62, -68), Vector2(4, -68)]
const WINDOW_COLOR: Color = Color("#2a1f3a")
const WHEEL_COLOR: Color = Color("#100a14")
const HUB_COLOR: Color = Color("#8a8296")
const HEADLIGHT_COLOR: Color = Color("#fff1b8")
const TAIL_COLOR: Color = Color("#ff3b30")
const ROOF_SIGN_COLOR: Color = Color("#f5eedc")
const WHEEL_RADIUS: float = 18.0
const HUB_RADIUS: float = 7.0
const WHEEL_X: float = 58.0


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_colored_polygon(BODY, body_color)
	draw_colored_polygon(REAR_WINDOW, WINDOW_COLOR)
	draw_colored_polygon(FRONT_WINDOW, WINDOW_COLOR)
	draw_line(Vector2(-96, -42), Vector2(96, -42), body_color.darkened(0.25), 3.0)
	for x: float in [-WHEEL_X, WHEEL_X]:
		draw_circle(Vector2(x, -WHEEL_RADIUS), WHEEL_RADIUS, WHEEL_COLOR)
		draw_circle(Vector2(x, -WHEEL_RADIUS), HUB_RADIUS, HUB_COLOR)
	draw_circle(Vector2(96, -50), 20.0, Color(HEADLIGHT_COLOR, 0.18))
	draw_circle(Vector2(95, -50), 6.0, HEADLIGHT_COLOR)
	draw_rect(Rect2(-99, -54, 6, 12), TAIL_COLOR)
	if is_taxi:
		draw_rect(Rect2(-20, -110, 40, 12), ROOF_SIGN_COLOR)
		draw_rect(Rect2(-20, -110, 40, 12), Color(ROOF_SIGN_COLOR, 0.25).lightened(0.3), false, 6.0)
