extends CanvasLayer
## Navigation entre les écrans avec fondu (autoload « SceneRouter »).
##
## Justification de l'autoload : le voile de transition doit survivre au changement de
## scène. Pendant une transition, les clics sont bloqués et une deuxième demande est refusée.

signal scene_change_started(path: String)
signal scene_changed(path: String)
signal scene_change_failed(path: String, reason: String)

## Au-dessus de toute l'interface du jeu.
const OVERLAY_LAYER: int = 128

var _overlay: ColorRect
var _busy: bool = false


func _ready() -> void:
	layer = OVERLAY_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay = ColorRect.new()
	_overlay.name = "FadeOverlay"
	_overlay.color = UIPalette.CHARCOAL
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.modulate.a = 0.0
	add_child(_overlay)


func is_busy() -> bool:
	return _busy


## Change d'écran avec fondu. Retourne faux si la scène est introuvable, si le changement
## échoue ou si une transition est déjà en cours.
func go_to(path: String) -> bool:
	if _busy:
		return false
	if not ResourceLoader.exists(path):
		_report_failure(path, "scène introuvable")
		return false
	_busy = true
	scene_change_started.emit(path)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	await _fade_to(1.0)
	var err: Error = get_tree().change_scene_to_file(path)
	if err == OK:
		# Le remplacement effectif a lieu à la fin de la frame courante.
		await get_tree().process_frame
		await get_tree().process_frame
	else:
		_report_failure(path, error_string(err))
	await _fade_to(0.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
	if err == OK:
		scene_changed.emit(path)
	return err == OK


func _fade_to(alpha: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_overlay, "modulate:a", alpha, GameConstants.SCENE_FADE_DURATION)
	await tween.finished


func _report_failure(path: String, reason: String) -> void:
	push_error("[SceneRouter] Impossible d'ouvrir %s : %s" % [path, reason])
	scene_change_failed.emit(path, reason)
