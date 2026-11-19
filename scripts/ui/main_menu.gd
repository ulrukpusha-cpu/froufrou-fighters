extends Control
## Menu principal. Seules les entrées réellement disponibles sont affichées.

const TITLE_OUTLINE_SIZE: int = 18

@onready var _background: ColorRect = %Background
@onready var _title_label: Label = %TitleLabel
@onready var _tagline_label: Label = %TaglineLabel
@onready var _fight_button: Button = %FightButton
@onready var _options_button: Button = %OptionsButton
@onready var _quit_button: Button = %QuitButton
@onready var _version_label: Label = %VersionLabel


func _ready() -> void:
	_background.color = UIPalette.CHARCOAL
	_title_label.add_theme_color_override("font_color", UIPalette.GOLD)
	_title_label.add_theme_color_override("font_outline_color", UIPalette.DEEP_VIOLET)
	_title_label.add_theme_constant_override("outline_size", TITLE_OUTLINE_SIZE)
	_tagline_label.add_theme_color_override("font_color", UIPalette.BURNT_ORANGE)
	_version_label.add_theme_color_override("font_color", UIPalette.GOLD)
	var version: String = ProjectSettings.get_setting("application/config/version", "0.0.0")
	_version_label.text = "v%s" % version
	_fight_button.pressed.connect(_on_fight_pressed)
	_options_button.pressed.connect(_on_options_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	# iOS interdit les boutons « Quitter » ; sur le web, quitter n'a pas de sens.
	_quit_button.visible = not (OS.has_feature("ios") or OS.has_feature("web"))
	_fight_button.grab_focus()


func _on_fight_pressed() -> void:
	SceneRouter.go_to(GameConstants.SCENE_CHARACTER_SELECT)


func _on_options_pressed() -> void:
	SceneRouter.go_to(GameConstants.SCENE_OPTIONS)


func _on_quit_pressed() -> void:
	SaveManager.flush()
	get_tree().quit()
