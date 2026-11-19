class_name GameConstants
extends RefCounted
## Paramètres globaux du jeu.
##
## Toute valeur de règle ou de configuration partagée entre plusieurs systèmes vit ici,
## pour éviter les valeurs magiques dispersées. Les valeurs propres à un combattant ou à
## une attaque vivent dans les ressources de data/ (FighterData, MoveData…).

# --- Simulation ------------------------------------------------------------------------
## La logique de combat avance par frames fixes à cette fréquence (_physics_process).
## Les durées d'attaque (startup / active / recovery) sont exprimées dans cette unité.
const SIMULATION_FPS: int = 60
## Durée d'une frame de simulation, en secondes.
const FRAME_DURATION: float = 1.0 / SIMULATION_FPS

# --- Affichage -------------------------------------------------------------------------
## Résolution de référence de toute l'interface et des arènes.
const REFERENCE_RESOLUTION: Vector2i = Vector2i(1920, 1080)
## Taille de fenêtre utilisée sur ordinateur pour les tests (16:9).
const DESKTOP_TEST_WINDOW: Vector2i = Vector2i(1280, 720)

# --- Règles de combat ------------------------------------------------------------------
const MAX_HEALTH: int = 1000
const ROUND_TIME_SECONDS: int = 99
const ROUNDS_TO_WIN: int = 2
## Nombre de niveaux de la jauge spéciale.
const SUPER_GAUGE_LEVELS: int = 3
## Points de jauge nécessaires pour remplir un niveau.
const SUPER_GAUGE_POINTS_PER_LEVEL: int = 100
const SUPER_GAUGE_MAX: int = SUPER_GAUGE_LEVELS * SUPER_GAUGE_POINTS_PER_LEVEL

# --- Audio -----------------------------------------------------------------------------
const BUS_MASTER: StringName = &"Master"
const BUS_MUSIC: StringName = &"Music"
const BUS_SFX: StringName = &"SFX"
const BUS_VOICE: StringName = &"Voice"
## Bus créés en plus de Master, tous routés vers Master.
const AUDIO_SUB_BUSES: Array[StringName] = [BUS_MUSIC, BUS_SFX, BUS_VOICE]

# --- Camps -----------------------------------------------------------------------------
const SIDE_P1: int = 0
const SIDE_P2: int = 1
const NO_SIDE: int = -1

# --- Moteur de combat (durées en frames de simulation) ----------------------------------
## Tolérance : une commande pressée jusqu'à N frames trop tôt reste valable.
const INPUT_BUFFER_FRAMES: int = 6
## Poing + Pied pressés dans cette fenêtre = projection.
const THROW_INPUT_WINDOW_FRAMES: int = 3
## Durée sur laquelle le recul (pushback) d'un impact est appliqué.
const PUSHBACK_FRAMES: int = 8
## Temps passé au sol après une chute, puis durée du relevé (invulnérable).
const KNOCKDOWN_FRAMES: int = 40
const GETUP_FRAMES: int = 24
## Éjection d'un combattant touché en l'air, et lors d'un KO (x = s'éloigne de l'attaquant).
const AIR_HIT_LAUNCH: Vector2 = Vector2(260.0, -700.0)
const KO_LAUNCH: Vector2 = Vector2(420.0, -950.0)
## Part de la jauge gagnée par le défenseur, relative au gain de l'attaquant.
const DEFENDER_GAUGE_RATIO: float = 0.5
## Distance horizontale maximale entre les deux combattants (cadre de la caméra).
const MAX_FIGHTER_SEPARATION: float = 1500.0
## Distance à partir de laquelle un combattant est considéré « dos au mur ».
const WALL_PROXIMITY: float = 4.0
## Plafond de manches si les égalités s'enchaînent.
const MAX_ROUNDS: int = 5
## Gel des deux combattants quand une posture de contre se déclenche.
const COUNTER_HIT_STOP_FRAMES: int = 14
## Un combo est annoncé à partir de ce nombre d'impacts.
const COMBO_MIN_HITS: int = 2

# --- Scènes ----------------------------------------------------------------------------
const SCENE_BOOT: String = "res://scenes/boot/boot.tscn"
const SCENE_MAIN_MENU: String = "res://scenes/menus/main_menu.tscn"
const SCENE_CHARACTER_SELECT: String = "res://scenes/menus/character_select.tscn"
const SCENE_FIGHT: String = "res://scenes/combat/fight_scene.tscn"
const SCENE_RESULTS: String = "res://scenes/menus/results.tscn"
const SCENE_OPTIONS: String = "res://scenes/menus/options_menu.tscn"
const SCENE_FIGHTER: String = "res://scenes/characters/fighter.tscn"
const SCENE_STAGE_ABIDJAN: String = "res://scenes/stages/abidjan_stage.tscn"
## Durée de chaque moitié du fondu entre deux écrans (secondes).
const SCENE_FADE_DURATION: float = 0.25
