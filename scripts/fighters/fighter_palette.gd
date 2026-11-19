class_name FighterPalette
extends RefCounted
## Matériau de recoloration des sprites de combattant (shaders/fighter_palette.gdshader).
## Chaque combattant reçoit son propre matériau : ses paramètres (flash d'impact) sont
## animés indépendamment de ceux de l'adversaire.

const SHADER_PATH: String = "res://shaders/fighter_palette.gdshader"
const PARAM_OUTFIT: StringName = &"outfit_color"
const PARAM_SKIN: StringName = &"skin_color"
const PARAM_ACCENT: StringName = &"accent_color"
const PARAM_FLASH: StringName = &"flash_amount"


static func make_material(data: FighterData) -> ShaderMaterial:
	var shader: Shader = load(SHADER_PATH) as Shader
	if shader == null:
		push_error("[FighterPalette] Shader introuvable : %s" % SHADER_PATH)
		return null
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter(PARAM_OUTFIT, data.outfit_color)
	material.set_shader_parameter(PARAM_SKIN, data.skin_color)
	material.set_shader_parameter(PARAM_ACCENT, data.accent_color)
	material.set_shader_parameter(PARAM_FLASH, 0.0)
	return material
