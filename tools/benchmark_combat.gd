extends SceneTree
## Banc de performance du combat (Phase 11), sans affichage.
##
## Usage : godot --headless --path . --script res://tools/benchmark_combat.gd
##
## Ce lanceur charge benchmark_runner.gd APRÈS le démarrage : un script lancé avec --script
## est compilé avant l'enregistrement des autoloads, et la scène de combat en dépend.

const RUNNER_PATH: String = "res://tools/benchmark_runner.gd"


func _initialize() -> void:
	_start.call_deferred()


func _start() -> void:
	var runner_script: GDScript = load(RUNNER_PATH) as GDScript
	if runner_script == null:
		push_error("[benchmark] Script introuvable : %s" % RUNNER_PATH)
		quit(1)
		return
	var runner: Node = runner_script.new() as Node
	root.add_child(runner)
	runner.call("run")
