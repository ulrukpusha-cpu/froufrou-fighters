class_name FighterController
extends Node
## Source des commandes d'un combattant.
##
## Le combattant ne sait pas qui le pilote : joueur, IA ou script. Chaque frame, il appelle
## poll() qui remplit out_frame. Un contrôleur ne reçoit que l'état COURANT des deux
## combattants : une IA n'a jamais accès aux commandes futures du joueur.
## La classe de base ne presse rien : c'est le mannequin d'entraînement.


func poll(_fighter: Fighter, _opponent: Fighter, out_frame: InputFrame) -> void:
	out_frame.clear()


## Oublie l'état interne (appelé au début de chaque manche).
func reset() -> void:
	pass
