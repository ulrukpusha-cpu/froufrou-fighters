extends TestCase
## Phase 1 : la scène de boot se charge, gère une scène suivante absente et sait
## charger une scène valide.

const BOOT_SCENE: String = "res://scenes/boot/boot.tscn"
const FIXTURE_SCENE: String = "res://tests/fixtures/empty_scene.tscn"
const MISSING_SCENE: String = "res://tests/fixtures/does_not_exist.tscn"
const MAX_WAIT_FRAMES: int = 300


func _instantiate_boot() -> Control:
	var packed: PackedScene = load(BOOT_SCENE) as PackedScene
	if packed == null:
		return null
	return packed.instantiate() as Control


func test_boot_scene_has_expected_nodes() -> void:
	var boot: Control = _instantiate_boot()
	assert_not_null(boot, "boot.tscn doit s'instancier")
	if boot == null:
		return
	for node_name: String in ["%Content", "%TitleLabel", "%StatusLabel", "%ProgressBar", "%VersionLabel"]:
		assert_not_null(boot.get_node_or_null(node_name), "Nœud manquant : %s" % node_name)
	boot.free()


func test_boot_reports_missing_next_scene() -> void:
	var boot: Control = _instantiate_boot()
	boot.set("next_scene_path", MISSING_SCENE)
	boot.set("auto_change_scene", false)
	var reasons: Array[String] = []
	boot.connect("boot_failed", func(reason: String) -> void: reasons.append(reason))
	print("          (l'erreur « Scène introuvable » qui suit est attendue)")
	tree.root.add_child(boot)
	assert_eq(reasons.size(), 1, "boot_failed doit être émis une fois")
	var status_label: Label = boot.get_node("%StatusLabel") as Label
	assert_true(status_label.text.contains("introuvable"), "Le message d'erreur doit être affiché")
	boot.queue_free()
	await wait_frames(1)


func test_boot_loads_valid_scene() -> void:
	var boot: Control = _instantiate_boot()
	boot.set("next_scene_path", FIXTURE_SCENE)
	boot.set("auto_change_scene", false)
	boot.set("minimum_display_time", 0.0)
	var completed: Array[String] = []
	boot.connect("boot_completed", func(path: String) -> void: completed.append(path))
	tree.root.add_child(boot)
	for i: int in MAX_WAIT_FRAMES:
		if not completed.is_empty():
			break
		await wait_frames(1)
	assert_eq(completed.size(), 1, "boot_completed doit être émis")
	if not completed.is_empty():
		assert_eq(completed[0], FIXTURE_SCENE, "Chemin de la scène chargée")
	var progress_bar: ProgressBar = boot.get_node("%ProgressBar") as ProgressBar
	assert_eq(progress_bar.value, progress_bar.max_value, "La barre doit être pleine")
	boot.queue_free()
	await wait_frames(1)
