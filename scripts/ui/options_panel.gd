class_name OptionsPanel
extends Control
## Options du jeu, en onglets : Audio, Jeu, Commandes, Statistiques.
## Réutilisé par l'écran d'options (menu principal) et par le menu pause.
## Tous les changements passent par SaveManager (appliqués et sauvegardés aussitôt).

signal closed

const BUS_LABELS: Dictionary = {
	GameConstants.BUS_MASTER: "Général",
	GameConstants.BUS_MUSIC: "Musique",
	GameConstants.BUS_SFX: "Effets",
	GameConstants.BUS_VOICE: "Voix",
}
const TAB_TITLES: PackedStringArray = ["AUDIO", "JEU", "COMMANDES", "STATISTIQUES"]
const PERCENT: float = 100.0
const SLIDER_STEP: float = 5.0
const SLIDER_WIDTH: float = 760.0
const ROW_LABEL_WIDTH: float = 300.0
const ROW_HEIGHT: float = 80.0
const CYCLE_BUTTON_SIZE: Vector2 = Vector2(900.0, 100.0)

var _sliders: Dictionary = {}
var _value_labels: Dictionary = {}
var _difficulty_button: Button = null
var _mode_button: Button = null
var _touch_button: Button = null

@onready var _tabs: TabContainer = %Tabs
@onready var _audio_tab: VBoxContainer = %AudioTab
@onready var _game_tab: VBoxContainer = %GameTab
@onready var _remap: ControlsRemapPanel = %ControlsTab
@onready var _stats_label: Label = %StatsLabel
@onready var _back_button: Button = %BackButton
@onready var _dim: ColorRect = %Dim
@onready var _title: Label = %Title


func _ready() -> void:
	_dim.color = Color(UIPalette.CHARCOAL, 0.96)
	_title.add_theme_color_override("font_color", UIPalette.GOLD)
	for index: int in TAB_TITLES.size():
		_tabs.set_tab_title(index, TAB_TITLES[index])
	_build_audio_tab()
	_build_game_tab()
	_back_button.pressed.connect(close)
	SaveManager.settings_changed.connect(_refresh_game_tab)
	SaveManager.stats_changed.connect(_refresh_stats)
	visibility_changed.connect(_on_visibility_changed)
	_refresh_game_tab()
	_refresh_stats()


func open() -> void:
	show()
	_tabs.current_tab = 0
	_refresh_stats()
	_back_button.grab_focus()


func close() -> void:
	if _remap.is_capturing():
		_remap.cancel_capture()
	SaveManager.flush()
	hide()
	closed.emit()


func get_slider(bus: StringName) -> HSlider:
	return _sliders.get(bus) as HSlider


func get_difficulty_button() -> Button:
	return _difficulty_button


func get_stats_text() -> String:
	return _stats_label.text


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed(&"ui_cancel") and not _remap.is_capturing():
		get_viewport().set_input_as_handled()
		close()


# --- Audio ------------------------------------------------------------------------------

func _build_audio_tab() -> void:
	for bus: StringName in BUS_LABELS:
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = ROW_HEIGHT
		var label := Label.new()
		label.text = BUS_LABELS[bus]
		label.custom_minimum_size.x = ROW_LABEL_WIDTH
		row.add_child(label)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = PERCENT
		slider.step = SLIDER_STEP
		slider.custom_minimum_size = Vector2(SLIDER_WIDTH, ROW_HEIGHT * 0.5)
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slider.value = SaveManager.get_volume(bus) * PERCENT
		slider.value_changed.connect(_on_volume_changed.bind(bus))
		row.add_child(slider)
		var value_label := Label.new()
		value_label.custom_minimum_size.x = ROW_LABEL_WIDTH * 0.5
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(value_label)
		_audio_tab.add_child(row)
		_sliders[bus] = slider
		_value_labels[bus] = value_label
		_update_volume_label(bus)
	var note := Label.new()
	note.text = "Les volumes s'appliquent aux bus audio du jeu (musiques et effets : assets à venir)."
	note.add_theme_color_override("font_color", UIPalette.GOLD)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_audio_tab.add_child(note)


func _on_volume_changed(value: float, bus: StringName) -> void:
	SaveManager.set_volume(bus, value / PERCENT)
	_update_volume_label(bus)


func _update_volume_label(bus: StringName) -> void:
	(_value_labels[bus] as Label).text = "%d %%" % roundi((_sliders[bus] as HSlider).value)


# --- Jeu --------------------------------------------------------------------------------

func _build_game_tab() -> void:
	_difficulty_button = _make_cycle_button(_on_difficulty_pressed)
	_mode_button = _make_cycle_button(_on_mode_pressed)
	_touch_button = _make_cycle_button(_on_touch_pressed)
	var hint := Label.new()
	hint.text = "Mode assisté : marteler Poing enchaîne léger → lourd → spécial ; Spécial lance l'ultime dès que la jauge est pleine."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_game_tab.add_child(hint)


func _make_cycle_button(handler: Callable) -> Button:
	var button := Button.new()
	button.custom_minimum_size = CYCLE_BUTTON_SIZE
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(handler)
	_game_tab.add_child(button)
	return button


func _refresh_game_tab() -> void:
	if _difficulty_button == null:
		return
	_difficulty_button.text = "DIFFICULTÉ DE L'IA : %s" % AIProfile.load_profile(GameSession.difficulty).display_name
	_mode_button.text = "COMMANDES : %s" % PlayerController.MODE_LABELS[GameSession.control_mode]
	_touch_button.text = "COMMANDES TACTILES : %s" % TouchControls.VISIBILITY_LABELS[GameSession.touch_controls]


func _on_difficulty_pressed() -> void:
	SaveManager.set_difficulty(_next(GameSession.difficulty, AIProfile.Difficulty.size()) as AIProfile.Difficulty)


func _on_mode_pressed() -> void:
	SaveManager.set_control_mode(_next(GameSession.control_mode, PlayerController.Mode.size()) as PlayerController.Mode)


func _on_touch_pressed() -> void:
	SaveManager.set_touch_controls(_next(GameSession.touch_controls, TouchControls.Visibility.size()) as TouchControls.Visibility)


static func _next(current: int, count: int) -> int:
	return (current + 1) % count


# --- Statistiques -----------------------------------------------------------------------

func _refresh_stats() -> void:
	var stats: Dictionary = SaveManager.get_stats()
	var lines := PackedStringArray()
	lines.append("Combats : %d    Victoires : %d    Défaites : %d    Égalités : %d" % [
		int(stats["matches_played"]), int(stats["matches_won"]), int(stats["matches_lost"]), int(stats["matches_drawn"])])
	lines.append("Manches gagnées : %d    Manches perdues : %d" % [int(stats["rounds_won"]), int(stats["rounds_lost"])])
	lines.append("Meilleur combo : %d coups" % int(stats["best_combo"]))
	var by_level := PackedStringArray()
	for level: int in AIProfile.Difficulty.size():
		var profile: AIProfile = AIProfile.load_profile(level as AIProfile.Difficulty)
		by_level.append("%s %d" % [profile.display_name, SaveManager.get_wins_by_difficulty(level as AIProfile.Difficulty)])
	lines.append("Victoires par difficulté : %s" % "  ·  ".join(by_level))
	var fighters: Dictionary = stats["fighters"]
	for fighter_id: StringName in FighterRegistry.ROSTER:
		var entry: Dictionary = fighters.get(String(fighter_id), {})
		var data: FighterData = FighterRegistry.load_fighter(fighter_id)
		var fighter_name: String = data.display_name if data != null else String(fighter_id)
		lines.append("%s : %d combats, %d victoires" % [fighter_name, int(entry.get("played", 0)), int(entry.get("won", 0))])
	_stats_label.text = "\n".join(lines)


func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		_refresh_stats()
