class_name HitboxData
extends Resource
## Une zone offensive d'une attaque.
##
## Le rectangle est exprimé en pixels, relatif aux pieds du combattant tourné vers la
## droite (x positif = devant, y négatif = vers le haut). Il est miroité automatiquement
## quand le combattant regarde à gauche.

@export var rect: Rect2 = Rect2(40.0, -260.0, 90.0, 50.0)
## Décalage, en frames, depuis la première frame active de l'attaque.
@export_range(0, 60) var delay_frames: int = 0
## Durée d'activité en frames ; 0 = jusqu'à la fin des frames actives de l'attaque.
@export_range(0, 60) var duration_frames: int = 0


## active_index : 0 pour la première frame active de l'attaque.
func is_active_at(active_index: int, move_active_frames: int) -> bool:
	if active_index < delay_frames or active_index >= move_active_frames:
		return false
	return duration_frames == 0 or active_index < delay_frames + duration_frames


func validate() -> PackedStringArray:
	var issues := PackedStringArray()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		issues.append("taille de hitbox nulle")
	return issues
