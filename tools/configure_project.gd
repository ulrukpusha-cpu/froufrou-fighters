extends SceneTree
## Outil headless de configuration du projet (Phase 1).
##
## Applique de façon reproductible tous les paramètres du projet (affichage, rendu
## mobile, simulation, entrées, couches physiques, bus audio) à partir des constantes
## du code, puis sauvegarde project.godot. À relancer après toute modification de
## GameConstants, InputActions, PhysicsLayers ou UIPalette.
##
## Usage, depuis le dossier FROUFROU_FIGHTERS :
##   godot --headless --path . --script res://tools/configure_project.gd

# preload() plutôt que class_name : cet outil doit fonctionner avant la toute première
# importation, quand le cache des classes globales n'existe pas encore.
const GameConstantsScript := preload("res://scripts/systems/game_constants.gd")
const InputActionsScript := preload("res://scripts/systems/input_actions.gd")
const PhysicsLayersScript := preload("res://scripts/systems/physics_layers.gd")
const UIPaletteScript := preload("res://scripts/ui/ui_palette.gd")
const UIThemeBuilderScript := preload("res://scripts/ui/ui_theme_builder.gd")

## Autoloads, justifiés par un état qui doit survivre aux changements de scène.
## Le préfixe « * » les rend accessibles par leur nom dans tout script.
const AUTOLOADS: Dictionary = {
	"GameSession": "*res://scripts/systems/game_session.gd",
	"SceneRouter": "*res://scripts/systems/scene_router.gd",
	# Après GameSession : il y applique les réglages sauvegardés.
	"SaveManager": "*res://scripts/systems/save_manager.gd",
}

const BUS_LAYOUT_PATH: String = "res://default_bus_layout.tres"
const GODOT_FEATURES: PackedStringArray = ["4.7", "GL Compatibility"]
const RENDERER: String = "gl_compatibility"
## Valeur de display/window/handheld/orientation : paysage, retournable par le capteur.
const ORIENTATION_SENSOR_LANDSCAPE: int = DisplayServer.SCREEN_SENSOR_LANDSCAPE
## Niveau « Erreur » d'un avertissement GDScript.
const WARNING_LEVEL_ERROR: int = 2


func _initialize() -> void:
	var exit_code: int = 0
	if not _write_bus_layout():
		exit_code = 1
	if not _write_theme():
		exit_code = 1
	_apply_settings(_build_settings())
	_apply_input_map()
	var err: Error = ProjectSettings.save()
	if err != OK:
		push_error("[configure] Échec de la sauvegarde de project.godot : %s" % error_string(err))
		exit_code = 1
	else:
		print("[configure] project.godot mis à jour.")
	quit(exit_code)


func _build_settings() -> Dictionary:
	var resolution: Vector2i = GameConstantsScript.REFERENCE_RESOLUTION
	var test_window: Vector2i = GameConstantsScript.DESKTOP_TEST_WINDOW
	var settings: Dictionary = {
		# --- Application ---
		"application/config/name": "FROUFROU FIGHTERS",
		"application/config/description":
			"Jeu de combat arcade 2.5D ancré dans l'Afrique de l'Ouest contemporaine.",
		"application/config/version": "0.1.0",
		"application/config/features": GODOT_FEATURES,
		"application/config/icon": "res://icon.svg",
		"application/config/use_custom_user_dir": true,
		"application/config/custom_user_dir_name": "FroufrouFighters",
		"application/run/main_scene": GameConstantsScript.SCENE_BOOT,
		"application/run/max_fps": GameConstantsScript.SIMULATION_FPS,
		"application/boot_splash/bg_color": UIPaletteScript.CHARCOAL,
		"application/boot_splash/show_image": false,
		# --- Affichage : 1920x1080 de référence, paysage, adaptation aux ratios mobiles ---
		"display/window/size/viewport_width": resolution.x,
		"display/window/size/viewport_height": resolution.y,
		"display/window/size/window_width_override": test_window.x,
		"display/window/size/window_height_override": test_window.y,
		"display/window/stretch/mode": "canvas_items",
		"display/window/stretch/aspect": "expand",
		"display/window/handheld/orientation": ORIENTATION_SENSOR_LANDSCAPE,
		"display/window/energy_saving/keep_screen_on": true,
		# --- Rendu : Compatibility (OpenGL ES 3) = meilleure couverture 2D mobile ---
		"rendering/renderer/rendering_method": RENDERER,
		"rendering/renderer/rendering_method.mobile": RENDERER,
		"rendering/textures/vram_compression/import_etc2_astc": true,
		"rendering/environment/defaults/default_clear_color": UIPaletteScript.CHARCOAL,
		# --- Simulation : logique de combat à pas fixe ---
		"physics/common/physics_ticks_per_second": GameConstantsScript.SIMULATION_FPS,
		# --- Entrées : la souris émule le tactile pour tester les commandes sur PC ---
		"input_devices/pointing/emulate_touch_from_mouse": true,
		"input_devices/pointing/emulate_mouse_from_touch": true,
		# --- Qualité du code : toute déclaration non typée est une erreur ---
		"debug/gdscript/warnings/untyped_declaration": WARNING_LEVEL_ERROR,
		# --- Audio ---
		"audio/buses/default_bus_layout": BUS_LAYOUT_PATH,
		# --- Interface : thème global généré depuis la palette ---
		"gui/theme/custom": UIThemeBuilderScript.THEME_PATH,
	}
	for autoload_name: String in AUTOLOADS:
		settings["autoload/%s" % autoload_name] = AUTOLOADS[autoload_name]
	for layer_number: int in PhysicsLayersScript.LAYER_NAMES:
		var key: String = "layer_names/2d_physics/layer_%d" % layer_number
		settings[key] = PhysicsLayersScript.LAYER_NAMES[layer_number]
	return settings


func _apply_settings(settings: Dictionary) -> void:
	for key: String in settings:
		ProjectSettings.set_setting(key, settings[key])


func _apply_input_map() -> void:
	for action: StringName in InputActionsScript.ALL_ACTIONS:
		var key: String = "input/%s" % action
		ProjectSettings.set_setting(key, InputActionsScript.build_project_setting(action))


func _write_theme() -> bool:
	var theme: Theme = UIThemeBuilderScript.build()
	var err: Error = ResourceSaver.save(theme, UIThemeBuilderScript.THEME_PATH)
	if err != OK:
		push_error("[configure] Échec de l'écriture du thème : %s" % error_string(err))
		return false
	print("[configure] %s écrit." % UIThemeBuilderScript.THEME_PATH)
	return true


## Crée les bus Music / SFX / Voice routés vers Master et sauvegarde le layout.
func _write_bus_layout() -> bool:
	for bus_name: StringName in GameConstantsScript.AUDIO_SUB_BUSES:
		var index: int = AudioServer.get_bus_index(bus_name)
		if index == -1:
			AudioServer.add_bus()
			index = AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, GameConstantsScript.BUS_MASTER)
	var layout: AudioBusLayout = AudioServer.generate_bus_layout()
	var err: Error = ResourceSaver.save(layout, BUS_LAYOUT_PATH)
	if err != OK:
		push_error("[configure] Échec de l'écriture de %s : %s" % [BUS_LAYOUT_PATH, error_string(err)])
		return false
	print("[configure] %s écrit." % BUS_LAYOUT_PATH)
	return true
