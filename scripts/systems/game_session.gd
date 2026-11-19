extends Node
## État de la partie partagé entre les écrans (autoload « GameSession »).
##
## Justification de l'autoload : la sélection des combattants doit survivre au passage
## sélection → combat, et le résultat au passage combat → résultats.

signal selection_changed(player_fighter_id: StringName, opponent_fighter_id: StringName)
signal result_recorded(result: MatchResult)

## Mode de commandes du joueur (sera sauvegardé avec les réglages en Phase 10).
var control_mode: PlayerController.Mode = PlayerController.Mode.CLASSIC
## Affichage des commandes tactiles (sera réglable dans les options en Phase 10).
var touch_controls: TouchControls.Visibility = TouchControls.Visibility.AUTO
## Difficulté de l'adversaire IA (sera sauvegardée avec les réglages en Phase 10).
var difficulty: AIProfile.Difficulty = AIProfile.Difficulty.NORMAL
var stage_id: StringName = StageRegistry.ABIDJAN_PLATEAU
var player_fighter_id: StringName = FighterRegistry.K_BLAZE
var opponent_fighter_id: StringName = FighterRegistry.AMAZONE
## Résultat du dernier match terminé (null si aucun).
var last_result: MatchResult = null


## Enregistre la sélection. Refuse (et retourne faux) un identifiant inconnu.
func set_selection(player_id: StringName, opponent_id: StringName) -> bool:
	if not FighterRegistry.has_fighter(player_id) or not FighterRegistry.has_fighter(opponent_id):
		push_error("[GameSession] Sélection invalide : %s contre %s" % [player_id, opponent_id])
		return false
	player_fighter_id = player_id
	opponent_fighter_id = opponent_id
	selection_changed.emit(player_id, opponent_id)
	return true


func record_result(result: MatchResult) -> void:
	last_result = result
	result_recorded.emit(result)
