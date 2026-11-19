extends Control
## Écran de démarrage.
##
## 1. Affiche l'identité du jeu.
## 2. Vérifie la configuration critique (ProjectConfigCheck) et journalise les écarts.
## 3. Charge la scène suivante dans un thread, avec barre de progression.
## 4. Change de scène après une durée minimale d'affichage.
## Toute erreur de chargement est affichée à l'écran et émise via boot_failed.

signal boot_completed(next_scene_path: String)
signal boot_failed(reason: String)

enum BootState { CHECKING, LOADING, READY, DONE, FAILED }

const FADE_IN_DURATION: float = 0.35
const PROGRESS_BAR_HEIGHT: float = 14.0
const PROGRESS_CORNER_RADIUS: int = 7
const TITLE_OUTLINE_SIZE: int = 18

## Scène chargée à la fin du boot.
@export_file("*.tscn") var next_scene_path: String = GameConstants.SCENE_MAIN_MENU
## Durée minimale d'affichage du splash (secondes), pour éviter un simple flash.
@export_range(0.0, 5.0, 0.1) var minimum_display_time: float = 1.2
## Si faux, la scène est chargée mais aucun changement de scène n'a lieu (tests).
@export var auto_change_scene: bool = true

var _state: BootState = BootState.CHECKING
var _elapsed: float = 0.0
var _load_progress: Array = []
var _loaded_scene: PackedScene = null

@onready var _content: Control = %Content
@onready var _title_label: Label = %TitleLabel
@onready var _tagline_label: Label = %TaglineLabel
@onready var _status_label: Label = %StatusLabel
@onready var _version_label: Label = %VersionLabel
@onready var _progress_bar: ProgressBar = %ProgressBar
@onready var _background: ColorRect = %Background
@onready var _top_stripe: ColorRect = %TopStripe
@onready var _bottom_stripe: ColorRect = %BottomStripe


func _ready() -> void:
	_apply_palette()
	_play_intro()
	var version: String = ProjectSettings.get_setting("application/config/version", "0.0.0")
	_version_label.text = "v%s" % version
	_report_config_issues(ProjectConfigCheck.run())
	_start_loading()


func _process(delta: float) -> void:
	_elapsed += delta
	match _state:
		BootState.LOADING:
			_poll_loading()
		BootState.READY:
			_try_finish()


func get_state() -> BootState:
	return _state


func _report_config_issues(issues: PackedStringArray) -> void:
	for issue: String in issues:
		push_warning("[Boot] Configuration : %s" % issue)


func _start_loading() -> void:
	if next_scene_path.is_empty() or not ResourceLoader.exists(next_scene_path):
		_fail("Scène introuvable : %s" % next_scene_path)
		return
	var err: Error = ResourceLoader.load_threaded_request(next_scene_path, "PackedScene")
	if err != OK:
		_fail("Impossible de charger %s (%s)" % [next_scene_path, error_string(err)])
		return
	_state = BootState.LOADING
	_status_label.text = "Chargement…"


func _poll_loading() -> void:
	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(
		next_scene_path, _load_progress
	)
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if not _load_progress.is_empty():
				_progress_bar.value = float(_load_progress[0]) * _progress_bar.max_value
		ResourceLoader.THREAD_LOAD_LOADED:
			_loaded_scene = ResourceLoader.load_threaded_get(next_scene_path) as PackedScene
			if _loaded_scene == null:
				_fail("%s n'est pas une scène valide" % next_scene_path)
				return
			_progress_bar.value = _progress_bar.max_value
			_status_label.text = "Prêt"
			_state = BootState.READY
		_:
			_fail("Échec du chargement de %s" % next_scene_path)


func _try_finish() -> void:
	if _elapsed < minimum_display_time:
		return
	_state = BootState.DONE
	set_process(false)
	boot_completed.emit(next_scene_path)
	if not auto_change_scene:
		return
	var err: Error = get_tree().change_scene_to_packed(_loaded_scene)
	if err != OK:
		_fail("Changement de scène impossible (%s)" % error_string(err))


func _fail(reason: String) -> void:
	_state = BootState.FAILED
	set_process(false)
	_status_label.text = reason
	_status_label.add_theme_color_override("font_color", UIPalette.BURNT_ORANGE)
	push_error("[Boot] %s" % reason)
	boot_failed.emit(reason)


func _play_intro() -> void:
	_content.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(_content, "modulate:a", 1.0, FADE_IN_DURATION)


func _apply_palette() -> void:
	_background.color = UIPalette.CHARCOAL
	_top_stripe.color = UIPalette.BURNT_ORANGE
	_bottom_stripe.color = UIPalette.GOLD
	_title_label.add_theme_color_override("font_color", UIPalette.GOLD)
	_title_label.add_theme_color_override("font_outline_color", UIPalette.DEEP_VIOLET)
	_title_label.add_theme_constant_override("outline_size", TITLE_OUTLINE_SIZE)
	_tagline_label.add_theme_color_override("font_color", UIPalette.IVORY)
	_status_label.add_theme_color_override("font_color", UIPalette.IVORY)
	_version_label.add_theme_color_override("font_color", UIPalette.GOLD)
	_progress_bar.custom_minimum_size.y = PROGRESS_BAR_HEIGHT
	_progress_bar.add_theme_stylebox_override("background", _make_box(UIPalette.VIOLET_SHADOW))
	_progress_bar.add_theme_stylebox_override("fill", _make_box(UIPalette.GOLD))


func _make_box(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(PROGRESS_CORNER_RADIUS)
	return box
