extends SceneTree
## Génère les sprites de test des combattants (SVG) et leur SpriteFrames (Phase 3).
##
## Chaque pose est décrite par ses articulations (texture 320x432, combattant tourné vers
## la droite, pieds en y = 410). Les zones sont encodées par canal de couleur
## (R = tenue, G = peau, B = accessoires) puis recolorées en jeu par
## shaders/fighter_palette.gdshader : un seul jeu de sprites sert à tous les combattants.
##
## Usage : godot --headless --path . --script res://tools/generate_placeholder_sprites.gd
## puis   : godot --headless --path . --import

const OUTPUT_DIR: String = "res://assets/fighters/placeholder"
const SPRITE_FRAMES_PATH: String = "res://assets/fighters/placeholder/placeholder_frames.tres"
## Pieds en y = 410 : le centre de la texture (y = 216) est 194 px au-dessus des pieds,
## d'où FighterData.sprite_offset = (0, -194).
const CANVAS: Vector2i = Vector2i(320, 432)

const TORSO_WIDTH: float = 56.0
const LEG_WIDTH: float = 34.0
const ARM_WIDTH: float = 24.0
const OUTLINE_WIDTH: float = 5.0
const HEAD_RADIUS: float = 28.0
const HAND_RADIUS: float = 13.0
const FOOT_RADIUS: float = 14.0
const BELT_HALF: float = 26.0
const BAND_HALF: float = 27.0
const SHOULDER_DROP: Vector2 = Vector2(0.0, 14.0)

const OUTFIT: String = "#ff0000"
const OUTFIT_BACK: String = "#a60000"
const SKIN: String = "#00ff00"
const SKIN_BACK: String = "#00a600"
const ACCENT: String = "#0000ff"
const ACCENT_BACK: String = "#0000a6"
const OUTLINE: String = "#000000"

## Articulations : hip, neck, head, ef/hf (coude/main avant), eb/hb (arrière),
## kf/ff (genou/pied avant), kb/fb (arrière).
const POSES: Dictionary = {
	"idle_0": {"hip": Vector2(160, 262), "neck": Vector2(168, 152), "head": Vector2(174, 118), "ef": Vector2(205, 190), "hf": Vector2(232, 160), "eb": Vector2(148, 200), "hb": Vector2(192, 176), "kf": Vector2(200, 330), "ff": Vector2(218, 410), "kb": Vector2(138, 335), "fb": Vector2(112, 410)},
	"idle_1": {"hip": Vector2(160, 267), "neck": Vector2(168, 157), "head": Vector2(174, 123), "ef": Vector2(205, 195), "hf": Vector2(232, 165), "eb": Vector2(148, 205), "hb": Vector2(192, 181), "kf": Vector2(200, 333), "ff": Vector2(218, 410), "kb": Vector2(138, 338), "fb": Vector2(112, 410)},
	"walk_0": {"hip": Vector2(160, 262), "neck": Vector2(170, 152), "head": Vector2(176, 118), "ef": Vector2(207, 190), "hf": Vector2(234, 160), "eb": Vector2(150, 200), "hb": Vector2(194, 176), "kf": Vector2(205, 330), "ff": Vector2(232, 410), "kb": Vector2(130, 332), "fb": Vector2(100, 410)},
	"walk_1": {"hip": Vector2(160, 258), "neck": Vector2(170, 148), "head": Vector2(176, 114), "ef": Vector2(207, 186), "hf": Vector2(234, 156), "eb": Vector2(150, 196), "hb": Vector2(194, 172), "kf": Vector2(178, 332), "ff": Vector2(170, 410), "kb": Vector2(160, 330), "fb": Vector2(150, 410)},
	"jump": {"hip": Vector2(160, 230), "neck": Vector2(166, 125), "head": Vector2(172, 92), "ef": Vector2(200, 150), "hf": Vector2(222, 116), "eb": Vector2(140, 160), "hb": Vector2(126, 128), "kf": Vector2(206, 250), "ff": Vector2(190, 316), "kb": Vector2(182, 276), "fb": Vector2(140, 312)},
	"crouch": {"hip": Vector2(155, 330), "neck": Vector2(172, 235), "head": Vector2(184, 204), "ef": Vector2(210, 268), "hf": Vector2(238, 240), "eb": Vector2(160, 276), "hb": Vector2(205, 256), "kf": Vector2(216, 346), "ff": Vector2(222, 410), "kb": Vector2(126, 374), "fb": Vector2(104, 410)},
	"punch": {"hip": Vector2(160, 262), "neck": Vector2(176, 152), "head": Vector2(184, 121), "ef": Vector2(226, 150), "hf": Vector2(288, 148), "eb": Vector2(150, 196), "hb": Vector2(186, 180), "kf": Vector2(206, 330), "ff": Vector2(228, 410), "kb": Vector2(134, 335), "fb": Vector2(100, 410)},
	"kick": {"hip": Vector2(150, 262), "neck": Vector2(122, 160), "head": Vector2(110, 129), "ef": Vector2(156, 190), "hf": Vector2(178, 166), "eb": Vector2(96, 200), "hb": Vector2(80, 176), "kf": Vector2(216, 232), "ff": Vector2(292, 214), "kb": Vector2(150, 336), "fb": Vector2(146, 410)},
	"crouch_punch": {"hip": Vector2(155, 330), "neck": Vector2(180, 236), "head": Vector2(194, 206), "ef": Vector2(232, 246), "hf": Vector2(290, 240), "eb": Vector2(166, 272), "hb": Vector2(206, 258), "kf": Vector2(216, 346), "ff": Vector2(222, 410), "kb": Vector2(126, 374), "fb": Vector2(104, 410)},
	"low_kick": {"hip": Vector2(150, 336), "neck": Vector2(130, 240), "head": Vector2(124, 208), "ef": Vector2(166, 270), "hf": Vector2(190, 250), "eb": Vector2(110, 290), "hb": Vector2(100, 370), "kf": Vector2(214, 372), "ff": Vector2(292, 402), "kb": Vector2(110, 364), "fb": Vector2(124, 410)},
	"air_punch": {"hip": Vector2(160, 230), "neck": Vector2(174, 126), "head": Vector2(182, 95), "ef": Vector2(226, 136), "hf": Vector2(284, 140), "eb": Vector2(150, 160), "hb": Vector2(190, 150), "kf": Vector2(206, 250), "ff": Vector2(190, 316), "kb": Vector2(182, 276), "fb": Vector2(140, 312)},
	"air_kick": {"hip": Vector2(150, 222), "neck": Vector2(126, 122), "head": Vector2(118, 90), "ef": Vector2(160, 152), "hf": Vector2(186, 132), "eb": Vector2(100, 152), "hb": Vector2(86, 122), "kf": Vector2(214, 254), "ff": Vector2(286, 284), "kb": Vector2(160, 282), "fb": Vector2(120, 302)},
	"block": {"hip": Vector2(155, 262), "neck": Vector2(160, 152), "head": Vector2(163, 120), "ef": Vector2(202, 176), "hf": Vector2(194, 116), "eb": Vector2(192, 196), "hb": Vector2(204, 132), "kf": Vector2(198, 330), "ff": Vector2(216, 410), "kb": Vector2(136, 335), "fb": Vector2(110, 410)},
	"crouch_block": {"hip": Vector2(150, 330), "neck": Vector2(160, 236), "head": Vector2(166, 204), "ef": Vector2(202, 252), "hf": Vector2(196, 200), "eb": Vector2(192, 270), "hb": Vector2(206, 216), "kf": Vector2(212, 346), "ff": Vector2(220, 410), "kb": Vector2(124, 374), "fb": Vector2(102, 410)},
	"hit": {"hip": Vector2(150, 264), "neck": Vector2(122, 162), "head": Vector2(102, 138), "ef": Vector2(150, 192), "hf": Vector2(176, 216), "eb": Vector2(96, 186), "hb": Vector2(70, 206), "kf": Vector2(186, 334), "ff": Vector2(206, 410), "kb": Vector2(126, 336), "fb": Vector2(104, 410)},
	"knockdown": {"hip": Vector2(190, 382), "neck": Vector2(96, 384), "head": Vector2(60, 382), "ef": Vector2(124, 360), "hf": Vector2(146, 338), "eb": Vector2(84, 400), "hb": Vector2(40, 404), "kf": Vector2(250, 364), "ff": Vector2(302, 394), "kb": Vector2(244, 392), "fb": Vector2(296, 406)},
	"dodge": {"hip": Vector2(130, 268), "neck": Vector2(96, 170), "head": Vector2(80, 141), "ef": Vector2(130, 202), "hf": Vector2(160, 186), "eb": Vector2(76, 216), "hb": Vector2(60, 242), "kf": Vector2(176, 336), "ff": Vector2(200, 410), "kb": Vector2(100, 340), "fb": Vector2(74, 410)},
	"throw": {"hip": Vector2(165, 262), "neck": Vector2(186, 156), "head": Vector2(196, 126), "ef": Vector2(236, 176), "hf": Vector2(276, 192), "eb": Vector2(226, 196), "hb": Vector2(266, 212), "kf": Vector2(216, 330), "ff": Vector2(236, 410), "kb": Vector2(140, 335), "fb": Vector2(110, 410)},
	"special": {"hip": Vector2(150, 282), "neck": Vector2(206, 186), "head": Vector2(226, 159), "ef": Vector2(256, 192), "hf": Vector2(302, 176), "eb": Vector2(162, 216), "hb": Vector2(120, 236), "kf": Vector2(216, 330), "ff": Vector2(242, 410), "kb": Vector2(110, 330), "fb": Vector2(60, 402)},
	"ultimate": {"hip": Vector2(160, 262), "neck": Vector2(160, 150), "head": Vector2(160, 116), "ef": Vector2(202, 112), "hf": Vector2(216, 60), "eb": Vector2(118, 112), "hb": Vector2(104, 60), "kf": Vector2(212, 330), "ff": Vector2(238, 410), "kb": Vector2(108, 330), "fb": Vector2(82, 410)},
	"victory": {"hip": Vector2(160, 262), "neck": Vector2(160, 150), "head": Vector2(162, 117), "ef": Vector2(196, 110), "hf": Vector2(206, 54), "eb": Vector2(130, 200), "hb": Vector2(150, 232), "kf": Vector2(180, 336), "ff": Vector2(186, 410), "kb": Vector2(140, 336), "fb": Vector2(134, 410)},
	"counter": {"hip": Vector2(158, 262), "neck": Vector2(164, 152), "head": Vector2(168, 119), "ef": Vector2(206, 160), "hf": Vector2(238, 128), "eb": Vector2(186, 190), "hb": Vector2(220, 170), "kf": Vector2(204, 330), "ff": Vector2(226, 410), "kb": Vector2(132, 336), "fb": Vector2(104, 410)},
	"counter_strike": {"hip": Vector2(165, 268), "neck": Vector2(196, 166), "head": Vector2(212, 138), "ef": Vector2(244, 170), "hf": Vector2(300, 160), "eb": Vector2(170, 206), "hb": Vector2(140, 226), "kf": Vector2(228, 326), "ff": Vector2(258, 410), "kb": Vector2(128, 330), "fb": Vector2(80, 406)},
	"defeat": {"hip": Vector2(150, 334), "neck": Vector2(176, 248), "head": Vector2(196, 232), "ef": Vector2(190, 292), "hf": Vector2(196, 338), "eb": Vector2(166, 296), "hb": Vector2(172, 342), "kf": Vector2(202, 342), "ff": Vector2(206, 410), "kb": Vector2(140, 404), "fb": Vector2(84, 410)},
}

## Animations : [nom, poses, images/seconde, en boucle].
const ANIMATIONS: Array = [
	["idle", ["idle_0", "idle_1"], 3.0, true],
	["walk", ["walk_0", "walk_1"], 6.0, true],
	["jump", ["jump"], 1.0, false],
	["crouch", ["crouch"], 1.0, false],
	["punch", ["punch"], 1.0, false],
	["kick", ["kick"], 1.0, false],
	["crouch_punch", ["crouch_punch"], 1.0, false],
	["low_kick", ["low_kick"], 1.0, false],
	["air_punch", ["air_punch"], 1.0, false],
	["air_kick", ["air_kick"], 1.0, false],
	["block", ["block"], 1.0, false],
	["crouch_block", ["crouch_block"], 1.0, false],
	["hit", ["hit"], 1.0, false],
	["knockdown", ["knockdown"], 1.0, false],
	["getup", ["crouch"], 1.0, false],
	["dodge", ["dodge"], 1.0, false],
	["throw", ["throw"], 1.0, false],
	["special", ["special"], 1.0, false],
	["ultimate", ["ultimate"], 1.0, false],
	["counter", ["counter"], 1.0, false],
	["counter_strike", ["counter_strike"], 1.0, false],
	["victory", ["victory"], 1.0, false],
	["defeat", ["defeat"], 1.0, false],
]


func _initialize() -> void:
	var exit_code: int = 0
	var err: Error = DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	if err != OK:
		push_error("[sprites] Dossier impossible à créer : %s" % error_string(err))
		quit(1)
		return
	for pose_name: String in POSES:
		if not _write_text("%s/%s.svg" % [OUTPUT_DIR, pose_name], _build_svg(POSES[pose_name])):
			exit_code = 1
	if not _write_text(SPRITE_FRAMES_PATH, _build_sprite_frames()):
		exit_code = 1
	print("[sprites] %d poses et %s générés." % [POSES.size(), SPRITE_FRAMES_PATH])
	quit(exit_code)


func _build_svg(pose: Dictionary) -> String:
	var hip: Vector2 = pose["hip"]
	var neck: Vector2 = pose["neck"]
	var head: Vector2 = pose["head"]
	var shoulder: Vector2 = neck + SHOULDER_DROP
	var parts := PackedStringArray()
	parts.append('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">' % [CANVAS.x, CANVAS.y, CANVAS.x, CANVAS.y])
	# Arrière-plan : bras et jambe arrière (teintes sombres).
	_limb(parts, [shoulder, pose["eb"], pose["hb"]], ARM_WIDTH, SKIN_BACK)
	_dot(parts, pose["hb"], HAND_RADIUS, ACCENT_BACK)
	_limb(parts, [hip, pose["kb"], pose["fb"]], LEG_WIDTH, OUTFIT_BACK)
	_dot(parts, pose["fb"], FOOT_RADIUS, ACCENT_BACK)
	# Torse et ceinture.
	_limb(parts, [neck, hip], TORSO_WIDTH, OUTFIT)
	_band(parts, hip, (neck - hip).normalized(), BELT_HALF, 12.0)
	# Premier plan : jambe et bras avant, tête et bandeau.
	_limb(parts, [hip, pose["kf"], pose["ff"]], LEG_WIDTH, OUTFIT)
	_dot(parts, pose["ff"], FOOT_RADIUS, ACCENT)
	_limb(parts, [shoulder, pose["ef"], pose["hf"]], ARM_WIDTH, SKIN)
	_dot(parts, pose["hf"], HAND_RADIUS, ACCENT)
	_dot(parts, head, HEAD_RADIUS, SKIN)
	var head_dir: Vector2 = (head - neck).normalized()
	_band(parts, head + head_dir * 8.0, head_dir, BAND_HALF, 9.0)
	parts.append("</svg>")
	return "\n".join(parts)


## Membre : contour noir épais puis trait coloré, extrémités arrondies.
func _limb(parts: PackedStringArray, points: Array, width: float, color: String) -> void:
	var coords := PackedStringArray()
	for point: Vector2 in points:
		coords.append("%.1f,%.1f" % [point.x, point.y])
	var joined: String = " ".join(coords)
	var style: String = 'fill="none" stroke-linecap="round" stroke-linejoin="round"'
	parts.append('<polyline points="%s" %s stroke="%s" stroke-width="%.1f"/>' % [joined, style, OUTLINE, width + OUTLINE_WIDTH * 2.0])
	parts.append('<polyline points="%s" %s stroke="%s" stroke-width="%.1f"/>' % [joined, style, color, width])


func _dot(parts: PackedStringArray, center: Vector2, radius: float, color: String) -> void:
	parts.append('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s" stroke="%s" stroke-width="%.1f"/>' % [center.x, center.y, radius, color, OUTLINE, OUTLINE_WIDTH])


## Bande d'accessoire perpendiculaire à « axis » (ceinture, bandeau).
func _band(parts: PackedStringArray, center: Vector2, axis: Vector2, half_length: float, width: float) -> void:
	var perpendicular := Vector2(-axis.y, axis.x) * half_length
	var a: Vector2 = center - perpendicular
	var b: Vector2 = center + perpendicular
	parts.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="%.1f" stroke-linecap="round"/>' % [a.x, a.y, b.x, b.y, ACCENT, width])


func _build_sprite_frames() -> String:
	var lines := PackedStringArray()
	lines.append("[gd_resource type=\"SpriteFrames\" format=3]")
	lines.append("")
	for pose_name: String in POSES:
		lines.append("[ext_resource type=\"Texture2D\" path=\"%s/%s.svg\" id=\"%s\"]" % [OUTPUT_DIR, pose_name, pose_name])
	lines.append("")
	lines.append("[resource]")
	var animations := PackedStringArray()
	for entry: Array in ANIMATIONS:
		var frames := PackedStringArray()
		for pose_name: String in entry[1]:
			frames.append("{\n\"duration\": 1.0,\n\"texture\": ExtResource(\"%s\")\n}" % pose_name)
		animations.append("{\n\"frames\": [%s],\n\"loop\": %s,\n\"name\": &\"%s\",\n\"speed\": %.1f\n}" % [
			", ".join(frames), "true" if entry[3] else "false", entry[0], entry[2]
		])
	lines.append("animations = [%s]" % ", ".join(animations))
	return "\n".join(lines) + "\n"


func _write_text(path: String, content: String) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("[sprites] Écriture impossible : %s (%s)" % [path, error_string(FileAccess.get_open_error())])
		return false
	file.store_string(content)
	file.close()
	return true
