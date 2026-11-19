extends Control
## Écran de fin de match : victoire / défaite / égalité, score des manches, suites possibles.
## Lit GameSession.last_result ; sans résultat, affiche un message et propose le menu.

const OUTCOME_OUTLINE_SIZE: int = 20

@onready var _background: ColorRect = %Background
@onready var _outcome_label: Label = %OutcomeLabel
@onready var _detail_label: Label = %DetailLabel
@onready var _score_label: Label = %ScoreLabel
@onready var _record_label: Label = %RecordLabel
@onready var _rematch_button: Button = %RematchButton
@onready var _select_button: Button = %SelectButton
@onready var _menu_button: Button = %MenuButton


func _ready() -> void:
	_background.color = UIPalette.CHARCOAL
	_outcome_label.add_theme_color_override("font_outline_color", UIPalette.DEEP_VIOLET)
	_outcome_label.add_theme_constant_override("outline_size", OUTCOME_OUTLINE_SIZE)
	_score_label.add_theme_color_override("font_color", UIPalette.GOLD)
	_rematch_button.pressed.connect(_on_rematch_pressed)
	_select_button.pressed.connect(_on_select_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)
	show_result(GameSession.last_result)
	_show_record()


## Bilan sauvegardé du joueur (toutes parties confondues).
func _show_record() -> void:
	var stats: Dictionary = SaveManager.get_stats()
	_record_label.text = "Bilan : %d victoires sur %d combats · meilleur combo %d coups" % [
		int(stats["matches_won"]), int(stats["matches_played"]), int(stats["best_combo"])]


func show_result(result: MatchResult) -> void:
	if result == null:
		_outcome_label.text = "AUCUN RÉSULTAT"
		_outcome_label.add_theme_color_override("font_color", UIPalette.IVORY)
		_detail_label.text = "Aucun combat terminé."
		_score_label.text = ""
		_rematch_button.visible = false
		_menu_button.grab_focus()
		return
	_rematch_button.visible = true
	if result.is_draw():
		_outcome_label.text = "ÉGALITÉ"
		_outcome_label.add_theme_color_override("font_color", UIPalette.IVORY)
		_detail_label.text = "Personne ne l'emporte."
	elif result.player_won():
		_outcome_label.text = "VICTOIRE"
		_outcome_label.add_theme_color_override("font_color", UIPalette.GOLD)
		_detail_label.text = "%s l'emporte !" % _fighter_name(result.get_winner_id())
	else:
		_outcome_label.text = "DÉFAITE"
		_outcome_label.add_theme_color_override("font_color", UIPalette.BURNT_ORANGE)
		_detail_label.text = "%s l'emporte." % _fighter_name(result.get_winner_id())
	_score_label.text = "%d – %d" % [
		result.rounds_won[GameConstants.SIDE_P1], result.rounds_won[GameConstants.SIDE_P2]
	]
	_rematch_button.grab_focus()


func _fighter_name(fighter_id: StringName) -> String:
	var data: FighterData = FighterRegistry.load_fighter(fighter_id)
	return data.display_name if data != null else String(fighter_id)


func _on_rematch_pressed() -> void:
	SceneRouter.go_to(GameConstants.SCENE_FIGHT)


func _on_select_pressed() -> void:
	SceneRouter.go_to(GameConstants.SCENE_CHARACTER_SELECT)


func _on_menu_pressed() -> void:
	SceneRouter.go_to(GameConstants.SCENE_MAIN_MENU)
