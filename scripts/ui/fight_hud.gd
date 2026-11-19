class_name FightHud
extends CanvasLayer
## HUD de combat : portraits, noms, barres de vie, jauge spéciale (sous la vie, pour laisser
## le bas de l'écran aux commandes tactiles), timer, manches gagnées, compteur de combos et
## annonces (manches, ultimes, contres).
## Il ne lit l'état du combat qu'à travers les signaux de FightManager, des Fighter et du
## ComboTracker.

const ROUND_WON: String = "●"
const ROUND_EMPTY: String = "○"
const LOW_HEALTH_RATIO: float = 0.3
const ANNOUNCE_HOLD: float = 0.9
const ANNOUNCE_FADE: float = 0.3
const ANNOUNCER_OUTLINE_SIZE: int = 24
const BAR_CORNER_RADIUS: int = 8
## Durée d'affichage du compteur après la fin d'un combo (secondes).
const COMBO_LINGER: float = 1.2
const COMBO_OUTLINE_SIZE: int = 12

@onready var _portraits: Array[TextureRect] = [%P1Portrait, %P2Portrait]
@onready var _name_labels: Array[Label] = [%P1Name, %P2Name]
@onready var _combo_labels: Array[Label] = [%P1Combo, %P2Combo]
@onready var _health_bars: Array[ProgressBar] = [%P1Health, %P2Health]
@onready var _round_labels: Array[Label] = [%P1Rounds, %P2Rounds]
@onready var _gauge_labels: Array[Label] = [%P1GaugeLabel, %P2GaugeLabel]
@onready var _gauge_bars: Array[ProgressBar] = [%P1GaugeBar, %P2GaugeBar]
@onready var _timer_label: Label = %TimerLabel
@onready var _announcer: Label = %Announcer

var _manager: FightManager = null
var _announce_tween: Tween = null
var _combo_tweens: Array[Tween] = [null, null]
var _normal_fill: StyleBoxFlat = _make_fill(UIPalette.GOLD)
var _low_fill: StyleBoxFlat = _make_fill(UIPalette.BURNT_ORANGE)
var _gauge_fill: StyleBoxFlat = _make_fill(UIPalette.BURNT_ORANGE)


func _ready() -> void:
	for label: Label in _name_labels:
		label.add_theme_color_override("font_color", UIPalette.GOLD)
	for bar: ProgressBar in _gauge_bars:
		bar.add_theme_stylebox_override("fill", _gauge_fill)
		bar.max_value = GameConstants.SUPER_GAUGE_MAX
	for label: Label in _combo_labels:
		label.add_theme_color_override("font_color", UIPalette.GOLD)
		label.add_theme_color_override("font_outline_color", UIPalette.DEEP_VIOLET)
		label.add_theme_constant_override("outline_size", COMBO_OUTLINE_SIZE)
		label.text = ""
	_timer_label.add_theme_color_override("font_color", UIPalette.IVORY)
	_announcer.add_theme_color_override("font_outline_color", UIPalette.DEEP_VIOLET)
	_announcer.add_theme_constant_override("outline_size", ANNOUNCER_OUTLINE_SIZE)
	_announcer.visible = false


func bind(manager: FightManager) -> void:
	_manager = manager
	for side: int in manager.fighters.size():
		var fighter: Fighter = manager.fighters[side]
		_name_labels[side].text = fighter.data.display_name
		_portraits[side].texture = FighterPortrait.get_texture(fighter.data)
		_portraits[side].material = FighterPortrait.get_material(fighter.data)
		fighter.health_changed.connect(_on_health_changed.bind(side))
		fighter.gauge_changed.connect(_on_gauge_changed.bind(side))
		fighter.move_started.connect(_on_move_started)
		fighter.counter_triggered.connect(_on_counter_triggered)
		_on_health_changed(fighter.health, fighter.data.max_health, side)
		_on_gauge_changed(fighter.gauge, GameConstants.SUPER_GAUGE_MAX, side)
	manager.simulation.combo_tracker.combo_updated.connect(_on_combo_updated)
	manager.simulation.combo_tracker.combo_finished.connect(_on_combo_finished)
	manager.round_started.connect(_on_round_started)
	manager.fight_started.connect(_on_fight_started)
	manager.timer_changed.connect(_on_timer_changed)
	manager.round_ended.connect(_on_round_ended)
	manager.match_ended.connect(_on_match_ended)
	_refresh_rounds()


func get_announcement() -> String:
	return _announcer.text if _announcer.visible else ""


func _on_health_changed(current: int, maximum: int, side: int) -> void:
	var bar: ProgressBar = _health_bars[side]
	bar.max_value = maximum
	bar.value = current
	var low: bool = maximum > 0 and float(current) / maximum <= LOW_HEALTH_RATIO
	bar.add_theme_stylebox_override("fill", _low_fill if low else _normal_fill)


func get_portrait(side: int) -> Texture2D:
	return _portraits[side].texture


func get_combo_text(side: int) -> String:
	return _combo_labels[side].text


func _on_gauge_changed(current: int, maximum: int, side: int) -> void:
	_gauge_bars[side].value = current
	var level: int = floori(float(current) / GameConstants.SUPER_GAUGE_POINTS_PER_LEVEL)
	var full: bool = current >= maximum
	_gauge_labels[side].text = "SUPER %d · ULTIME PRÊTE" % level if full else "SUPER %d" % level
	_gauge_labels[side].add_theme_color_override("font_color", UIPalette.GOLD if full else UIPalette.IVORY)


func _on_combo_updated(side: int, hits: int, damage: int) -> void:
	if hits < GameConstants.COMBO_MIN_HITS:
		return
	if _combo_tweens[side] != null and _combo_tweens[side].is_valid():
		_combo_tweens[side].kill()
	_combo_labels[side].modulate.a = 1.0
	_combo_labels[side].text = "%d COUPS · %d" % [hits, damage]


func _on_combo_finished(side: int, _hits: int, _damage: int) -> void:
	var label: Label = _combo_labels[side]
	var tween: Tween = create_tween()
	tween.tween_interval(COMBO_LINGER)
	tween.tween_property(label, "modulate:a", 0.0, ANNOUNCE_FADE)
	tween.tween_callback(func() -> void: label.text = "")
	_combo_tweens[side] = tween


func _on_move_started(move: MoveData) -> void:
	if move.category == MoveData.Category.ULTIMATE:
		_announce(move.display_name.to_upper(), UIPalette.GOLD)


func _on_counter_triggered(_attacker: Fighter, stance: MoveData) -> void:
	_announce("%s !" % stance.display_name.to_upper(), UIPalette.GOLD)


func _on_round_started(round_number: int) -> void:
	_refresh_rounds()
	_announce("MANCHE %d" % round_number, UIPalette.IVORY)


func _on_fight_started() -> void:
	_announce("COMBAT !", UIPalette.GOLD)


func _on_timer_changed(seconds_left: int) -> void:
	_timer_label.text = "%02d" % seconds_left


func _on_round_ended(_winner_side: int, reason: FightManager.RoundEndReason) -> void:
	_refresh_rounds()
	match reason:
		FightManager.RoundEndReason.KO:
			_announce("K.O. !", UIPalette.BURNT_ORANGE)
		FightManager.RoundEndReason.DOUBLE_KO:
			_announce("DOUBLE K.O. !", UIPalette.BURNT_ORANGE)
		FightManager.RoundEndReason.TIME_OUT:
			_announce("TEMPS ÉCOULÉ", UIPalette.IVORY)


func _on_match_ended(result: MatchResult) -> void:
	if result.is_draw():
		_announce("ÉGALITÉ", UIPalette.IVORY, false)
	else:
		var winner: Fighter = _manager.fighters[result.winner_side]
		_announce("%s GAGNE !" % winner.data.display_name, UIPalette.GOLD, false)


func _refresh_rounds() -> void:
	if _manager == null:
		return
	for side: int in _round_labels.size():
		var won: int = mini(_manager.rounds_won[side], GameConstants.ROUNDS_TO_WIN)
		_round_labels[side].text = ROUND_WON.repeat(won) + ROUND_EMPTY.repeat(GameConstants.ROUNDS_TO_WIN - won)


## Affiche une annonce centrale ; fade = faux la laisse affichée (fin de match).
func _announce(text_value: String, color: Color, fade: bool = true) -> void:
	if _announce_tween != null and _announce_tween.is_valid():
		_announce_tween.kill()
	_announcer.text = text_value
	_announcer.add_theme_color_override("font_color", color)
	_announcer.modulate.a = 1.0
	_announcer.visible = true
	if not fade:
		return
	_announce_tween = create_tween()
	_announce_tween.tween_interval(ANNOUNCE_HOLD)
	_announce_tween.tween_property(_announcer, "modulate:a", 0.0, ANNOUNCE_FADE)
	_announce_tween.tween_callback(_announcer.hide)


static func _make_fill(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(BAR_CORNER_RADIUS)
	return box
