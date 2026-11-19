class_name StageData
extends Resource
## Fiche d'une arène : identité et scène à charger. Les données physiques du plan de combat
## (largeur, positions de départ, limites de caméra) sont portées par le nœud Stage de la scène.

@export var id: StringName = &""
@export var display_name: String = ""
@export var city: String = ""
@export var district: String = ""
@export_multiline var description: String = ""
@export_file("*.tscn") var scene_path: String = ""


func validate() -> PackedStringArray:
	var issues := PackedStringArray()
	if id == &"":
		issues.append("arène sans identifiant")
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		issues.append("scène d'arène introuvable : %s" % scene_path)
	return issues
