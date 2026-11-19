class_name TestCase
extends RefCounted
## Base minimale d'un fichier de tests (aucune dépendance externe).
##
## Chaque méthode dont le nom commence par « test_ » est un test. Un test peut être une
## coroutine (await tree.process_frame) pour faire avancer le moteur.
## before_each() / after_each() encadrent chaque test.

## Arbre de scènes du lanceur, pour ajouter des nœuds et attendre des frames.
var tree: SceneTree

var _failures: PackedStringArray = PackedStringArray()


func before_each() -> void:
	pass


func after_each() -> void:
	pass


func assert_true(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func assert_false(condition: bool, message: String) -> void:
	assert_true(not condition, message)


func assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if not _values_equal(actual, expected):
		_failures.append("%s (attendu : %s, obtenu : %s)" % [message, expected, actual])


func assert_not_null(value: Variant, message: String) -> void:
	if value == null:
		_failures.append(message)


## Avance le moteur d'un nombre de frames de rendu.
func wait_frames(count: int) -> void:
	for i: int in count:
		await tree.process_frame


## Renvoie puis vide les échecs du test courant (utilisé par le lanceur).
func take_failures() -> PackedStringArray:
	var failures: PackedStringArray = _failures
	_failures = PackedStringArray()
	return failures


static func _values_equal(a: Variant, b: Variant) -> bool:
	var numeric: Array[int] = [TYPE_INT, TYPE_FLOAT]
	if typeof(a) != typeof(b) and not (typeof(a) in numeric and typeof(b) in numeric):
		return false
	return a == b
