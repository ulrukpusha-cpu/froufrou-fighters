class_name ControlsRemapPanel
extends VBoxContainer
## Personnalisation des commandes : une ligne par action, un bouton pour la touche clavier
## et un pour le bouton de manette. Cliquer puis appuyer sur la nouvelle touche ; Échap
## annule. Les choix sont sauvegardés (SaveManager) et appliqués immédiatement à l'InputMap :
## clavier, manette et commandes tactiles restent sur les mêmes actions logiques.

signal capture_started(action: StringName)
signal capture_finished(action: StringName)

enum CaptureKind { NONE, KEYBOARD, GAMEPAD }

const WAITING_TEXT: String = "Appuie…"
const NONE_TEXT: String = "—"
const ROW_HEIGHT: float = 76.0
const LABEL_WIDTH: float = 300.0
const BUTTON_WIDTH: float = 340.0
const ROW_FONT_SIZE: int = 30

var _key_buttons: Dictionary = {}
var _pad_buttons: Dictionary = {}
var _capture_action: StringName = &""
var _capture_kind: CaptureKind = CaptureKind.NONE
var _reset_button: Button = null


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	_build()
	SaveManager.settings_changed.connect(refresh)
	refresh()


func is_capturing() -> bool:
	return _capture_kind != CaptureKind.NONE


func get_key_button(action: StringName) -> Button:
	return _key_buttons.get(action) as Button


func get_pad_button(action: StringName) -> Button:
	return _pad_buttons.get(action) as Button


## Met à jour les libellés depuis l'InputMap.
func refresh() -> void:
	for action: StringName in InputActions.ALL_ACTIONS:
		var keys: Array[int] = InputActions.get_keys(action)
		var buttons: Array[int] = InputActions.get_buttons(action)
		(_key_buttons[action] as Button).text = _join_labels(keys, true)
		(_pad_buttons[action] as Button).text = _join_labels(buttons, false)


## Démarre l'écoute de la prochaine touche (KEYBOARD) ou du prochain bouton (GAMEPAD).
func start_capture(action: StringName, kind: CaptureKind) -> void:
	refresh()
	_capture_action = action
	_capture_kind = kind
	var button: Button = (_key_buttons if kind == CaptureKind.KEYBOARD else _pad_buttons)[action]
	button.text = WAITING_TEXT
	capture_started.emit(action)


func cancel_capture() -> void:
	var action: StringName = _capture_action
	_capture_kind = CaptureKind.NONE
	_capture_action = &""
	refresh()
	capture_finished.emit(action)


func _input(event: InputEvent) -> void:
	if not is_capturing() or not is_visible_in_tree():
		return
	var key_event: InputEventKey = event as InputEventKey
	if key_event != null and key_event.pressed and not key_event.echo:
		get_viewport().set_input_as_handled()
		if key_event.physical_keycode == KEY_ESCAPE:
			cancel_capture()
		elif _capture_kind == CaptureKind.KEYBOARD:
			_finish_capture(int(key_event.physical_keycode))
		return
	var pad_event: InputEventJoypadButton = event as InputEventJoypadButton
	if pad_event != null and pad_event.pressed and _capture_kind == CaptureKind.GAMEPAD:
		get_viewport().set_input_as_handled()
		_finish_capture(int(pad_event.button_index))


func _finish_capture(value: int) -> void:
	var action: StringName = _capture_action
	if _capture_kind == CaptureKind.KEYBOARD:
		SaveManager.set_binding_key(action, value)
	else:
		SaveManager.set_binding_button(action, value)
	_capture_kind = CaptureKind.NONE
	_capture_action = &""
	refresh()
	capture_finished.emit(action)


func _build() -> void:
	var header := HBoxContainer.new()
	header.add_child(_make_label("ACTION", LABEL_WIDTH, UIPalette.GOLD))
	header.add_child(_make_label("CLAVIER", BUTTON_WIDTH, UIPalette.GOLD))
	header.add_child(_make_label("MANETTE", BUTTON_WIDTH, UIPalette.GOLD))
	add_child(header)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	for action: StringName in InputActions.ALL_ACTIONS:
		var row := HBoxContainer.new()
		row.add_child(_make_label(InputActions.ACTION_LABELS.get(action, String(action)), LABEL_WIDTH, UIPalette.IVORY))
		var key_button: Button = _make_button(action, CaptureKind.KEYBOARD)
		var pad_button: Button = _make_button(action, CaptureKind.GAMEPAD)
		row.add_child(key_button)
		row.add_child(pad_button)
		rows.add_child(row)
		_key_buttons[action] = key_button
		_pad_buttons[action] = pad_button
	_reset_button = Button.new()
	_reset_button.text = "RÉINITIALISER LES COMMANDES"
	_reset_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_reset_button.pressed.connect(_on_reset_pressed)
	add_child(_reset_button)


func _make_button(action: StringName, kind: CaptureKind) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(BUTTON_WIDTH, ROW_HEIGHT)
	button.add_theme_font_size_override("font_size", ROW_FONT_SIZE)
	button.pressed.connect(start_capture.bind(action, kind))
	return button


func _make_label(text_value: String, width: float, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.custom_minimum_size = Vector2(width, ROW_HEIGHT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", ROW_FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	return label


func _on_reset_pressed() -> void:
	if is_capturing():
		cancel_capture()
	SaveManager.reset_bindings()


static func _join_labels(values: Array[int], keyboard: bool) -> String:
	if values.is_empty():
		return NONE_TEXT
	var labels := PackedStringArray()
	for value: int in values:
		labels.append(InputActions.key_label(value) if keyboard else InputActions.button_label(value))
	return " / ".join(labels)
