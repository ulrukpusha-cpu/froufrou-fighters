extends TestCase
## Phase 8 : arène « Abidjan — Le Plateau Électrique » : données, plans de parallaxe,
## plan de combat stable, animations du décor et réactions aux impacts.

var stage: Stage = null


func before_each() -> void:
	stage = StageRegistry.instantiate_stage(StageRegistry.ABIDJAN_PLATEAU)
	if stage != null:
		tree.root.add_child(stage)


func after_each() -> void:
	if stage != null and is_instance_valid(stage):
		stage.free()


func _all(type_name: String) -> Array[Node]:
	return stage.find_children("*", type_name, true, false)


func test_stage_data_and_registry() -> void:
	var data: StageData = StageRegistry.load_stage_data(StageRegistry.ABIDJAN_PLATEAU)
	assert_not_null(data, "Fiche de l'arène")
	assert_true(data.validate().is_empty(), "Fiche valide")
	assert_eq(data.district, "Le Plateau", "Quartier")
	assert_not_null(stage, "Scène instanciée par le registre")
	assert_eq(stage.display_name, data.display_name, "Nom repris de la fiche")
	assert_eq(GameSession.stage_id, StageRegistry.ABIDJAN_PLATEAU, "Arène par défaut de la session")


func test_parallax_layers_are_ordered_by_depth() -> void:
	var layers: Array[Parallax2D] = []
	for child: Node in stage.get_children():
		if child is Parallax2D:
			layers.append(child as Parallax2D)
	assert_true(layers.size() >= 6, "Ciel, arrière-plan, plan médian, boulevard, rue, premier plan (%d)" % layers.size())
	for i: int in range(1, layers.size()):
		assert_true(layers[i].scroll_scale.x > layers[i - 1].scroll_scale.x,
			"%s défile plus vite que %s" % [layers[i].name, layers[i - 1].name])
	for layer: Parallax2D in layers:
		assert_eq(layer.scroll_scale.y, 1.0, "%s : pas de parallaxe verticale" % layer.name)
		if layer.scroll_scale.x < 1.0:
			assert_true(layer.z_index < 0, "%s est derrière les combattants" % layer.name)
		else:
			assert_true(layer.z_index > 0, "%s est devant les combattants" % layer.name)


func test_combat_plane_is_stable() -> void:
	var plane: Node2D = stage.get_node_or_null("CombatPlane") as Node2D
	assert_not_null(plane, "Plan de combat présent")
	assert_false(plane is Parallax2D, "Le plan de combat ne défile pas (vitesse 1)")
	assert_true(plane.z_index < 0, "Le sol est dessiné derrière les combattants")
	assert_eq(stage.get_floor_y(), 0.0, "Sol à y = 0")
	assert_eq(stage.get_left_limit(), -stage.half_width, "Mur gauche")
	assert_eq(stage.get_spawn_position(GameConstants.SIDE_P2), Vector2(stage.spawn_distance, 0.0), "Départ J2")


func test_city_has_towers_and_landmark() -> void:
	var cities: Array[Node] = _all("Node2D").filter(func(node: Node) -> bool: return node is CityLayer)
	assert_true(cities.size() >= 2, "Deux rangées d'immeubles (lointaine et proche)")
	for city: Node in cities:
		assert_true((city as CityLayer).get_building_count() >= 8, "%s : assez d'immeubles" % city.name)
	assert_not_null(stage.get_node_or_null("Background/Pyramide"), "Silhouette de repère sur l'horizon")


func test_traffic_moves_and_loops() -> void:
	var lanes: Array[Node] = _all("Node2D").filter(func(node: Node) -> bool: return node is TrafficLane)
	assert_true(lanes.size() >= 2, "Circulation dans les deux sens")
	var taxis: int = 0
	for lane_node: Node in lanes:
		for car: Taxi in (lane_node as TrafficLane).get_cars():
			taxis += 1 if car.is_taxi else 0
	assert_true(taxis >= 2, "Des taxis orange circulent (%d)" % taxis)
	var lane: TrafficLane = lanes[0] as TrafficLane
	var car: Taxi = lane.get_cars()[0]
	var before: float = car.position.x
	lane.advance(0.5)
	assert_true(car.position.x != before, "Les voitures avancent")
	car.position.x = lane.span.y + 10.0 if lane.direction > 0 else lane.span.x - 10.0
	lane.advance(0.01)
	assert_true(car.position.x >= lane.span.x and car.position.x <= lane.span.y, "Une voiture sortie revient de l'autre côté")


func test_neon_signs_of_the_street() -> void:
	var texts: PackedStringArray = PackedStringArray()
	for node: Node in _all("Node2D"):
		if node is NeonSign:
			texts.append((node as NeonSign).text)
	assert_true(texts.size() >= 8, "Rue commerçante éclairée (%d enseignes)" % texts.size())
	for expected: String in ["MAQUIS", "ALLOCO", "GARBA", "PHARMACIE"]:
		assert_true(expected in texts, "Enseigne %s" % expected)


func test_decor_reacts_to_impacts() -> void:
	assert_true(stage.get_reactive_count() >= 10, "Foule, néons et câbles écoutent les impacts")
	var crowd: Crowd = stage.get_node("Foreground/Crowd") as Crowd
	var maquis_sign: NeonSign = stage.get_node("Street/SignMaquis") as NeonSign
	var lines: PowerLines = stage.get_node("Street/PowerLines") as PowerLines
	assert_true(crowd.get_person_count() > 40, "Public nombreux")
	stage.react_to_impact(0.3)
	assert_true(crowd.excitement > 0.2, "Le public réagit à un coup")
	assert_true(maquis_sign.is_glitching(), "Les néons grésillent")
	assert_false(lines.is_sparking(), "Pas d'étincelles pour un petit coup")
	stage.react_to_impact(1.0)
	assert_eq(crowd.excitement, 1.0, "KO : le public est debout")
	assert_true(lines.is_sparking(), "KO : étincelles sur les câbles")
	crowd.advance(3.0)
	assert_true(crowd.excitement < 0.2, "L'excitation retombe (%.2f)" % crowd.excitement)
