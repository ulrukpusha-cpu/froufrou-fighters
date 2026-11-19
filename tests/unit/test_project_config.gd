extends TestCase
## Phase 1 : la configuration du projet respecte le cahier des charges.


func test_config_check_reports_no_issue() -> void:
	var issues: PackedStringArray = ProjectConfigCheck.run()
	assert_true(issues.is_empty(), "Configuration incohérente : %s" % " | ".join(issues))


func test_reference_resolution_and_stretch() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 1920, "Largeur")
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 1080, "Hauteur")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items", "Stretch mode")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "expand", "Stretch aspect")


func test_landscape_orientation() -> void:
	assert_eq(
		ProjectSettings.get_setting("display/window/handheld/orientation"),
		DisplayServer.SCREEN_SENSOR_LANDSCAPE,
		"Orientation paysage (capteur)"
	)


func test_simulation_runs_at_60_fps() -> void:
	assert_eq(GameConstants.SIMULATION_FPS, 60, "Fréquence cible")
	assert_eq(Engine.physics_ticks_per_second, 60, "Ticks physiques")
	assert_eq(ProjectSettings.get_setting("application/run/max_fps"), 60, "FPS max")


func test_combat_rules_match_spec() -> void:
	assert_eq(GameConstants.MAX_HEALTH, 1000, "Santé")
	assert_eq(GameConstants.ROUND_TIME_SECONDS, 99, "Timer")
	assert_eq(GameConstants.ROUNDS_TO_WIN, 2, "Manches gagnantes")
	assert_eq(GameConstants.SUPER_GAUGE_LEVELS, 3, "Niveaux de jauge")


func test_mobile_rendering() -> void:
	assert_eq(
		ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile"),
		"gl_compatibility",
		"Rendu mobile"
	)
	assert_true(
		ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc"),
		"Compression ETC2/ASTC"
	)


func test_typed_gdscript_is_enforced() -> void:
	assert_eq(
		ProjectSettings.get_setting("debug/gdscript/warnings/untyped_declaration"),
		2,
		"Les déclarations non typées doivent être des erreurs"
	)


func test_touch_emulation_for_desktop_testing() -> void:
	assert_true(
		ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse"),
		"La souris doit émuler le tactile"
	)


func test_palette_colors_are_distinct() -> void:
	var colors: Array[Color] = [
		UIPalette.BURNT_ORANGE, UIPalette.GOLD, UIPalette.DEEP_VIOLET,
		UIPalette.CHARCOAL, UIPalette.IVORY,
	]
	for i: int in colors.size():
		for j: int in range(i + 1, colors.size()):
			assert_true(colors[i] != colors[j], "Couleurs %d et %d identiques" % [i, j])
