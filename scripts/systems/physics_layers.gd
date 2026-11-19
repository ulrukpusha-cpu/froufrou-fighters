class_name PhysicsLayers
extends RefCounted
## Couches de collision 2D du jeu.
##
## Les bitmasks ci-dessous doivent correspondre aux noms déclarés dans
## project.godot (layer_names/2d_physics/*), écrits par tools/configure_project.gd.
## Couche N  ->  bitmask 1 << (N - 1).

## Sol et murs invisibles de l'arène.
const STAGE_BOUNDS: int = 1 << 0
## Boîte de poussée des combattants (ils ne se traversent pas).
const FIGHTER_BODY: int = 1 << 1
## Zones offensives, actives uniquement pendant les frames actives d'une attaque.
const HITBOX: int = 1 << 2
## Zones vulnérables d'un combattant.
const HURTBOX: int = 1 << 3

## Noms affichés dans l'éditeur, indexés par numéro de couche (base 1).
const LAYER_NAMES: Dictionary = {
	1: "stage_bounds",
	2: "fighter_body",
	3: "hitbox",
	4: "hurtbox",
}
