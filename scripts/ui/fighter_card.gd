class_name FighterCard
extends Button
## Carte de sélection d'un combattant : aperçu recoloré, nom, origine, style, spécialité.

signal fighter_chosen(fighter_id: StringName)

const CARD_SIZE: Vector2 = Vector2(560.0, 700.0)
const PREVIEW_SIZE: Vector2 = Vector2(320.0, 400.0)
const PREVIEW_ANIMATION: StringName = &"idle"
const NAME_FONT_SIZE: int = 60
const INFO_FONT_SIZE: int = 28
const CONTENT_MARGIN: int = 24
const CONTENT_SEPARATION: int = 12

var fighter_id: StringName = &""


func setup(data: FighterData) -> void:
	fighter_id = data.id
	custom_minimum_size = CARD_SIZE
	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", CONTENT_SEPARATION)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, CONTENT_MARGIN)
	add_child(content)
	content.add_child(_make_preview(data))
	content.add_child(_make_label(data.display_name, NAME_FONT_SIZE, UIPalette.GOLD))
	content.add_child(_make_label(data.origin, INFO_FONT_SIZE, UIPalette.IVORY))
	content.add_child(_make_label(data.fighting_style, INFO_FONT_SIZE, UIPalette.IVORY))
	content.add_child(_make_label("Spécialité : %s" % data.specialty_name, INFO_FONT_SIZE, UIPalette.GOLD))
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	fighter_chosen.emit(fighter_id)


func _make_preview(data: FighterData) -> TextureRect:
	var preview := TextureRect.new()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.custom_minimum_size = PREVIEW_SIZE
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if data.sprite_frames != null and data.sprite_frames.has_animation(PREVIEW_ANIMATION):
		preview.texture = data.sprite_frames.get_frame_texture(PREVIEW_ANIMATION, 0)
		preview.material = FighterPalette.make_material(data)
	return preview


func _make_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Largeur fixe + retour à la ligne : un texte long ne déborde jamais de la carte.
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = CARD_SIZE.x - CONTENT_MARGIN * 2.0
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
