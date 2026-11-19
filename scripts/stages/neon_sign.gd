@tool
class_name NeonSign
extends Node2D
## Enseigne néon (fond sombre, cadre et texte lumineux avec halo) qui grésille de temps en
## temps, et franchement quand le combat s'emballe (react). Le grésillement ne touche que
## la transparence : l'enseigne n'est dessinée qu'une fois.

@export var text: String = "MAQUIS"
@export var neon_color: Color = Color("#ff6a1a")
@export var font_size: int = 54
@export var padding: Vector2 = Vector2(26.0, 16.0)
## Probabilité, à chaque frame, d'un court grésillement spontané.
@export_range(0.0, 0.1) var flicker_chance: float = 0.004
@export var rng_seed: int = 0

const PLATE_COLOR: Color = Color(0.05, 0.02, 0.08, 0.85)
const GLOW_LAYERS: int = 3
const GLOW_STEP: float = 7.0
const GLOW_ALPHA: float = 0.12
const FRAME_WIDTH: float = 4.0
const TEXT_OUTLINE: int = 10
const SPONTANEOUS_GLITCH: float = 0.12
const REACT_GLITCH_BASE: float = 0.15
const REACT_GLITCH_SCALE: float = 0.45
const DIM_ALPHA: float = 0.25

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _glitch_time: float = 0.0


func _ready() -> void:
	_rng.seed = rng_seed if rng_seed != 0 else hash(text)
	if not Engine.is_editor_hint():
		add_to_group(Stage.REACTIVE_GROUP)
	queue_redraw()


func react(strength: float) -> void:
	_glitch_time = maxf(_glitch_time, REACT_GLITCH_BASE + REACT_GLITCH_SCALE * strength)


func is_glitching() -> bool:
	return _glitch_time > 0.0


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _glitch_time > 0.0:
		_glitch_time -= delta
		modulate.a = 1.0 if _glitch_time <= 0.0 else _rng.randf_range(DIM_ALPHA, 1.0)
	elif _rng.randf() < flicker_chance:
		_glitch_time = SPONTANEOUS_GLITCH


func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var plate := Rect2(-text_size * 0.5 - padding, text_size + padding * 2.0)
	draw_rect(plate, PLATE_COLOR)
	for layer: int in GLOW_LAYERS:
		draw_rect(plate.grow(GLOW_STEP * (layer + 1)), Color(neon_color, GLOW_ALPHA), false, GLOW_STEP)
	draw_rect(plate, neon_color, false, FRAME_WIDTH)
	var baseline := Vector2(-text_size.x * 0.5, (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5)
	draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, TEXT_OUTLINE, Color(neon_color, 0.4))
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, neon_color.lightened(0.55))
