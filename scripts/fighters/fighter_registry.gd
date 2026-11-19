class_name FighterRegistry
extends RefCounted
## Liste des combattants jouables et chargement sécurisé de leurs données.

const K_BLAZE: StringName = &"k_blaze"
const AMAZONE: StringName = &"amazone"

## Ordre d'affichage dans l'écran de sélection.
const ROSTER: Array[StringName] = [K_BLAZE, AMAZONE]

const DATA_PATHS: Dictionary = {
	K_BLAZE: "res://data/fighters/k_blaze.tres",
	AMAZONE: "res://data/fighters/amazone.tres",
}


static func has_fighter(fighter_id: StringName) -> bool:
	return DATA_PATHS.has(fighter_id)


## Charge et valide les données d'un combattant. Retourne null (avec erreur) en cas d'échec.
static func load_fighter(fighter_id: StringName) -> FighterData:
	if not has_fighter(fighter_id):
		push_error("[FighterRegistry] Combattant inconnu : %s" % fighter_id)
		return null
	var path: String = DATA_PATHS[fighter_id]
	if not ResourceLoader.exists(path):
		push_error("[FighterRegistry] Données introuvables : %s" % path)
		return null
	var data: FighterData = load(path) as FighterData
	if data == null:
		push_error("[FighterRegistry] %s n'est pas un FighterData" % path)
		return null
	var issues: PackedStringArray = data.validate()
	if not issues.is_empty():
		push_error("[FighterRegistry] %s invalide : %s" % [path, " | ".join(issues)])
		return null
	return data


## Adversaire par défaut : le premier combattant du roster différent du joueur.
static func pick_opponent(player_id: StringName) -> StringName:
	for fighter_id: StringName in ROSTER:
		if fighter_id != player_id:
			return fighter_id
	return player_id
