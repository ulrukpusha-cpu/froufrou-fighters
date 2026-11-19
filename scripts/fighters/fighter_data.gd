class_name FighterData
extends Resource
## Fiche complète d'un combattant : identité, visuel, statistiques, boîtes et attaques.
## Ajouter un combattant = créer un nouveau FighterData, sans modifier le moteur.

@export_group("Identité")
@export var id: StringName = &""
@export var display_name: String = ""
@export var origin: String = ""
@export var fighting_style: String = ""
@export var specialty_name: String = ""
@export_multiline var description: String = ""

@export_group("Visuel")
## Portrait du HUD (illustration définitive). Vide : la tête du sprite de test est utilisée.
@export var portrait: Texture2D
@export var sprite_frames: SpriteFrames
@export var sprite_scale: float = 1.0
## Décalage du sprite pour que ses pieds soient sur l'origine du combattant (pixels texture).
@export var sprite_offset: Vector2 = Vector2(0.0, -194.0)
## Couleurs appliquées par shaders/fighter_palette.gdshader (canaux R, G, B des sprites).
@export var outfit_color: Color = Color.WHITE
@export var skin_color: Color = Color.WHITE
@export var accent_color: Color = Color.WHITE

@export_group("Statistiques")
@export var max_health: int = GameConstants.MAX_HEALTH
## Vitesses en pixels/seconde, gravité en pixels/seconde².
@export var walk_speed: float = 360.0
@export var back_walk_speed: float = 280.0
@export var jump_velocity: float = 1500.0
@export var jump_forward_speed: float = 380.0
@export var gravity: float = 4200.0
@export var dodge_speed: float = 700.0
@export var dodge_frames: int = 18
@export var dodge_invulnerable_frames: int = 12

@export_group("Boîtes")
## Boîte de poussée (empêche les combattants de se traverser).
@export var body_size: Vector2 = Vector2(100.0, 300.0)
## Boîtes vulnérables, relatives aux pieds, combattant tourné vers la droite.
@export var standing_hurtbox: Rect2 = Rect2(-60.0, -350.0, 120.0, 350.0)
@export var crouching_hurtbox: Rect2 = Rect2(-65.0, -250.0, 130.0, 250.0)

@export_group("Attaques")
@export var light_attack: MoveData
@export var heavy_attack: MoveData
@export var crouch_light_attack: MoveData
@export var crouch_heavy_attack: MoveData
@export var air_light_attack: MoveData
@export var air_heavy_attack: MoveData
@export var throw_move: MoveData
## Bouton Spécial (gratuit).
@export var special_move: MoveData
## Bas + Spécial avec la jauge suffisante (gauge_cost de l'attaque).
@export var ultimate_move: MoveData


## Toutes les attaques, ripostes de contre comprises.
func get_all_moves() -> Array[MoveData]:
	var moves: Array[MoveData] = []
	for move: MoveData in [
		light_attack, heavy_attack, crouch_light_attack, crouch_heavy_attack,
		air_light_attack, air_heavy_attack, throw_move, special_move, ultimate_move,
	]:
		if move == null:
			continue
		moves.append(move)
		if move.counter_follow_up != null and move.counter_follow_up not in moves:
			moves.append(move.counter_follow_up)
	return moves


## Retourne la liste des problèmes (vide si le combattant est utilisable).
func validate() -> PackedStringArray:
	var issues := PackedStringArray()
	if id == &"":
		issues.append("combattant sans identifiant")
	if max_health <= 0:
		issues.append("santé maximale nulle")
	if sprite_frames == null:
		issues.append("aucun SpriteFrames")
	var required: Dictionary = {
		"attaque légère": light_attack, "attaque lourde": heavy_attack,
		"légère accroupie": crouch_light_attack, "lourde accroupie": crouch_heavy_attack,
		"légère sautée": air_light_attack, "lourde sautée": air_heavy_attack,
		"projection": throw_move,
		"attaque spéciale": special_move, "attaque ultime": ultimate_move,
	}
	for label: String in required:
		if required[label] == null:
			issues.append("%s manquante" % label)
	for move: MoveData in get_all_moves():
		issues.append_array(move.validate())
		if sprite_frames != null and not sprite_frames.has_animation(move.animation):
			issues.append("%s : animation « %s » absente" % [move.id, move.animation])
	if throw_move != null and not throw_move.is_throw:
		issues.append("la projection n'est pas marquée is_throw")
	if ultimate_move != null and ultimate_move.gauge_cost > GameConstants.SUPER_GAUGE_MAX:
		issues.append("l'ultime coûte plus que la jauge maximale")
	return issues
