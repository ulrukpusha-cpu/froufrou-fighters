class_name ProjectConfigCheck
extends RefCounted
## Vérifie que la configuration critique du projet est cohérente avec le code
## (GameConstants, InputActions, PhysicsLayers).
##
## Appelé au démarrage par l'écran de boot et par les tests. Une incohérence signifie
## généralement que tools/configure_project.gd n'a pas été relancé après une modification.

const RENDERER_COMPATIBILITY: String = "gl_compatibility"
const REQUIRED_AUTOLOADS: PackedStringArray = ["GameSession", "SceneRouter", "SaveManager"]


## Retourne la liste des problèmes détectés (vide si tout est cohérent).
static func run() -> PackedStringArray:
	var issues := PackedStringArray()
	_check_display(issues)
	_check_simulation(issues)
	_check_rendering(issues)
	_check_input_map(issues)
	_check_physics_layers(issues)
	_check_audio_buses(issues)
	_check_main_scene(issues)
	_check_autoloads_and_theme(issues)
	return issues


static func _check_autoloads_and_theme(issues: PackedStringArray) -> void:
	for autoload_name: String in REQUIRED_AUTOLOADS:
		if not ProjectSettings.has_setting("autoload/%s" % autoload_name):
			issues.append("Autoload manquant : %s" % autoload_name)
	var theme_path: String = ProjectSettings.get_setting("gui/theme/custom", "")
	if theme_path != UIThemeBuilder.THEME_PATH or not ResourceLoader.exists(theme_path):
		issues.append("Thème global absent (%s)" % theme_path)


static func _check_display(issues: PackedStringArray) -> void:
	var expected: Vector2i = GameConstants.REFERENCE_RESOLUTION
	var width: int = ProjectSettings.get_setting("display/window/size/viewport_width", 0)
	var height: int = ProjectSettings.get_setting("display/window/size/viewport_height", 0)
	if Vector2i(width, height) != expected:
		issues.append("Résolution de référence %dx%d au lieu de %s" % [width, height, expected])
	var orientation: int = ProjectSettings.get_setting("display/window/handheld/orientation", -1)
	if orientation != DisplayServer.SCREEN_SENSOR_LANDSCAPE:
		issues.append("Orientation mobile non paysage (%d)" % orientation)


static func _check_simulation(issues: PackedStringArray) -> void:
	if Engine.physics_ticks_per_second != GameConstants.SIMULATION_FPS:
		issues.append(
			"Fréquence physique %d au lieu de %d"
			% [Engine.physics_ticks_per_second, GameConstants.SIMULATION_FPS]
		)


static func _check_rendering(issues: PackedStringArray) -> void:
	var mobile_renderer: String = ProjectSettings.get_setting(
		"rendering/renderer/rendering_method.mobile", ""
	)
	if mobile_renderer != RENDERER_COMPATIBILITY:
		issues.append("Moteur de rendu mobile « %s » au lieu de Compatibility" % mobile_renderer)
	if not ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc", false):
		issues.append("Compression de textures ETC2/ASTC désactivée (requise sur mobile)")


static func _check_input_map(issues: PackedStringArray) -> void:
	for action: StringName in InputActions.ALL_ACTIONS:
		if not InputMap.has_action(action):
			issues.append("Action d'entrée manquante : %s" % action)
		elif InputMap.action_get_events(action).is_empty():
			issues.append("Action d'entrée sans liaison : %s" % action)


static func _check_physics_layers(issues: PackedStringArray) -> void:
	for layer_number: int in PhysicsLayers.LAYER_NAMES:
		var key: String = "layer_names/2d_physics/layer_%d" % layer_number
		var actual: String = ProjectSettings.get_setting(key, "")
		var expected: String = PhysicsLayers.LAYER_NAMES[layer_number]
		if actual != expected:
			issues.append("Couche physique %d nommée « %s » au lieu de « %s »" % [layer_number, actual, expected])


static func _check_audio_buses(issues: PackedStringArray) -> void:
	for bus_name: StringName in GameConstants.AUDIO_SUB_BUSES:
		if AudioServer.get_bus_index(bus_name) == -1:
			issues.append("Bus audio manquant : %s" % bus_name)


static func _check_main_scene(issues: PackedStringArray) -> void:
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene", "")
	if main_scene != GameConstants.SCENE_BOOT:
		issues.append("Scène principale « %s » au lieu de %s" % [main_scene, GameConstants.SCENE_BOOT])
	elif not ResourceLoader.exists(main_scene):
		issues.append("Scène principale introuvable : %s" % main_scene)
