extends Control
## Sélection du combattant. Les cartes sont générées depuis FighterRegistry : ajouter un
## combattant au roster suffit pour qu'il apparaisse ici. L'adversaire est le premier
## autre combattant du roster.

const TITLE_OUTLINE_SIZE: int = 12

@onready var _background: ColorRect = %Background
@onready var _title_label: Label = %TitleLabel
@onready var _cards: HBoxContainer = %Cards
@onready var _error_label: Label = %ErrorLabel
@onready var _back_button: Button = %BackButton
@onready var _mode_button: Button = %ModeButton
@onready var _difficulty_button: Button = %DifficultyButton


func _ready() -> void:
	_mode_button.pressed.connect(_on_mode_pressed)
	_difficulty_button.pressed.connect(_on_difficulty_pressed)
	_refresh_mode_label()
	_refresh_difficulty_label()
	_background.color = UIPalette.CHARCOAL
	_title_label.add_theme_color_override("font_color", UIPalette.GOLD)
	_title_label.add_theme_color_override("font_outline_color", UIPalette.DEEP_VIOLET)
	_title_label.add_theme_constant_override("outline_size", TITLE_OUTLINE_SIZE)
	_error_label.add_theme_color_override("font_color", UIPalette.BURNT_ORANGE)
	_error_label.visible = false
	_back_button.pressed.connect(_on_back_pressed)
	_build_cards()


func get_card_count() -> int:
	return _cards.get_child_count()


func _build_cards() -> void:
	var first_card: FighterCard = null
	for fighter_id: StringName in FighterRegistry.ROSTER:
		if not SaveManager.is_fighter_unlocked(fighter_id):
			continue
		var data: FighterData = FighterRegistry.load_fighter(fighter_id)
		if data == null:
			_show_error("Combattant indisponible : %s" % fighter_id)
			continue
		var card := FighterCard.new()
		_cards.add_child(card)
		card.setup(data)
		card.fighter_chosen.connect(_on_fighter_chosen)
		if first_card == null:
			first_card = card
	if first_card != null:
		first_card.grab_focus()
	else:
		_back_button.grab_focus()


func _on_fighter_chosen(fighter_id: StringName) -> void:
	var opponent_id: StringName = FighterRegistry.pick_opponent(fighter_id)
	if GameSession.set_selection(fighter_id, opponent_id):
		SceneRouter.go_to(GameConstants.SCENE_FIGHT)


## Bascule Classique ↔ Assisté (le mode assisté simplifie combos et ultimes).
func _on_mode_pressed() -> void:
	if GameSession.control_mode == PlayerController.Mode.CLASSIC:
		SaveManager.set_control_mode(PlayerController.Mode.ASSISTED)
	else:
		SaveManager.set_control_mode(PlayerController.Mode.CLASSIC)
	_refresh_mode_label()


## Fait défiler Facile → Normal → Difficile.
func _on_difficulty_pressed() -> void:
	var count: int = AIProfile.Difficulty.size()
	SaveManager.set_difficulty(((GameSession.difficulty + 1) % count) as AIProfile.Difficulty)
	_refresh_difficulty_label()


func _refresh_difficulty_label() -> void:
	_difficulty_button.text = "IA : %s" % AIProfile.load_profile(GameSession.difficulty).display_name


func _refresh_mode_label() -> void:
	_mode_button.text = "COMMANDES : %s" % PlayerController.MODE_LABELS[GameSession.control_mode]


func _on_back_pressed() -> void:
	SceneRouter.go_to(GameConstants.SCENE_MAIN_MENU)


func _show_error(message: String) -> void:
	_error_label.visible = true
	_error_label.text = message
