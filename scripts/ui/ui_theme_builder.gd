class_name UIThemeBuilder
extends RefCounted
## Construit le thème global de l'interface à partir de la palette.
##
## Le thème est sauvegardé dans THEME_PATH par tools/configure_project.gd et déclaré comme
## thème du projet : tous les écrans en héritent, aucune couleur n'est saisie à la main.

# preload() : utilisable par l'outil de configuration avant la première importation.
const Palette := preload("res://scripts/ui/ui_palette.gd")

const THEME_PATH: String = "res://assets/ui/ff_theme.tres"
const DEFAULT_FONT_SIZE: int = 32
const BUTTON_FONT_SIZE: int = 40
const CORNER_RADIUS: int = 14
const BORDER_WIDTH: int = 4
const FOCUS_BORDER_WIDTH: int = 6
const BUTTON_PADDING: Vector2 = Vector2(36.0, 18.0)
const PANEL_PADDING: float = 24.0
const BAR_CORNER_RADIUS: int = 8
const TAB_PADDING: Vector2 = Vector2(28.0, 12.0)
## Épaisseur des pistes de curseur (assez épaisses pour le doigt).
const SLIDER_TRACK_THICKNESS: float = 14.0


static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = DEFAULT_FONT_SIZE
	theme.set_color("font_color", "Label", Palette.IVORY)
	theme.set_color("font_outline_color", "Label", Palette.CHARCOAL)
	_style_buttons(theme)
	_style_panels(theme)
	_style_progress_bars(theme)
	_style_tabs(theme)
	_style_sliders(theme)
	return theme


static func _style_tabs(theme: Theme) -> void:
	var tab_padding := Vector2(TAB_PADDING.x, TAB_PADDING.y)
	theme.set_stylebox("tab_selected", "TabContainer", _box(Palette.DEEP_VIOLET, Palette.GOLD, tab_padding))
	theme.set_stylebox("tab_unselected", "TabContainer", _box(Palette.VIOLET_SHADOW, Palette.VIOLET_SHADOW, tab_padding))
	theme.set_stylebox("tab_hovered", "TabContainer", _box(Palette.BURNT_ORANGE, Palette.GOLD, tab_padding))
	theme.set_stylebox("tab_focus", "TabContainer", _box(Palette.DEEP_VIOLET, Palette.IVORY, tab_padding))
	theme.set_stylebox("panel", "TabContainer", _box(Palette.VIOLET_SHADOW, Palette.DEEP_VIOLET, Vector2(PANEL_PADDING, PANEL_PADDING)))
	theme.set_color("font_selected_color", "TabContainer", Palette.GOLD)
	theme.set_color("font_unselected_color", "TabContainer", Palette.IVORY)
	theme.set_color("font_hovered_color", "TabContainer", Palette.IVORY)
	theme.set_constant("side_margin", "TabContainer", 0)


static func _style_sliders(theme: Theme) -> void:
	var track := _bar(Palette.VIOLET_SHADOW)
	track.content_margin_top = SLIDER_TRACK_THICKNESS * 0.5
	track.content_margin_bottom = SLIDER_TRACK_THICKNESS * 0.5
	var filled := _bar(Palette.GOLD)
	filled.content_margin_top = SLIDER_TRACK_THICKNESS * 0.5
	filled.content_margin_bottom = SLIDER_TRACK_THICKNESS * 0.5
	var highlight := _bar(Palette.BURNT_ORANGE)
	highlight.content_margin_top = SLIDER_TRACK_THICKNESS * 0.5
	highlight.content_margin_bottom = SLIDER_TRACK_THICKNESS * 0.5
	theme.set_stylebox("slider", "HSlider", track)
	theme.set_stylebox("grabber_area", "HSlider", filled)
	theme.set_stylebox("grabber_area_highlight", "HSlider", highlight)


static func _style_buttons(theme: Theme) -> void:
	var pressed: StyleBoxFlat = _box(Palette.GOLD, Palette.IVORY, BUTTON_PADDING)
	theme.set_stylebox("normal", "Button", _box(Palette.DEEP_VIOLET, Palette.GOLD, BUTTON_PADDING))
	theme.set_stylebox("hover", "Button", _box(Palette.BURNT_ORANGE, Palette.GOLD, BUTTON_PADDING))
	theme.set_stylebox("pressed", "Button", pressed)
	theme.set_stylebox("hover_pressed", "Button", pressed)
	theme.set_stylebox("disabled", "Button", _box(Palette.VIOLET_SHADOW, Palette.CHARCOAL, BUTTON_PADDING))
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = Palette.IVORY
	focus.set_border_width_all(FOCUS_BORDER_WIDTH)
	focus.set_corner_radius_all(CORNER_RADIUS)
	theme.set_stylebox("focus", "Button", focus)
	theme.set_color("font_color", "Button", Palette.IVORY)
	theme.set_color("font_hover_color", "Button", Palette.IVORY)
	theme.set_color("font_focus_color", "Button", Palette.GOLD)
	theme.set_color("font_pressed_color", "Button", Palette.CHARCOAL)
	theme.set_color("font_hover_pressed_color", "Button", Palette.CHARCOAL)
	theme.set_color("font_disabled_color", "Button", Palette.DEEP_VIOLET)
	theme.set_font_size("font_size", "Button", BUTTON_FONT_SIZE)


static func _style_panels(theme: Theme) -> void:
	var padding := Vector2(PANEL_PADDING, PANEL_PADDING)
	theme.set_stylebox("panel", "PanelContainer", _box(Palette.VIOLET_SHADOW, Palette.GOLD, padding))
	theme.set_stylebox("panel", "Panel", _box(Palette.VIOLET_SHADOW, Palette.GOLD, padding))


static func _style_progress_bars(theme: Theme) -> void:
	theme.set_stylebox("background", "ProgressBar", _bar(Palette.VIOLET_SHADOW))
	theme.set_stylebox("fill", "ProgressBar", _bar(Palette.GOLD))


static func _box(background: Color, border: Color, padding: Vector2) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(BORDER_WIDTH)
	box.set_corner_radius_all(CORNER_RADIUS)
	box.content_margin_left = padding.x
	box.content_margin_right = padding.x
	box.content_margin_top = padding.y
	box.content_margin_bottom = padding.y
	return box


static func _bar(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(BAR_CORNER_RADIUS)
	return box
