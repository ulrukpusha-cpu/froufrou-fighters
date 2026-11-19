class_name PauseMenu
extends CanvasLayer
## Menu pause du combat : Reprendre, Recommencer, Options, Quitter.
##
## S'ouvre avec l'action « pause » (Échap, P, Start, bouton tactile II) et automatiquement
## quand l'application passe en arrière-plan (appel, notification, changement d'app).
## Il fige l'arbre (get_tree().paused) : simulation, IA et commandes tactiles s'arrêtent ;
## ce menu, lui, continue de tourner (PROCESS_MODE_ALWAYS).

signal opened
signal resumed
signal restart_requested
signal quit_requested

## Faux pendant l'intro et après la fin du match (aucune pause possible).
var enabled: bool = false

## Échap ferme les options ET correspond à l'action pause : on ignore la pause pendant la
## frame où les options se ferment, sinon le combat reprendrait dans le même appui.
var _ignore_pause_until_frame: int = -1

@onready var _root: Control = %Root
@onready var _dim: ColorRect = %Dim
@onready var _title: Label = %Title
@onready var _resume_button: Button = %ResumeButton
@onready var _restart_button: Button = %RestartButton
@onready var _options_button: Button = %OptionsButton
@onready var _quit_button: Button = %QuitButton
@onready var _options: OptionsPanel = %OptionsPanel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_dim.color = Color(UIPalette.CHARCOAL, 0.8)
	_title.add_theme_color_override("font_color", UIPalette.GOLD)
	_resume_button.pressed.connect(resume)
	_restart_button.pressed.connect(_on_restart_pressed)
	_options_button.pressed.connect(_on_options_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_options.closed.connect(_on_options_closed)
	_options.hide()
	_root.hide()


func _process(_delta: float) -> void:
	if not Input.is_action_just_pressed(InputActions.PAUSE):
		return
	if Engine.get_process_frames() <= _ignore_pause_until_frame:
		return
	if is_open():
		if not _options.visible:
			resume()
	elif enabled:
		open()


func _notification(what: int) -> void:
	var backgrounded: bool = what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED
	if backgrounded and enabled and not is_open():
		open()


func is_open() -> bool:
	return _root.visible


func open() -> void:
	if is_open():
		return
	get_tree().paused = true
	_root.show()
	_resume_button.grab_focus()
	opened.emit()


func resume() -> void:
	if not is_open():
		return
	_options.hide()
	_root.hide()
	get_tree().paused = false
	resumed.emit()


func _on_restart_pressed() -> void:
	_close_for_navigation()
	restart_requested.emit()


func _on_quit_pressed() -> void:
	_close_for_navigation()
	quit_requested.emit()


func _on_options_pressed() -> void:
	_options.open()


func _on_options_closed() -> void:
	_ignore_pause_until_frame = Engine.get_process_frames() + 1
	_options_button.grab_focus()


## Quitte la pause avant de changer d'écran (sinon la scène suivante serait figée).
func _close_for_navigation() -> void:
	enabled = false
	_options.hide()
	_root.hide()
	get_tree().paused = false
