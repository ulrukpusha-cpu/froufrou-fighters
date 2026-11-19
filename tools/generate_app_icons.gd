extends SceneTree
## Génère les icônes d'application (PNG) à partir de res://icon.svg (Phase 11).
##   - Android : icône 192 px, icône adaptative (premier plan + fond 432 px) ;
##   - iOS / App Store : icône 1024 px OPAQUE (Apple refuse la transparence).
##
## Usage : godot --headless --path . --script res://tools/generate_app_icons.gd
## puis   : godot --headless --path . --import

# preload() : utilisable avant la première importation (pas de class_name requis).
const Palette := preload("res://scripts/ui/ui_palette.gd")

const SOURCE_SVG: String = "res://icon.svg"
const OUTPUT_DIR: String = "res://assets/ui/icons"
const SOURCE_SIZE: float = 256.0
const ANDROID_ICON_SIZE: int = 192
const ADAPTIVE_SIZE: int = 432
## Zone sûre d'une icône adaptative Android : le logo occupe les 2/3 centraux.
const ADAPTIVE_SAFE_RATIO: float = 0.66
const STORE_ICON_SIZE: int = 1024


func _initialize() -> void:
	var svg: String = FileAccess.get_file_as_string(SOURCE_SVG)
	if svg.is_empty():
		push_error("[icons] Impossible de lire %s" % SOURCE_SVG)
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	var ok: bool = true
	ok = _save(_render(svg, ANDROID_ICON_SIZE), "icon_192.png") and ok
	ok = _save(_adaptive_foreground(svg), "adaptive_foreground_432.png") and ok
	ok = _save(_solid(ADAPTIVE_SIZE, Palette.DEEP_VIOLET), "adaptive_background_432.png") and ok
	ok = _save(_opaque(_render(svg, STORE_ICON_SIZE), Palette.DEEP_VIOLET), "icon_1024.png") and ok
	quit(0 if ok else 1)


func _render(svg: String, size: int) -> Image:
	var image := Image.new()
	var err: Error = image.load_svg_from_string(svg, size / SOURCE_SIZE)
	if err != OK:
		push_error("[icons] Rendu SVG impossible (%s)" % error_string(err))
	return image


func _adaptive_foreground(svg: String) -> Image:
	var logo_size: int = roundi(ADAPTIVE_SIZE * ADAPTIVE_SAFE_RATIO)
	var logo: Image = _render(svg, logo_size)
	var canvas: Image = Image.create_empty(ADAPTIVE_SIZE, ADAPTIVE_SIZE, false, Image.FORMAT_RGBA8)
	var offset: int = floori((ADAPTIVE_SIZE - logo_size) / 2.0)
	canvas.blend_rect(logo, Rect2i(Vector2i.ZERO, logo.get_size()), Vector2i(offset, offset))
	return canvas


func _solid(size: int, color: Color) -> Image:
	var image: Image = Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return image


## Pose l'image sur un fond plein (aucun pixel transparent).
func _opaque(image: Image, background: Color) -> Image:
	var flat: Image = _solid(image.get_width(), background)
	flat.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i.ZERO)
	flat.convert(Image.FORMAT_RGB8)
	return flat


func _save(image: Image, file_name: String) -> bool:
	var path: String = OUTPUT_DIR.path_join(file_name)
	var err: Error = image.save_png(path)
	if err != OK:
		push_error("[icons] Écriture impossible : %s (%s)" % [path, error_string(err)])
		return false
	print("[icons] %s (%dx%d)" % [path, image.get_width(), image.get_height()])
	return true
