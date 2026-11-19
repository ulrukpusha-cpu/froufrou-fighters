class_name MatchResult
extends RefCounted
## Résultat d'un match, transmis de la scène de combat à l'écran des résultats.

## Camp vainqueur (GameConstants.SIDE_P1 / SIDE_P2) ou GameConstants.NO_SIDE en cas d'égalité.
var winner_side: int = GameConstants.NO_SIDE
## Identifiants des combattants, indexés par camp.
var fighter_ids: Array[StringName] = [&"", &""]
## Manches gagnées, indexées par camp.
var rounds_won: Array[int] = [0, 0]
var rounds_played: int = 0


func is_draw() -> bool:
	return winner_side == GameConstants.NO_SIDE


## Vrai si le joueur 1 (le joueur humain en mode arcade) a gagné.
func player_won() -> bool:
	return winner_side == GameConstants.SIDE_P1


func get_winner_id() -> StringName:
	return &"" if is_draw() else fighter_ids[winner_side]
