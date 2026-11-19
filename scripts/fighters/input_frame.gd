class_name InputFrame
extends RefCounted
## Commandes d'un combattant pour une frame de simulation.
##
## Les directions sont en coordonnées écran (x : -1 gauche / 1 droite ; y : -1 haut /
## 1 bas) : c'est le combattant qui les traduit en avant / arrière selon son orientation.
## Les instances sont réutilisées d'une frame à l'autre (aucune allocation en combat).

const PUNCH: int = 1 << 0
const KICK: int = 1 << 1
const SPECIAL: int = 1 << 2
const GUARD: int = 1 << 3
const DODGE: int = 1 << 4
## Poing + Pied ensemble = projection.
const THROW_BUTTONS: int = PUNCH | KICK
## Bouton virtuel, ajouté par le combattant dans sa mémoire de commandes : Spécial pressé
## AVEC Bas (= ultime). Ainsi l'intention survit au tampon, même si Bas est relâché avant
## que l'attaque ne parte (enchaînement pendant un gel d'impact).
const SPECIAL_DOWN: int = 1 << 5

var direction: Vector2i = Vector2i.ZERO
## Boutons maintenus pendant cette frame.
var held: int = 0
## Boutons enfoncés à cette frame précise (front montant).
var pressed: int = 0


func clear() -> void:
	direction = Vector2i.ZERO
	held = 0
	pressed = 0


## Remplit la frame ; « pressed » est déduit des boutons maintenus à la frame précédente.
func set_from(new_direction: Vector2i, held_buttons: int, previous_held: int) -> void:
	direction = new_direction
	held = held_buttons
	pressed = held_buttons & ~previous_held


func is_held(button: int) -> bool:
	return (held & button) != 0


func is_pressed(button: int) -> bool:
	return (pressed & button) != 0
