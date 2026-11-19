class_name AIProfile
extends Resource
## Réglages d'une difficulté d'IA. Les trois difficultés sont des fichiers de data/ai/ :
## on équilibre l'IA sans toucher au code.
## Toutes les probabilités sont tirées au plus une fois par situation (par attaque perçue,
## par décision), avec un générateur à graine fixe : un combat est reproductible.

enum Difficulty { EASY, NORMAL, HARD }

const PROFILE_PATHS: Dictionary = {
	Difficulty.EASY: "res://data/ai/easy.tres",
	Difficulty.NORMAL: "res://data/ai/normal.tres",
	Difficulty.HARD: "res://data/ai/hard.tres",
}

@export var difficulty: Difficulty = Difficulty.NORMAL
@export var display_name: String = "NORMAL"

@export_group("Rythme")
## Retard de perception : l'IA voit l'adversaire tel qu'il était il y a N frames.
@export_range(0, 60) var reaction_frames: int = 12
## Intervalle entre deux décisions en situation neutre.
@export_range(1, 60) var decision_interval_frames: int = 12

@export_group("Attaque")
## Probabilité d'attaquer quand l'adversaire est à portée.
@export_range(0.0, 1.0) var aggression: float = 0.45
## Probabilité de poursuivre un enchaînement quand un coup touche.
@export_range(0.0, 1.0) var combo_chance: float = 0.5
## Probabilité de lancer l'attaque spéciale en neutre (hors posture de contre).
@export_range(0.0, 1.0) var special_chance: float = 0.12
## Probabilité d'utiliser l'ultime quand elle est disponible et qu'elle peut toucher.
@export_range(0.0, 1.0) var ultimate_chance: float = 0.5
## Probabilité de projeter un adversaire en garde au corps à corps.
@export_range(0.0, 1.0) var throw_chance: float = 0.2
@export_range(0.0, 1.0) var jump_chance: float = 0.08

@export_group("Défense")
## Probabilité de se mettre en garde face à une attaque perçue (ou une menace à portée).
@export_range(0.0, 1.0) var block_chance: float = 0.45
## Probabilité de choisir la bonne hauteur de garde (haute / basse).
@export_range(0.0, 1.0) var guard_accuracy: float = 0.7
## Probabilité de punir une attaque en phase de récupération.
@export_range(0.0, 1.0) var punish_chance: float = 0.35
## Probabilité d'utiliser une posture de contre face à une attaque lente.
@export_range(0.0, 1.0) var counter_chance: float = 0.3
## Probabilité d'esquiver une attaque ultime ou lourde.
@export_range(0.0, 1.0) var dodge_chance: float = 0.1
## Gère la distance : recule parfois pour rester juste hors de portée (footsies).
@export var manages_spacing: bool = true


## Charge le profil d'une difficulté. En cas d'échec, l'erreur est signalée et un profil
## NORMAL par défaut est retourné : le combat reste jouable.
static func load_profile(level: Difficulty) -> AIProfile:
	var path: String = PROFILE_PATHS.get(level, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		push_error("[AIProfile] Profil introuvable pour la difficulté %d" % level)
		return AIProfile.new()
	var profile: AIProfile = load(path) as AIProfile
	if profile == null:
		push_error("[AIProfile] %s n'est pas un AIProfile" % path)
		return AIProfile.new()
	return profile
