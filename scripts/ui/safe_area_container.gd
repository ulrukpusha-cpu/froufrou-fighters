class_name SafeAreaContainer
extends MarginContainer
## Conteneur qui garde son contenu hors des encoches, coins arrondis et barres système.
##
## Sur mobile, les marges = marge de base + zone non sûre de l'écran (convertie en unités de
## l'interface 1920x1080). Sur ordinateur, seule la marge de base s'applique.

## Marge minimale de chaque côté, en unités d'interface.
@export var base_margin: float = 32.0


func _ready() -> void:
	get_viewport().size_changed.connect(_update_margins)
	_update_margins()


## Marges de sécurité (gauche, haut, droite, bas) en unités d'interface, sans la marge de base.
func get_safe_insets() -> Vector4:
	if not OS.has_feature("mobile"):
		return Vector4.ZERO
	var window_size: Vector2 = Vector2(DisplayServer.window_get_size())
	if window_size.x <= 0.0 or window_size.y <= 0.0:
		return Vector4.ZERO
	var safe: Rect2 = Rect2(DisplayServer.get_display_safe_area())
	var visible_size: Vector2 = get_viewport().get_visible_rect().size
	var ratio: Vector2 = visible_size / window_size
	return Vector4(
		maxf(safe.position.x, 0.0) * ratio.x,
		maxf(safe.position.y, 0.0) * ratio.y,
		maxf(window_size.x - safe.end.x, 0.0) * ratio.x,
		maxf(window_size.y - safe.end.y, 0.0) * ratio.y
	)


func _update_margins() -> void:
	var insets: Vector4 = get_safe_insets()
	add_theme_constant_override("margin_left", roundi(base_margin + insets.x))
	add_theme_constant_override("margin_top", roundi(base_margin + insets.y))
	add_theme_constant_override("margin_right", roundi(base_margin + insets.z))
	add_theme_constant_override("margin_bottom", roundi(base_margin + insets.w))
