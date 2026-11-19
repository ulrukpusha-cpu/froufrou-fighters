extends SceneTree
## Lanceur de tests headless.
##
## Usage, depuis le dossier FROUFROU_FIGHTERS (après une première importation) :
##   godot --headless --path . --script res://tests/run_tests.gd
## Code de sortie : 0 si tous les tests passent, 1 sinon.

const TEST_DIRECTORIES: PackedStringArray = ["res://tests/unit", "res://tests/integration"]
const TEST_FILE_PREFIX: String = "test_"
const TEST_METHOD_PREFIX: String = "test_"
const SCRIPT_EXTENSION: String = ".gd"
const SAVE_MANAGER_PATH: String = "/root/SaveManager"
const TEST_SAVE_PATH: String = "user://tests_save.json"

var _passed: int = 0
var _failed: int = 0


func _initialize() -> void:
	# Exécution différée : l'arbre (root) doit être prêt avant d'y ajouter des nœuds.
	_run_all.call_deferred()


func _run_all() -> void:
	# Les tests ne touchent jamais la sauvegarde du joueur : fichier dédié, valeurs par défaut.
	var save_manager: Node = root.get_node_or_null(SAVE_MANAGER_PATH)
	if save_manager != null:
		save_manager.call("use_save_path", TEST_SAVE_PATH, true)
	var files: PackedStringArray = PackedStringArray()
	for directory: String in TEST_DIRECTORIES:
		_collect_test_files(directory, files)
	files.sort()
	print("\n=== FROUFROU FIGHTERS — tests (%d fichiers) ===" % files.size())
	for path: String in files:
		await _run_file(path)
	print("\n=== Résultat : %d réussis, %d échoués ===" % [_passed, _failed])
	if save_manager != null:
		save_manager.call("flush")
	for path: String in [TEST_SAVE_PATH, TEST_SAVE_PATH + ".tmp", TEST_SAVE_PATH + ".corrupt"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	quit(0 if _failed == 0 and _passed > 0 else 1)


func _collect_test_files(directory: String, into: PackedStringArray) -> void:
	var dir: DirAccess = DirAccess.open(directory)
	if dir == null:
		push_error("[tests] Dossier introuvable : %s" % directory)
		return
	for sub_dir: String in dir.get_directories():
		_collect_test_files(directory.path_join(sub_dir), into)
	for file_name: String in dir.get_files():
		if file_name.begins_with(TEST_FILE_PREFIX) and file_name.ends_with(SCRIPT_EXTENSION):
			into.append(directory.path_join(file_name))


func _run_file(path: String) -> void:
	print("\n%s" % path)
	var script: GDScript = load(path) as GDScript
	if script == null or not script.can_instantiate():
		_record(path, "chargement", PackedStringArray(["script invalide ou non compilable"]))
		return
	var test_case: TestCase = script.new() as TestCase
	if test_case == null:
		_record(path, "chargement", PackedStringArray(["le fichier doit étendre TestCase"]))
		return
	test_case.tree = self
	for method: Dictionary in script.get_script_method_list():
		var method_name: String = method["name"]
		if not method_name.begins_with(TEST_METHOD_PREFIX):
			continue
		# Appels dynamiques : before_each / after_each peuvent être des coroutines
		# (ex. attendre une frame que les conteneurs d'interface calculent leur mise en page).
		await test_case.call("before_each")
		await test_case.call(method_name)
		await test_case.call("after_each")
		_record(path, method_name, test_case.take_failures())


func _record(_path: String, test_name: String, failures: PackedStringArray) -> void:
	if failures.is_empty():
		_passed += 1
		print("  [OK]    %s" % test_name)
		return
	_failed += 1
	print("  [ÉCHEC] %s" % test_name)
	for failure: String in failures:
		print("          - %s" % failure)
