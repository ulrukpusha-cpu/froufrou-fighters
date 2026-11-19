@tool
class_name ShopRow
extends Node2D
## Rez-de-chaussée commerçant de la rue : façades, vitrines éclairées, portes, étage avec
## fenêtres et auvents rayés aux couleurs orange / blanc / vert. Les enseignes sont des
## NeonSign placés au-dessus de chaque boutique. Dessiné une seule fois.

@export var start_x: float = -2050.0
@export var shop_count: int = 10
@export var shop_width: float = 400.0
@export var gap: float = 24.0
@export var base_y: float = -10.0
@export var height: float = 440.0
@export var wall_colors: Array[Color] = [Color("#2b1838"), Color("#3a2030"), Color("#22162e"), Color("#33222c")]
@export var awning_colors: Array[Color] = [Color("#f07c1c"), Color("#f5eedc"), Color("#1fa863")]
@export var window_light: Color = Color("#ffcf7a")

const SHOP_WINDOW_HEIGHT: float = 160.0
const SHOP_WINDOW_BOTTOM: float = 40.0
const DOOR_SIZE: Vector2 = Vector2(78.0, 210.0)
const AWNING_TOP: float = 262.0
const AWNING_DEPTH: float = 44.0
const AWNING_OVERHANG: float = 14.0
const STRIPE_WIDTH: float = 40.0
const UPPER_WINDOW_SIZE: Vector2 = Vector2(60.0, 50.0)
const UPPER_WINDOW_Y: float = 400.0
const MULLION_STEP: float = 70.0
const DARK: Color = Color("#120a18")


func _ready() -> void:
	queue_redraw()


func get_shop_center_x(index: int) -> float:
	return start_x + index * (shop_width + gap) + shop_width * 0.5


func _draw() -> void:
	for i: int in shop_count:
		var x: float = start_x + i * (shop_width + gap)
		draw_rect(Rect2(x, base_y - height, shop_width, height), wall_colors[i % wall_colors.size()])
		_draw_upper_windows(x, i)
		var window_rect := Rect2(x + 24.0, base_y - SHOP_WINDOW_BOTTOM - SHOP_WINDOW_HEIGHT,
			shop_width - DOOR_SIZE.x - 64.0, SHOP_WINDOW_HEIGHT)
		draw_rect(window_rect, Color(window_light, 0.85))
		var mullion: float = window_rect.position.x + MULLION_STEP
		while mullion < window_rect.end.x:
			draw_line(Vector2(mullion, window_rect.position.y), Vector2(mullion, window_rect.end.y), DARK, 3.0)
			mullion += MULLION_STEP
		var door := Rect2(x + shop_width - DOOR_SIZE.x - 24.0, base_y - DOOR_SIZE.y, DOOR_SIZE.x, DOOR_SIZE.y)
		draw_rect(door, DARK)
		draw_rect(Rect2(door.position, Vector2(door.size.x, 16.0)), Color(window_light, 0.6))
		_draw_awning(x)


func _draw_upper_windows(x: float, index: int) -> void:
	for slot: int in 3:
		var lit: bool = (index + slot) % 3 != 0
		var rect := Rect2(x + 40.0 + slot * (shop_width - 80.0 - UPPER_WINDOW_SIZE.x) * 0.5,
			base_y - UPPER_WINDOW_Y, UPPER_WINDOW_SIZE.x, UPPER_WINDOW_SIZE.y)
		draw_rect(rect, Color(window_light, 0.7) if lit else DARK)


## Auvent en trapèze, rayé, légèrement plus large que la façade.
func _draw_awning(x: float) -> void:
	var top: float = base_y - AWNING_TOP
	var bottom: float = top + AWNING_DEPTH
	var left: float = x - AWNING_OVERHANG
	var right: float = x + shop_width + AWNING_OVERHANG
	var stripe: int = 0
	var sx: float = left
	while sx < right:
		var ex: float = minf(sx + STRIPE_WIDTH, right)
		var color: Color = awning_colors[stripe % awning_colors.size()]
		draw_colored_polygon(PackedVector2Array([
			Vector2(sx + AWNING_OVERHANG * 0.5, top), Vector2(ex + AWNING_OVERHANG * 0.5, top),
			Vector2(ex, bottom), Vector2(sx, bottom),
		]), color)
		sx = ex
		stripe += 1
	draw_line(Vector2(left, bottom), Vector2(right, bottom), DARK, 4.0)
