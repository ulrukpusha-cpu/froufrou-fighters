class_name TouchActionButton
extends Control
## Bouton tactile rond lié à une action logique (Poing, Pied, Spécial, Garde, Esquive).
##
## Il presse l'action tant que SON doigt reste posé (suivi par index de toucher) : plusieurs
## boutons peuvent être tenus en même temps (Poing + Pied = projection). Les événements sont
## lus dans _input() car la GUI ne gère qu'un seul pointeur à la fois.

signal pressed_changed(is_down: bool)

const NO_TOUCH: int = -1
const RING_WIDTH: float = 6.0
## Zone de contact légèrement plus grande que le dessin (doigts imprécis).
const HIT_SLOP: float = 1.12

@export var action: StringName = InputActions.PUNCH
@export var label: String = "POING"
@export var fill_color: Color = UIPalette.DEEP_VIOLET
@export var font_size: int = 30
@export_range(0.0, 1.0) var idle_alpha: float = 0.55
@export_range(0.0, 1.0) var pressed_alpha: float = 0.95

var _touch_index: int = NO_TOUCH
var _is_down: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visibility_changed.connect(_on_visibility_changed)


func _exit_tree() -> void:
	release()


func is_down() -> bool:
	return _is_down


func get_radius() -> float:
	return minf(size.x, size.y) * 0.5


func get_global_center() -> Vector2:
	return global_position + size * 0.5


func contains_point(global_point: Vector2) -> bool:
	return global_point.distance_to(get_global_center()) <= get_radius() * HIT_SLOP


func release() -> void:
	_touch_index = NO_TOUCH
	_set_down(false)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var touch: InputEventScreenTouch = event as InputEventScreenTouch
	if touch == null:
		return
	if touch.pressed and _touch_index == NO_TOUCH and contains_point(touch.position):
		_touch_index = touch.index
		_set_down(true)
		get_viewport().set_input_as_handled()
	elif not touch.pressed and touch.index == _touch_index:
		release()
		get_viewport().set_input_as_handled()


func _set_down(down: bool) -> void:
	if down == _is_down:
		return
	_is_down = down
	if down:
		Input.action_press(action)
	else:
		Input.action_release(action)
	pressed_changed.emit(down)
	queue_redraw()


func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		release()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = get_radius()
	var fill: Color = UIPalette.GOLD if _is_down else fill_color
	fill.a = pressed_alpha if _is_down else idle_alpha
	var ring: Color = UIPalette.IVORY if _is_down else UIPalette.GOLD
	draw_circle(center, radius, fill)
	draw_arc(center, radius - RING_WIDTH * 0.5, 0.0, TAU, 64, ring, RING_WIDTH, true)
	var font: Font = get_theme_default_font()
	var text_color: Color = UIPalette.CHARCOAL if _is_down else UIPalette.IVORY
	var text_size: Vector2 = font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var baseline := Vector2(center.x - text_size.x * 0.5, center.y + font.get_ascent(font_size) * 0.5 - font.get_descent(font_size) * 0.5)
	draw_string(font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
