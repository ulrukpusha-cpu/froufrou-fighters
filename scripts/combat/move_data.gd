class_name MoveData
extends Resource
## Description complète d'une attaque, configurable sans toucher au moteur.
##
## Chronologie (en frames à 60 FPS) : la frame 1 est la première frame de l'attaque.
##   startup  : frames 1 .. startup_frames                    (préparation, aucune hitbox)
##   active   : startup_frames + 1 .. startup_frames + active_frames   (hitboxes possibles)
##   recovery : les recovery_frames suivantes                 (vulnérable, aucune hitbox)

## Hauteur de l'attaque, qui détermine comment la parer.
enum HitLevel {
	MID, ## Se pare debout ou accroupi.
	LOW, ## Se pare uniquement accroupi.
	OVERHEAD, ## Se pare uniquement debout (attaques sautées).
}

## Quand l'attaque peut être annulée dans une autre (combos).
enum CancelCondition {
	NEVER,
	ON_HIT, ## Seulement si l'attaque a touché sans être parée.
	ON_HIT_OR_BLOCK, ## Si l'attaque a touché ou a été parée.
	ALWAYS, ## Dès la première frame active, même dans le vide.
}

enum Phase { STARTUP, ACTIVE, RECOVERY, FINISHED }

## Famille de l'attaque (annonces du HUD, décisions de l'IA).
enum Category { NORMAL, SPECIAL, ULTIMATE }

@export var id: StringName = &""
@export var display_name: String = ""
@export var category: Category = Category.NORMAL
## Animation jouée (nom dans le SpriteFrames du combattant).
@export var animation: StringName = &"punch"
## Vrai pour les attaques accroupies (boîte vulnérable basse).
@export var crouching: bool = false

@export_group("Timing")
@export_range(1, 60) var startup_frames: int = 4
@export_range(1, 60) var active_frames: int = 3
@export_range(0, 120) var recovery_frames: int = 10

@export_group("Impact")
@export_range(0, 1000) var damage: int = 40
## Dégâts infligés même si l'attaque est parée (ne peut pas mettre KO).
@export_range(0, 1000) var chip_damage: int = 0
@export_range(0, 120) var hitstun_frames: int = 14
@export_range(0, 120) var blockstun_frames: int = 10
## Gel des deux combattants à l'impact (sensation de puissance).
@export_range(0, 30) var hit_stop_frames: int = 6
## Distance de recul imposée au défenseur (pixels).
@export_range(0.0, 600.0) var pushback: float = 60.0
@export var hit_level: HitLevel = HitLevel.MID
## Fait chuter l'adversaire au lieu d'un simple hitstun. Pour une attaque multi-coups,
## seul le dernier impact fait chuter (les précédents enchaînent en hitstun).
@export var knockdown: bool = false
## Éjection en cas de chute (x = s'éloigne de l'attaquant, y négatif = vers le haut).
@export var launch_velocity: Vector2 = Vector2(350.0, -900.0)
## Nombre maximal d'impacts sur une même cible (1 = un seul impact par attaque).
@export_range(1, 10) var max_hits: int = 1
## Frames minimales entre deux impacts sur la même cible (attaques multi-coups).
@export_range(0, 60) var rehit_interval_frames: int = 0

@export_group("Jauge")
@export_range(0, 300) var gauge_gain_on_hit: int = 8
@export_range(0, 300) var gauge_gain_on_block: int = 4
@export_range(0, 300) var gauge_cost: int = 0

@export_group("Annulations")
@export var cancel_condition: CancelCondition = CancelCondition.NEVER
## Identifiants des attaques dans lesquelles celle-ci peut être annulée.
@export var cancel_into: Array[StringName] = []

@export_group("Mouvement")
## Vitesse propre pendant startup + active (x = vers l'avant), en pixels/seconde.
@export var self_velocity: Vector2 = Vector2.ZERO

@export_group("Projection")
## Projection : imparable, ne touche qu'un adversaire au sol et hors hitstun / blockstun.
@export var is_throw: bool = false

@export_group("Invulnérabilité")
## Frames d'invulnérabilité à partir de la première frame (ex. démarrage d'une ultime).
@export_range(0, 60) var invulnerable_frames: int = 0

@export_group("Contre")
## Les frames actives forment une posture de contre : une frappe reçue (hors projection et
## ultime) est annulée, l'attaquant est sonné et counter_follow_up part aussitôt.
@export var counter_window: bool = false
@export var counter_follow_up: MoveData
## Durée pendant laquelle l'attaquant contré reste sonné (hitstun).
@export_range(0, 120) var counter_stun_frames: int = 30

@export_group("Hitboxes")
@export var hitboxes: Array[HitboxData] = []


func is_special() -> bool:
	return category != Category.NORMAL


## Peut être annulée par une posture de contre (les projections et les ultimes passent).
func is_counterable() -> bool:
	return not is_throw and category != Category.ULTIMATE


func get_total_frames() -> int:
	return startup_frames + active_frames + recovery_frames


func get_first_active_frame() -> int:
	return startup_frames + 1


func get_phase(frame: int) -> Phase:
	if frame <= startup_frames:
		return Phase.STARTUP
	if frame <= startup_frames + active_frames:
		return Phase.ACTIVE
	if frame <= get_total_frames():
		return Phase.RECOVERY
	return Phase.FINISHED


func validate() -> PackedStringArray:
	var issues := PackedStringArray()
	var label: String = String(id) if id != &"" else "(sans id)"
	if id == &"":
		issues.append("attaque sans identifiant")
	if hitboxes.is_empty() and not counter_window:
		issues.append("%s : aucune hitbox" % label)
	if counter_window:
		if counter_follow_up == null:
			issues.append("%s : posture de contre sans riposte" % label)
		elif counter_follow_up != self:
			issues.append_array(counter_follow_up.validate())
	for hitbox: HitboxData in hitboxes:
		if hitbox == null:
			issues.append("%s : hitbox vide" % label)
			continue
		for issue: String in hitbox.validate():
			issues.append("%s : %s" % [label, issue])
	if max_hits > 1 and rehit_interval_frames < 1:
		issues.append("%s : plusieurs impacts exigent un intervalle >= 1 frame" % label)
	if chip_damage > damage:
		issues.append("%s : dégâts sur garde supérieurs aux dégâts" % label)
	return issues
