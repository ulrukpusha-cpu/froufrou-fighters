extends TestCase
## Tous les scripts et toutes les scènes du jeu se chargent sans erreur.

const SCRIPT_ROOTS: PackedStringArray = ["res://scripts", "res://tools"]
const SCENE_ROOT: String = "res://scenes"


func test_every_script_compiles() -> void:
	var paths := PackedStringArray()
	for root: String in SCRIPT_ROOTS:
		_collect(root, ".gd", paths)
	assert_true(paths.size() > 10, "Trop peu de scripts trouvés (%d)" % paths.size())
	for path: String in paths:
		var script: GDScript = load(path) as GDScript
		assert_true(script != null and script.can_instantiate(), "Script invalide : %s" % path)


func test_every_scene_loads() -> void:
	var paths := PackedStringArray()
	_collect(SCENE_ROOT, ".tscn", paths)
	assert_true(paths.size() >= 7, "Scènes attendues : au moins 7 (%d)" % paths.size())
	for path: String in paths:
		var scene: PackedScene = load(path) as PackedScene
		assert_true(scene != null and scene.can_instantiate(), "Scène invalide : %s" % path)


func _collect(directory: String, extension: String, into: PackedStringArray) -> void:
	var dir: DirAccess = DirAccess.open(directory)
	if dir == null:
		return
	for sub_dir: String in dir.get_directories():
		_collect(directory.path_join(sub_dir), extension, into)
	for file_name: String in dir.get_files():
		if file_name.ends_with(extension):
			into.append(directory.path_join(file_name))
