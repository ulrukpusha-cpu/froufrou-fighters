class_name TouchJoystick
extends Control
## Joystick virtuel flottant : le pouce posé n'importe où dans la zone devient le centre.
##
## Il ne connaît pas le combat : il presse et relâche les actions logiques de InputActions
## (directions), exactement comme le clavier ou une manette. Il suit un seul doigt (son index
## de toucher), les autres doigts restent libres pour les boutons (multi-touch).
## Les événements sont lus dans _input() : la GUI ne gère qu'un seul pointeur à la fois.

signal direction_changed(direction: Vector2i)

## Rayon de débattement et rayon du bouton central, en unités d'interface.
@export var radius: float = 130.0
@export var knob_radius: float = 58.0
## Seuils, en fraction du rayon. Le saut demande un geste plus franc que l'accroupi
## pour éviter les sauts involontaires.
@export_range(0.0, 1.0) var horizontal_threshold: float = 0.35
@export_range(0.0, 1.0) var down_threshold: float = 0.45
@export_range(0.0, 1.0) var up_threshold: float = 0.55
@export_range(0.0, 1.0) var idle_alpha: float = 0.35
@export_range(0.0, 1.0) var active_alpha: float = 0.85

const NO_TOUCH: int = -1
const RING_WIDTH: float = 6.0
const DIRECTION_ACTIONS: Dictionary = {
	Vector2i.LEFT: InputActions.MOVE_LEFT,
	Vector2i.RIGHT: InputActions.MOVE_RIGHT,
	Vector2i.UP: InputActions.MOVE_UP,
	Vector2i.DOWN: InputActions.MOVE_DOWN,
}

var _touch_index: int = NO_TOUCH
var _center: Vector2 = Vector2.ZERO
var _knob_offset: Vector2 = Vector2.ZERO
var _direction: Vector2i = Vector2i.ZERO
## Actions pressées par CE joystick (on ne relâche jamais celles d'un autre périphérique).
var _pressed_actions: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_reset_center)
	visibility_changed.connect(_on_visibility_changed)
	_reset_center()


func _exit_tree() -> void:
	release()


func get_direction() -> Vector2i:
	return _direction


func is_active() -> bool:
	return _touch_index != NO_TOUCH


## Direction numérique (-1 / 0 / 1 par axe) pour un débattement normalisé (longueur <= 1).
func compute_direction(normalized: Vector2) -> Vector2i:
	var result := Vector2i.ZERO
	if normalized.x > horizontal_threshold:
		result.x = 1
	elif normalized.x < -horizontal_threshold:
		result.x = -1
	if normalized.y < -up_threshold:
		result.y = -1
	elif normalized.y > down_threshold:
		result.y = 1
	return result


## Relâche le joystick et toutes les actions qu'il maintenait.
func release() -> void:
	_touch_index = NO_TOUCH
	_knob_offset = Vector2.ZERO
	_set_direction(Vector2i.ZERO)
	_reset_center()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var touch: InputEventScreenTouch = event as InputEventScreenTouch
	if touch != null:
		if touch.pressed and _touch_index == NO_TOUCH and get_global_rect().has_point(touch.position):
			_touch_index = touch.index
			_center = _clamp_center(touch.position - global_position)
			_update_knob(touch.position)
			get_viewport().set_input_as_handled()
		elif not touch.pressed and touch.index == _touch_index:
			release()
			get_viewport().set_input_as_handled()
		return
	var drag: InputEventScreenDrag = event as InputEventScreenDrag
	if drag != null and drag.index == _touch_index:
		_update_knob(drag.position)
		get_viewport().set_input_as_handled()


func _update_knob(global_point: Vector2) -> void:
	_knob_offset = (global_point - global_position - _center).limit_length(radius)
	_set_direction(compute_direction(_knob_offset / radius))
	queue_redraw()


func _set_direction(direction: Vector2i) -> void:
	if direction == _direction:
		return
	_direction = direction
	_set_action(Vector2i.LEFT, direction.x < 0)
	_set_action(Vector2i.RIGHT, direction.x > 0)
	_set_action(Vector2i.UP, direction.y < 0)
	_set_action(Vector2i.DOWN, direction.y > 0)
	direction_changed.emit(direction)
	queue_redraw()


func _set_action(key: Vector2i, active: bool) -> void:
	var action: StringName = DIRECTION_ACTIONS[key]
	if active and not _pressed_actions.has(action):
		_pressed_actions[action] = true
		Input.action_press(action)
	elif not active and _pressed_actions.has(action):
		_pressed_actions.erase(action)
		Input.action_release(action)


## Position de repos : en bas à gauche de la zone, le socle entièrement visible.
func _reset_center() -> void:
	_center = Vector2(radius + knob_radius, size.y - radius - knob_radius)
	queue_redraw()


## Le socle reste entièrement dans la zone, même si le pouce se pose au bord.
func _clamp_center(local_point: Vector2) -> Vector2:
	var margin: float = radius * 0.5
	return Vector2(
		clampf(local_point.x, margin, maxf(size.x - margin, margin)),
		clampf(local_point.y, margin, maxf(size.y - margin, margin))
	)


func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		release()


func _draw() -> void:
	var alpha: float = active_alpha if is_active() else idle_alpha
	var base_color: Color = UIPalette.VIOLET_SHADOW
	base_color.a = alpha
	var ring_color: Color = UIPalette.GOLD
	ring_color.a = alpha
	var knob_color: Color = UIPalette.BURNT_ORANGE if _direction != Vector2i.ZERO else UIPalette.IVORY
	knob_color.a = alpha
	draw_circle(_center, radius, base_color)
	draw_arc(_center, radius, 0.0, TAU, 64, ring_color, RING_WIDTH, true)
	draw_circle(_center + _knob_offset, knob_radius, knob_color)
