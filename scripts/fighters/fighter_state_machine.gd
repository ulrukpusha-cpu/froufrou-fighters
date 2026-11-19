class_name FighterStateMachine
extends RefCounted
## Machine à états d'un combattant : état courant, durée passée dans l'état, transitions
## signalées. Les états VICTORY et DEFEAT sont terminaux jusqu'à reset() (nouvelle manche).

signal state_changed(previous: Fighter.State, current: Fighter.State)

## États dans lesquels le combattant accepte de nouvelles actions au sol.
const ACTIONABLE_STATES: Array[Fighter.State] = [
	Fighter.State.IDLE, Fighter.State.WALK, Fighter.State.CROUCH, Fighter.State.BLOCK,
]
const TERMINAL_STATES: Array[Fighter.State] = [Fighter.State.VICTORY, Fighter.State.DEFEAT]

var current: Fighter.State = Fighter.State.IDLE
var previous: Fighter.State = Fighter.State.IDLE
var frames_in_state: int = 0


## Change d'état. restart = vrai relance l'état même s'il est déjà actif (ex. nouveau hitstun).
## Retourne faux si la transition est refusée (état terminal).
func change(next: Fighter.State, restart: bool = false) -> bool:
	if next == current and not restart:
		return true
	if current in TERMINAL_STATES and next not in TERMINAL_STATES:
		return false
	previous = current
	current = next
	frames_in_state = 0
	state_changed.emit(previous, current)
	return true


## Retour forcé à IDLE (début de manche), y compris depuis un état terminal.
func reset() -> void:
	previous = current
	current = Fighter.State.IDLE
	frames_in_state = 0
	state_changed.emit(previous, current)


func tick() -> void:
	frames_in_state += 1


func is_actionable() -> bool:
	return current in ACTIONABLE_STATES


static func get_state_name(state: Fighter.State) -> String:
	return Fighter.State.keys()[state]
