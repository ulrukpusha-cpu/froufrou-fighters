class_name FighterPortrait
extends RefCounted
## Portrait d'un combattant pour le HUD.
## Avec une illustration (FighterData.portrait), elle est utilisée telle quelle. Sinon, la
## tête de la première image « idle » des sprites de test est découpée et recolorée.

## Zone de la tête dans les sprites de test (texture 320x432, voir generate_placeholder_sprites).
const PLACEHOLDER_REGION: Rect2 = Rect2(104.0, 48.0, 140.0, 140.0)
const PLACEHOLDER_ANIMATION: StringName = &"idle"


static func get_texture(data: FighterData) -> Texture2D:
	if data.portrait != null:
		return data.portrait
	if data.sprite_frames == null or not data.sprite_frames.has_animation(PLACEHOLDER_ANIMATION):
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = data.sprite_frames.get_frame_texture(PLACEHOLDER_ANIMATION, 0)
	atlas.region = PLACEHOLDER_REGION
	return atlas


## Matériau à appliquer au portrait (palette des sprites de test), null pour une illustration.
static func get_material(data: FighterData) -> Material:
	return FighterPalette.make_material(data) if data.portrait == null else null
