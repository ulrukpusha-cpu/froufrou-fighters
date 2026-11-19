extends Node
## Sauvegarde locale du joueur (autoload « SaveManager »).
##
## Justification de l'autoload : réglages, commandes et progression doivent être chargés
## avant le premier écran et rester accessibles partout.
##
## Contenu : réglages (volumes, mode de commandes, difficulté, commandes tactiles, touches
## personnalisées), progression (combattants débloqués, victoires par difficulté) et
## statistiques du joueur.
##
## Structure évolutive :
## - champ « version » + _migrate() pour transformer les anciennes sauvegardes ;
## - fusion avec default_data() : une clé manquante est complétée, une clé de mauvais type
##   est remplacée, une clé inconnue (version future) est conservée ;
## - écriture atomique (fichier temporaire puis renommage) ; un fichier illisible est mis de
##   côté (.corrupt) au lieu d'être écrasé.

signal settings_changed
signal stats_changed

const SAVE_VERSION: int = 1
const DEFAULT_PATH: String = "user://save.json"
const TEMP_SUFFIX: String = ".tmp"
const CORRUPT_SUFFIX: String = ".corrupt"
## Les écritures demandées sont regroupées (ex. glisser un curseur de volume).
const SAVE_DELAY: float = 0.5
const DEFAULT_VOLUME: float = 1.0
const DEFAULT_MUSIC_VOLUME: float = 0.8
const MIN_VOLUME_DB: float = -60.0

var save_path: String = DEFAULT_PATH
var data: Dictionary = {}

var _save_timer: Timer = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = SAVE_DELAY
	_save_timer.timeout.connect(save)
	add_child(_save_timer)
	load_save()
	apply_all()


func _notification(what: int) -> void:
	# Fermeture de l'application ou mise en arrière-plan sur mobile : on écrit tout de suite.
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		flush()


# --- Fichier ----------------------------------------------------------------------------

static func default_data() -> Dictionary:
	var unlocked: Array = []
	for fighter_id: StringName in FighterRegistry.ROSTER:
		unlocked.append(String(fighter_id))
	return {
		"version": SAVE_VERSION,
		"settings": {
			"volumes": {
				String(GameConstants.BUS_MASTER): DEFAULT_VOLUME,
				String(GameConstants.BUS_MUSIC): DEFAULT_MUSIC_VOLUME,
				String(GameConstants.BUS_SFX): DEFAULT_VOLUME,
				String(GameConstants.BUS_VOICE): DEFAULT_VOLUME,
			},
			"control_mode": PlayerController.Mode.CLASSIC,
			"difficulty": AIProfile.Difficulty.NORMAL,
			"touch_controls": TouchControls.Visibility.AUTO,
			"bindings": {},
		},
		"progress": {
			"unlocked_fighters": unlocked,
			"wins_by_difficulty": {"0": 0, "1": 0, "2": 0},
		},
		"stats": {
			"matches_played": 0, "matches_won": 0, "matches_lost": 0, "matches_drawn": 0,
			"rounds_won": 0, "rounds_lost": 0, "best_combo": 0,
			"fighters": {},
		},
	}


## Charge la sauvegarde (ou les valeurs par défaut). Retourne faux si le fichier existait
## mais était illisible.
func load_save() -> bool:
	data = default_data()
	if not FileAccess.file_exists(save_path):
		return true
	var text: String = FileAccess.get_file_as_string(save_path)
	var json := JSON.new()
	var parsed: Variant = json.data if json.parse(text) == OK else null
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("[SaveManager] Sauvegarde illisible, mise de côté : %s" % save_path)
		DirAccess.rename_absolute(save_path, save_path + CORRUPT_SUFFIX)
		return false
	data = _migrate(parsed)
	_merge_defaults(data, default_data())
	data["version"] = SAVE_VERSION
	return true


## Écrit la sauvegarde de façon atomique. Retourne faux en cas d'échec.
func save() -> bool:
	var temp_path: String = save_path + TEMP_SUFFIX
	var file: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] Écriture impossible : %s (%s)" % [temp_path, error_string(FileAccess.get_open_error())])
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	var err: Error = DirAccess.rename_absolute(temp_path, save_path)
	if err != OK:
		push_error("[SaveManager] Renommage impossible : %s" % error_string(err))
		return false
	return true


## Demande une écriture groupée (dans SAVE_DELAY secondes).
func request_save() -> void:
	if _save_timer != null and _save_timer.is_inside_tree():
		_save_timer.start()
	else:
		save()


## Écrit immédiatement si une écriture était en attente.
func flush() -> void:
	if _save_timer != null and not _save_timer.is_stopped():
		_save_timer.stop()
		save()


## Change de fichier (tests) ; reset = repartir des valeurs par défaut sans lire le fichier.
func use_save_path(path: String, reset: bool) -> void:
	flush()
	save_path = path
	if reset:
		data = default_data()
	else:
		load_save()
	apply_all()


func reset_to_defaults() -> void:
	data = default_data()
	apply_all()
	request_save()


## Transforme une sauvegarde d'une version antérieure. Version 0 = fichier sans champ
## « version » (prototype) : la fusion avec les valeurs par défaut suffit.
func _migrate(raw: Dictionary) -> Dictionary:
	var version: int = int(raw.get("version", 0))
	if version > SAVE_VERSION:
		push_warning("[SaveManager] Sauvegarde d'une version plus récente (%d) : champs inconnus conservés" % version)
	return raw


## Complète « target » avec « defaults » : clés manquantes ajoutées, types incompatibles
## remplacés, entiers relus comme flottants par JSON reconvertis. Clés inconnues conservées.
## Un dictionnaire par défaut vide (ex. touches personnalisées) est une table libre.
static func _merge_defaults(target: Dictionary, defaults: Dictionary) -> void:
	for key: Variant in defaults:
		var default_value: Variant = defaults[key]
		if not target.has(key):
			target[key] = _copy(default_value)
			continue
		var value: Variant = target[key]
		var default_type: int = typeof(default_value)
		if default_type == TYPE_INT and typeof(value) == TYPE_FLOAT:
			target[key] = int(value)
		elif default_type == TYPE_FLOAT and typeof(value) == TYPE_INT:
			target[key] = float(value)
		elif typeof(value) != default_type:
			target[key] = _copy(default_value)
		elif default_type == TYPE_DICTIONARY and not (default_value as Dictionary).is_empty():
			_merge_defaults(value as Dictionary, default_value as Dictionary)


static func _copy(value: Variant) -> Variant:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	if value is Array:
		return (value as Array).duplicate(true)
	return value


# --- Réglages ---------------------------------------------------------------------------

## Applique tous les réglages : volumes, session (modes, difficulté), touches.
func apply_all() -> void:
	var settings: Dictionary = data["settings"]
	for bus_name: String in (settings["volumes"] as Dictionary):
		_apply_volume(StringName(bus_name), get_volume(StringName(bus_name)))
	GameSession.control_mode = clampi(int(settings["control_mode"]), 0, PlayerController.Mode.size() - 1) as PlayerController.Mode
	GameSession.difficulty = clampi(int(settings["difficulty"]), 0, AIProfile.Difficulty.size() - 1) as AIProfile.Difficulty
	GameSession.touch_controls = clampi(int(settings["touch_controls"]), 0, TouchControls.Visibility.size() - 1) as TouchControls.Visibility
	_apply_bindings()
	settings_changed.emit()


func get_volume(bus: StringName) -> float:
	var volumes: Dictionary = data["settings"]["volumes"]
	return clampf(float(volumes.get(String(bus), DEFAULT_VOLUME)), 0.0, 1.0)


## Volume linéaire 0..1 d'un bus audio (appliqué immédiatement, sauvegarde groupée).
func set_volume(bus: StringName, linear: float) -> void:
	var value: float = clampf(linear, 0.0, 1.0)
	data["settings"]["volumes"][String(bus)] = value
	_apply_volume(bus, value)
	request_save()


func set_control_mode(mode: PlayerController.Mode) -> void:
	data["settings"]["control_mode"] = mode
	GameSession.control_mode = mode
	_settings_updated()


func set_difficulty(level: AIProfile.Difficulty) -> void:
	data["settings"]["difficulty"] = level
	GameSession.difficulty = level
	_settings_updated()


func set_touch_controls(visibility: TouchControls.Visibility) -> void:
	data["settings"]["touch_controls"] = visibility
	GameSession.touch_controls = visibility
	_settings_updated()


func _apply_volume(bus: StringName, linear: float) -> void:
	var index: int = AudioServer.get_bus_index(bus)
	if index == -1:
		return
	AudioServer.set_bus_mute(index, linear <= 0.0)
	AudioServer.set_bus_volume_db(index, maxf(linear_to_db(linear), MIN_VOLUME_DB) if linear > 0.0 else MIN_VOLUME_DB)


func _settings_updated() -> void:
	settings_changed.emit()
	request_save()


# --- Touches ----------------------------------------------------------------------------

## Remplace la touche clavier d'une action (code physique). Une touche déjà utilisée par
## une autre action lui est retirée : jamais deux actions sur la même touche.
func set_binding_key(action: StringName, physical_keycode: int) -> void:
	for other: StringName in InputActions.ALL_ACTIONS:
		var keys: Array[int] = InputActions.get_keys(other)
		if other != action and physical_keycode in keys:
			keys.erase(physical_keycode)
			_store_binding(other, keys, InputActions.get_buttons(other))
	var single_key: Array[int] = [physical_keycode]
	_store_binding(action, single_key, InputActions.get_buttons(action))
	_settings_updated()


## Remplace le bouton de manette d'une action (même règle d'unicité).
func set_binding_button(action: StringName, button: int) -> void:
	for other: StringName in InputActions.ALL_ACTIONS:
		var buttons: Array[int] = InputActions.get_buttons(other)
		if other != action and button in buttons:
			buttons.erase(button)
			_store_binding(other, InputActions.get_keys(other), buttons)
	var single_button: Array[int] = [button]
	_store_binding(action, InputActions.get_keys(action), single_button)
	_settings_updated()


func reset_bindings() -> void:
	data["settings"]["bindings"] = {}
	InputActions.restore_defaults()
	_settings_updated()


func _store_binding(action: StringName, keys: Array[int], buttons: Array[int]) -> void:
	data["settings"]["bindings"][String(action)] = {"keys": keys.duplicate(), "buttons": buttons.duplicate()}
	InputActions.apply_bindings(action, keys, buttons)


func _apply_bindings() -> void:
	InputActions.restore_defaults()
	var bindings: Dictionary = data["settings"]["bindings"]
	for action_name: String in bindings:
		var action := StringName(action_name)
		var entry: Variant = bindings[action_name]
		if action not in InputActions.ALL_ACTIONS or typeof(entry) != TYPE_DICTIONARY:
			continue
		InputActions.apply_bindings(action, _to_int_array((entry as Dictionary).get("keys", [])),
			_to_int_array((entry as Dictionary).get("buttons", [])))


static func _to_int_array(values: Variant) -> Array[int]:
	var result: Array[int] = []
	if values is Array:
		for value: Variant in values:
			if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
				result.append(int(value))
	return result


# --- Progression et statistiques --------------------------------------------------------

func is_fighter_unlocked(fighter_id: StringName) -> bool:
	return String(fighter_id) in (data["progress"]["unlocked_fighters"] as Array)


func unlock_fighter(fighter_id: StringName) -> void:
	if not is_fighter_unlocked(fighter_id) and FighterRegistry.has_fighter(fighter_id):
		(data["progress"]["unlocked_fighters"] as Array).append(String(fighter_id))
		request_save()


## Enregistre un match terminé du point de vue du joueur 1.
func record_match(result: MatchResult, level: AIProfile.Difficulty, best_combo: int) -> void:
	var stats: Dictionary = data["stats"]
	stats["matches_played"] = int(stats["matches_played"]) + 1
	if result.is_draw():
		stats["matches_drawn"] = int(stats["matches_drawn"]) + 1
	elif result.player_won():
		stats["matches_won"] = int(stats["matches_won"]) + 1
		var wins: Dictionary = data["progress"]["wins_by_difficulty"]
		var key: String = str(int(level))
		wins[key] = int(wins.get(key, 0)) + 1
	else:
		stats["matches_lost"] = int(stats["matches_lost"]) + 1
	stats["rounds_won"] = int(stats["rounds_won"]) + result.rounds_won[GameConstants.SIDE_P1]
	stats["rounds_lost"] = int(stats["rounds_lost"]) + result.rounds_won[GameConstants.SIDE_P2]
	stats["best_combo"] = maxi(int(stats["best_combo"]), best_combo)
	var fighter_key: String = String(result.fighter_ids[GameConstants.SIDE_P1])
	var fighters: Dictionary = stats["fighters"]
	var entry: Dictionary = fighters.get(fighter_key, {"played": 0, "won": 0})
	entry["played"] = int(entry.get("played", 0)) + 1
	if result.player_won():
		entry["won"] = int(entry.get("won", 0)) + 1
	fighters[fighter_key] = entry
	stats_changed.emit()
	request_save()


## Copie des statistiques (lecture seule pour l'interface).
func get_stats() -> Dictionary:
	return (data["stats"] as Dictionary).duplicate(true)


func get_wins_by_difficulty(level: AIProfile.Difficulty) -> int:
	return int((data["progress"]["wins_by_difficulty"] as Dictionary).get(str(int(level)), 0))
