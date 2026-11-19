extends Control
## Écran d'options ouvert depuis le menu principal : le panneau d'options en plein écran ;
## « Retour » ramène au menu principal.

@onready var _panel: OptionsPanel = %OptionsPanel


func _ready() -> void:
	_panel.closed.connect(_on_closed)
	_panel.open()


func _on_closed() -> void:
	SceneRouter.go_to(GameConstants.SCENE_MAIN_MENU)
