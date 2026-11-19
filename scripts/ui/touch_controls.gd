class_name TouchControls
extends CanvasLayer
## Commandes tactiles du combat : joystick virtuel (moitié gauche) + boutons Poing, Pied,
## Spécial, Garde et Esquive (en bas à droite), dans la zone de sécurité de l'écran.
##
## Elles déclenchent les mêmes actions logiques que le clavier et la manette : le mode
## Classique ou Assisté s'applique donc à l'identique (PlayerController / AssistedInput).
## Poing + Pied tenus ensemble = projection (multi-touch).

enum Visibility {
	AUTO, ## Affichées sur écran tactile (ou avec l'argument --touch sur ordinateur).
	ALWAYS,
	NEVER,
}

## Libellés affichés dans les options.
const VISIBILITY_LABELS: Dictionary = {
	Visibility.AUTO: "AUTO", Visibility.ALWAYS: "TOUJOURS", Visibility.NEVER: "JAMAIS",
}

## Argument utilisateur pour afficher les commandes sur ordinateur :
## godot --path . -- --touch
const FORCE_ARGUMENT: String = "--touch"
## Plateformes tactiles : applications mobiles et navigateurs mobiles.
const MOBILE_FEATURES: PackedStringArray = ["mobile", "web_android", "web_ios"]

@onready var _root: Control = %Root
@onready var _joystick: TouchJoystick = %Joystick
@onready var _assist_badge: Label = %AssistBadge
@onready var _buttons: Array[TouchActionButton] = _collect_buttons()


func _ready() -> void:
	_assist_badge.add_theme_color_override("font_color", UIPalette.GOLD)
	apply_visibility(GameSession.touch_controls)
	set_control_mode(GameSession.control_mode)


static func should_show(mode: Visibility) -> bool:
	match mode:
		Visibility.ALWAYS:
			return true
		Visibility.NEVER:
			return false
	# DisplayServer.is_touchscreen_available() n'est pas utilisé : il renvoie vrai dès que la
	# souris émule le tactile (réglage du projet pour tester sur ordinateur), ce qui afficherait
	# les commandes à tous les joueurs PC. On se fie à la plateforme.
	for feature: String in MOBILE_FEATURES:
		if OS.has_feature(feature):
			return true
	return FORCE_ARGUMENT in OS.get_cmdline_user_args()


func apply_visibility(mode: Visibility) -> void:
	_root.visible = should_show(mode)


func is_shown() -> bool:
	return _root.visible


## Affiche le rappel du mode Assisté (chaîne au Poing, ultime sur Spécial).
func set_control_mode(mode: PlayerController.Mode) -> void:
	_assist_badge.visible = mode == PlayerController.Mode.ASSISTED


func get_joystick() -> TouchJoystick:
	return _joystick


func get_button(action: StringName) -> TouchActionButton:
	for button: TouchActionButton in _buttons:
		if button.action == action:
			return button
	return null


## Relâche tout (fin de manche, pause, changement d'écran).
func release_all() -> void:
	_joystick.release()
	for button: TouchActionButton in _buttons:
		button.release()


func _collect_buttons() -> Array[TouchActionButton]:
	var result: Array[TouchActionButton] = [%PauseButton as TouchActionButton]
	for child: Node in %Buttons.get_children():
		var button: TouchActionButton = child as TouchActionButton
		if button != null:
			result.append(button)
	return result
