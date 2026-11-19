class_name FighterVisual
extends Node2D
## Rendu d'un combattant : AnimatedSprite2D recoloré (palette du combattant) et
## AnimationPlayer pour les effets (flash blanc à l'impact).
## L'échelle du sprite est fixée une fois pour toutes au setup : elle ne change jamais
## pendant le combat.

const FLASH_ANIMATION: StringName = &"hit_flash"
const FLASH_DURATION: float = 0.14
const FLASH_TRACK_PATH: String = "Sprite:material:shader_parameter/flash_amount"
const FALLBACK_ANIMATION: StringName = &"idle"
const EFFECTS_LIBRARY: StringName = &""

@onready var _sprite: AnimatedSprite2D = $Sprite
@onready var _effects: AnimationPlayer = $Effects

var _current: StringName = &""
var _backwards: bool = false
var _missing_reported: Dictionary = {}


func setup(data: FighterData) -> void:
	_sprite.sprite_frames = data.sprite_frames
	_sprite.scale = Vector2.ONE * data.sprite_scale
	_sprite.offset = data.sprite_offset
	_sprite.material = FighterPalette.make_material(data)
	_build_effects()
	_current = &""
	play(FALLBACK_ANIMATION)


## Joue une animation (sans effet si elle tourne déjà dans le même sens).
func play(animation_name: StringName, backwards: bool = false) -> void:
	var target: StringName = animation_name
	if _sprite.sprite_frames == null:
		return
	if not _sprite.sprite_frames.has_animation(target):
		if not _missing_reported.has(target):
			_missing_reported[target] = true
			push_warning("[FighterVisual] Animation absente : %s" % target)
		target = FALLBACK_ANIMATION
	if target == _current and backwards == _backwards:
		return
	_current = target
	_backwards = backwards
	if backwards:
		_sprite.play_backwards(target)
	else:
		_sprite.play(target)


func get_current_animation() -> StringName:
	return _current


## Gèle l'animation pendant le gel d'impact (hitstop).
func set_frozen(frozen: bool) -> void:
	_sprite.speed_scale = 0.0 if frozen else 1.0


func flash() -> void:
	if _effects.has_animation(FLASH_ANIMATION):
		_effects.stop()
		_effects.play(FLASH_ANIMATION)


func _build_effects() -> void:
	if _effects.has_animation_library(EFFECTS_LIBRARY):
		return
	var animation := Animation.new()
	animation.length = FLASH_DURATION
	var track: int = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, NodePath(FLASH_TRACK_PATH))
	animation.track_insert_key(track, 0.0, 1.0)
	animation.track_insert_key(track, FLASH_DURATION, 0.0)
	var library := AnimationLibrary.new()
	library.add_animation(FLASH_ANIMATION, animation)
	_effects.add_animation_library(EFFECTS_LIBRARY, library)
