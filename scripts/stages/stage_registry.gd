class_name StageRegistry
extends RefCounted
## Liste des arènes et chargement sécurisé.

const ABIDJAN_PLATEAU: StringName = &"abidjan_plateau"
const ROSTER: Array[StringName] = [ABIDJAN_PLATEAU]
const DATA_PATHS: Dictionary = {
	ABIDJAN_PLATEAU: "res://data/stages/abidjan_plateau.tres",
}


static func load_stage_data(stage_id: StringName) -> StageData:
	var path: String = DATA_PATHS.get(stage_id, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		push_error("[StageRegistry] Arène inconnue ou introuvable : %s" % stage_id)
		return null
	var data: StageData = load(path) as StageData
	if data == null:
		push_error("[StageRegistry] %s n'est pas un StageData" % path)
		return null
	var issues: PackedStringArray = data.validate()
	if not issues.is_empty():
		push_error("[StageRegistry] %s invalide : %s" % [path, " | ".join(issues)])
		return null
	return data


## Instancie la scène d'une arène. Retourne null (avec erreur) en cas d'échec.
static func instantiate_stage(stage_id: StringName) -> Stage:
	var data: StageData = load_stage_data(stage_id)
	if data == null:
		return null
	var packed: PackedScene = load(data.scene_path) as PackedScene
	var stage: Stage = packed.instantiate() as Stage if packed != null else null
	if stage == null:
		push_error("[StageRegistry] La scène %s n'a pas de nœud Stage à la racine" % data.scene_path)
		return null
	stage.display_name = data.display_name
	return stage
